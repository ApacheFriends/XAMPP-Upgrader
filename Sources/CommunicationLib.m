/*
 *  CommunicationLib.c
 *  XAMPP Upgrader
 *
 *  Created by Christian Speich on 06.09.10.
 *  Copyright 2010 Apple Inc. All rights reserved.
 *
 */

#include "CommunicationLib.h"

#include <CoreServices/CoreServices.h>

#include <launch.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/event.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <sys/socket.h>

// kBASMaxNumberOfKBytes has two uses:
//
// 1. When receiving a dictionary, it is used to limit the size of the incoming 
//    data.  This ensures that a non-privileged client can't exhaust the 
//    address space of a privileged helper tool.
//
// 2. Because it's less than 4 GB, this limit ensures that the dictionary size 
//    can be sent as an architecture-neutral uint32_t.

#define kBASMaxNumberOfKBytes			(1024 * 1024)

/////////////////////////////////////////////////////////////////
#pragma mark ***** Common Code

extern int BASOSStatusToErrno(OSStatus errNum)
// See comment in header.
{
	int retval;
    
#define CASE(ident)         \
case k ## ident ## Err: \
retval = ident;     \
break
    switch (errNum) {
		case noErr:
			retval = 0;
			break;
        case kENORSRCErr:
            retval = ESRCH;                 // no ENORSRC on Mac OS X, so use ESRCH
            break;
        case memFullErr:
            retval = ENOMEM;
            break;
			CASE(EDEADLK);
			CASE(EAGAIN);
		case kEOPNOTSUPPErr:
			retval = ENOTSUP;
			break;
			CASE(EPROTO);
			CASE(ETIME);
			CASE(ENOSR);
			CASE(EBADMSG);
        case kECANCELErr:
            retval = ECANCELED;             // note spelling difference
            break;
			CASE(ENOSTR);
			CASE(ENODATA);
			CASE(EINPROGRESS);
			CASE(ESRCH);
			CASE(ENOMSG);
        default:
            if ( (errNum <= kEPERMErr) && (errNum >= kENOMSGErr) ) {
				retval = (-3200 - errNum) + 1;				// OT based error
            } else if ( (errNum >= errSecErrnoBase) && (errNum <= (errSecErrnoBase + ELAST)) ) {
                retval = (int) errNum - errSecErrnoBase;	// POSIX based error
            } else {
				retval = (int) errNum;						// just return the value unmodified
			}
    }
#undef CASE
    return retval;
}

extern OSStatus BASErrnoToOSStatus(int errNum)
// See comment in header.
{
	OSStatus retval;
	
	if ( errNum == 0 ) {
		retval = noErr;
	} else if ( (errNum >= EPERM) && (errNum <= ELAST) ) {
		retval = (OSStatus) errNum + errSecErrnoBase;
	} else {
		retval = (int) errNum;      // just return the value unmodified
	}
    
    return retval;
}

static Boolean BASIsBinaryPropertyListData(const void * plistBuffer, size_t plistSize)
// Make sure that whatever is passed into the buffer that will 
// eventually become a plist (and then sequentially a dictionary)
// is NOT in binary format.
{
    static const char kBASBinaryPlistWatermark[6] = "bplist";
    
    assert(plistBuffer != NULL);
	
	return (plistSize >= sizeof(kBASBinaryPlistWatermark)) 
	&& (memcmp(plistBuffer, kBASBinaryPlistWatermark, sizeof(kBASBinaryPlistWatermark)) == 0);
}

static void NormaliseOSStatusErrorCode(OSStatus *errPtr)
// Normalise the cancelled error code to reduce the number of checks that our clients 
// have to do.  I made this a function in case I ever want to expand this to handle 
// more than just this one case.
{
    assert(errPtr != NULL);
    
    if ( (*errPtr == errAuthorizationCanceled) || (*errPtr == (errSecErrnoBase + ECANCELED)) ) {
        *errPtr = userCanceledErr;
    }
}

static int BASRead(int fd, void *buf, size_t bufSize, size_t *bytesRead)
// A wrapper around <x-man-page://2/read> that keeps reading until either 
// bufSize bytes are read or until EOF is encountered, in which case you get 
// EPIPE.
//
// If bytesRead is not NULL, *bytesRead will be set to the number 
// of bytes successfully read.  On success, this will always be equal to 
// bufSize.  On error, it indicates how much was read before the error 
// occurred (which could be zero).
{
	int 	err;
	char *	cursor;
	size_t	bytesLeft;
	ssize_t bytesThisTime;
	
    // Pre-conditions
	
	assert(fd >= 0);
	assert(buf != NULL);
    // bufSize may be 0
	assert(bufSize <= kBASMaxNumberOfKBytes);
    // bytesRead may be NULL
	
	err = 0;
	bytesLeft = bufSize;
	cursor = (char *) buf;
	while ( (err == 0) && (bytesLeft != 0) ) {
		bytesThisTime = read(fd, cursor, bytesLeft);
		if (bytesThisTime > 0) {
			cursor    += bytesThisTime;
			bytesLeft -= bytesThisTime;
		} else if (bytesThisTime == 0) {
			err = EPIPE;
		} else {
			assert(bytesThisTime == -1);
			
			err = errno;
			assert(err != 0);
			if (err == EINTR) {
				err = 0;		// let's loop again
			}
		}
	}
	if (bytesRead != NULL) {
		*bytesRead = bufSize - bytesLeft;
	}
	
	return err;
}

static int BASWrite(int fd, const void *buf, size_t bufSize, size_t *bytesWritten)
// A wrapper around <x-man-page://2/write> that keeps writing until either 
// all the data is written or an error occurs, in which case 
// you get EPIPE.
//
// If bytesWritten is not NULL, *bytesWritten will be set to the number 
// of bytes successfully written.  On success, this will always be equal to 
// bufSize.  On error, it indicates how much was written before the error 
// occurred (which could be zero).
{
	int 	err;
	char *	cursor;
	size_t	bytesLeft;
	ssize_t bytesThisTime;
	
    // Pre-conditions
	
	assert(fd >= 0);
	assert(buf != NULL);
    // bufSize may be 0
	assert(bufSize <= kBASMaxNumberOfKBytes);
	// bytesWritten may be NULL
	
	// SIGPIPE occurs when you write to pipe or socket 
	// whose other end has been closed.  The default action 
	// for SIGPIPE is to terminate the process.  That's 
	// probably not what you wanted.  So, in the debug build, 
	// we check that you've set the signal action to SIG_IGN 
	// (ignore).  Of course, you could be building a program 
	// that needs SIGPIPE to work in some special way, in 
	// which case you should define BAS_WRITE_CHECK_SIGPIPE 
	// to 0 to bypass this check.
	
#if !defined(BAS_WRITE_CHECK_SIGPIPE)
#define BAS_WRITE_CHECK_SIGPIPE 1
#endif
#if !defined(NDEBUG) && BAS_WRITE_CHECK_SIGPIPE
	{
		int					junk;
		struct stat			sb;
		struct sigaction	currentSignalState;
		int					val;
		socklen_t			valLen;
		
		junk = fstat(fd, &sb);
		assert(junk == 0);
		
		if ( S_ISFIFO(sb.st_mode) || S_ISSOCK(sb.st_mode) ) {
			junk = sigaction(SIGPIPE, NULL, &currentSignalState);
			assert(junk == 0);
			
			valLen = sizeof(val);
			junk = getsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &val, &valLen);
			assert(junk == 0);
			assert(valLen == sizeof(val));
			
			// If you hit this assertion, you need to either disable SIGPIPE in 
			// your process or on the specific socket you're writing to.  The 
			// standard code for the former is:
			//
			// (void) signal(SIGPIPE, SIG_IGN);
			//
			// You typically add this code to your main function.
			//
			// The standard code for the latter is:
			//
			// static const int kOne = 1;
			// err = setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &kOne, sizeof(kOne));
			//
			// You typically do this just after creating the socket.
			
			assert( (currentSignalState.sa_handler == SIG_IGN) || (val == 1) );
		}
	}
#endif
	
	err = 0;
	bytesLeft = bufSize;
	cursor = (char *) buf;
	while ( (err == 0) && (bytesLeft != 0) ) {
		bytesThisTime = write(fd, cursor, bytesLeft);
		if (bytesThisTime > 0) {
			cursor    += bytesThisTime;
			bytesLeft -= bytesThisTime;
		} else if (bytesThisTime == 0) {
			assert(false);
			err = EPIPE;
		} else {
			assert(bytesThisTime == -1);
			
			err = errno;
			assert(err != 0);
			if (err == EINTR) {
				err = 0;		// let's loop again
			}
		}
	}
	if (bytesWritten != NULL) {
		*bytesWritten = bufSize - bytesLeft;
	}
	
	return err;
}

static int BASReadDictionary(int fdIn, CFDictionaryRef *dictPtr)
// Create a CFDictionary by reading the XML data from fdIn. 
// It first reads the size of the XML data, then allocates a 
// buffer for that data, then reads the data in, and finally 
// unflattens the data into a CFDictionary.
//
// On success, the caller is responsible for releasing *dictPtr.
//
// See also the companion routine, BASWriteDictionary, below.
{
	int                 err = 0;
	uint32_t			dictSize;
	void *				dictBuffer;
	CFDataRef			dictData;
	CFPropertyListRef 	dict;
	
    // Pre-conditions
	
	assert(fdIn >= 0);
	assert( dictPtr != NULL);
	assert(*dictPtr == NULL);
	
	dictBuffer = NULL;
	dictData   = NULL;
	dict       = NULL;
	
	// Read the data size and allocate a buffer.  Always read the length as a big-endian 
    // uint32_t, so that the app and the helper tool can be different architectures.
	
	err = BASRead(fdIn, &dictSize, sizeof(dictSize), NULL);
	if (err == 0) {
        dictSize = OSSwapBigToHostInt32(dictSize);
		if (dictSize == 0) {
			// According to the C language spec malloc(0) may return NULL (although the Mac OS X 
            // malloc doesn't ever do this), so we specifically check for and error out in 
			// that case.
			err = EINVAL;
		} else if (dictSize > kBASMaxNumberOfKBytes) {
			// Abitrary limit to prevent potentially hostile client overwhelming us with data.
			err = EINVAL;
		}
	}
	if (err == 0) {
		dictBuffer = malloc( (size_t) dictSize);
		if (dictBuffer == NULL) {
			err = ENOMEM;
		}
	}
	
	// Read the data and unflatten.
	
	if (err == 0) {
		err = BASRead(fdIn, dictBuffer, dictSize, NULL);
	}
	if ( (err == 0) && BASIsBinaryPropertyListData(dictBuffer, dictSize) ) {
        err = BASOSStatusToErrno( coreFoundationUnknownErr );
	}
	if (err == 0) {
		dictData = CFDataCreateWithBytesNoCopy(NULL, dictBuffer, dictSize, kCFAllocatorNull);
		if (dictData == NULL) {
			err = BASOSStatusToErrno( coreFoundationUnknownErr );
		}
	}
	if (err == 0) {
		dict = CFPropertyListCreateFromXMLData(NULL, dictData, kCFPropertyListImmutable, NULL);
		if (dict == NULL) {
			err = BASOSStatusToErrno( coreFoundationUnknownErr );
		}
	}
	if ( (err == 0) && (CFGetTypeID(dict) != CFDictionaryGetTypeID()) ) {
		err = EINVAL;		// only CFDictionaries need apply
	}
	// CFShow(dict);
	
	// Clean up.
	
	if (err != 0) {
		if (dict != NULL) {
			CFRelease(dict);
		}
		dict = NULL;
	}
	*dictPtr = (CFDictionaryRef) dict;
	free(dictBuffer);
	if (dictData != NULL) {
		CFRelease(dictData);
	}
	
	assert( (err == 0) == (*dictPtr != NULL) );
	
	return err;
}

static int BASWriteDictionary(CFDictionaryRef dict, int fdOut)
// Write a dictionary to a file descriptor by flattening 
// it into XML.  Send the size of the XML before sending 
// the data so that BASReadDictionary knows how much to 
// read.
//
// See also the companion routine, BASReadDictionary, above.
{
	int                 err = 0;
	CFDataRef			dictData;
	uint32_t			dictSize;
	
    // Pre-conditions
	
	assert(dict != NULL);
	assert(fdOut >= 0);
	
	dictData   = NULL;
	
    // Get the dictionary as XML data.
    
	dictData = CFPropertyListCreateXMLData(NULL, dict);
	if (dictData == NULL) {
		err = BASOSStatusToErrno( coreFoundationUnknownErr );
	}
    
    // Send the length, then send the data.  Always send the length as a big-endian 
    // uint32_t, so that the app and the helper tool can be different architectures.
    //
    // The MoreAuthSample version of this code erroneously assumed that CFDataGetBytePtr 
    // can fail and thus allocated an extra buffer to copy the data into.  In reality, 
    // CFDataGetBytePtr can't fail, so this version of the code doesn't do the unnecessary 
    // allocation.
    
    if ( (err == 0) && (CFDataGetLength(dictData) > kBASMaxNumberOfKBytes) ) {
        err = EINVAL;
    }
    if (err == 0) {
		dictSize = OSSwapHostToBigInt32( CFDataGetLength(dictData) );
        err = BASWrite(fdOut, &dictSize, sizeof(dictSize), NULL);
    }
	if (err == 0) {
		err = BASWrite(fdOut, CFDataGetBytePtr(dictData), CFDataGetLength(dictData), NULL);
	}
	
	if (dictData != NULL) {
		CFRelease(dictData);
	}
	
	return err;
}

// When we pass a descriptor, we have to pass at least one byte 
// of data along with it, otherwise the recvmsg call will not 
// block if the descriptor hasn't been written to the other end 
// of the socket yet.

static const char kDummyData = 'D';

// Due to a kernel bug in Mac OS X 10.4.x and earlier <rdar://problem/4650646>, 
// you will run into problems if you write data to a socket while a process is 
// trying to receive a descriptor from that socket.  A common symptom of this 
// problem is that, if you write two descriptors back-to-back, the second one 
// just disappears.
//
// To avoid this problem, we explicitly ACK all descriptor transfers.  
// After writing a descriptor, the sender reads an ACK byte from the socket.  
// After reading a descriptor, the receiver sends an ACK byte (kACKData) 
// to unblock the sender.

static const char kACKData   = 'A';

static int BASReadDescriptor(int fd, int *fdRead)
// Read a descriptor from fd and place it in *fdRead.
//
// On success, the caller is responsible for closing *fdRead.
//
// See the associated BASWriteDescriptor, below.
{
	int 				err;
	int 				junk;
	struct msghdr 		msg;
	struct iovec		iov;
	struct {
		struct cmsghdr 	hdr;
		int            	fd;
	} 					control;
	char				dummyData;
	ssize_t				bytesReceived;
	
    // Pre-conditions
	
	assert(fd >= 0);
	assert( fdRead != NULL);
	assert(*fdRead == -1);
	
	iov.iov_base = (char *) &dummyData;
	iov.iov_len  = sizeof(dummyData);
	
    msg.msg_name       = NULL;
    msg.msg_namelen    = 0;
    msg.msg_iov        = &iov;
    msg.msg_iovlen     = 1;
    msg.msg_control    = (caddr_t) &control;
    msg.msg_controllen = sizeof(control);
    msg.msg_flags	   = MSG_WAITALL;
    
    do {
	    bytesReceived = recvmsg(fd, &msg, 0);
	    if (bytesReceived == sizeof(dummyData)) {
	    	if (   (dummyData != kDummyData)
	    		|| (msg.msg_flags != 0) 
	    		|| (msg.msg_control == NULL) 
	    		|| (msg.msg_controllen != sizeof(control)) 
	    		|| (control.hdr.cmsg_len != sizeof(control)) 
	    		|| (control.hdr.cmsg_level != SOL_SOCKET)
				|| (control.hdr.cmsg_type  != SCM_RIGHTS) 
				|| (control.fd < 0) ) {
	    		err = EINVAL;
	    	} else {
	    		*fdRead = control.fd;
		    	err = 0;
	    	}
	    } else if (bytesReceived == 0) {
	    	err = EPIPE;
	    } else {
	    	assert(bytesReceived == -1);
			
	    	err = errno;
	    	assert(err != 0);
	    }
	} while (err == EINTR);
    
    // Send the ACK.  If that fails, we have to act like we never got the 
    // descriptor in our to maintain our post condition.
    
    if (err == 0) {
        err = BASWrite(fd, &kACKData, sizeof(kACKData), NULL);
        if (err != 0) {
            junk = close(*fdRead);
            assert(junk == 0);
            *fdRead = -1;
        }
    }
	
	assert( (err == 0) == (*fdRead >= 0) );
	
	return err;
}

static int BASWriteDescriptor(int fd, int fdToWrite)
// Write the descriptor fdToWrite to fd.
//
// See the associated BASReadDescriptor, above.
{
	int 				err;
	struct msghdr 		msg;
	struct iovec		iov;
	struct {
		struct cmsghdr 	hdr;
		int            	fd;
	} 					control;
	ssize_t 			bytesSent;
    char                ack;
	
    // Pre-conditions
	
	assert(fd >= 0);
	assert(fdToWrite >= 0);
	
    control.hdr.cmsg_len   = sizeof(control);
    control.hdr.cmsg_level = SOL_SOCKET;
    control.hdr.cmsg_type  = SCM_RIGHTS;
    control.fd             = fdToWrite;
	
	iov.iov_base = (char *) &kDummyData;
	iov.iov_len  = sizeof(kDummyData);
	
    msg.msg_name       = NULL;
    msg.msg_namelen    = 0;
    msg.msg_iov        = &iov;
    msg.msg_iovlen     = 1;
    msg.msg_control    = (caddr_t) &control;
    msg.msg_controllen = control.hdr.cmsg_len;
    msg.msg_flags	   = 0;
    do {
	    bytesSent = sendmsg(fd, &msg, 0);
	    if (bytesSent == sizeof(kDummyData)) {
	    	err = 0;
	    } else {
	    	assert(bytesSent == -1);
			
	    	err = errno;
	    	assert(err != 0);
	    }
	} while (err == EINTR);
	
    // After writing the descriptor, try to read an ACK back from the 
    // recipient.  If that fails, or we get the wrong ACK, we've failed.
    
    if (err == 0) {
        err = BASRead(fd, &ack, sizeof(ack), NULL);
        if ( (err == 0) && (ack != kACKData) ) {
            err = EINVAL;
        }
    }
	
    return err;
}

extern void BASCloseDescriptorArray(
									NSArray*					descArray
									)
// See comment in header.
{	
	int							junk;
	CFIndex						descCount;
	CFIndex						descIndex;
	
	// I decided to allow descArray to be NULL because it makes it 
	// easier to call this routine using the code.
	//
	// BASCloseDescriptorArray((CFArrayRef) CFDictionaryGetValue(response, CFSTR(kBASDescriptorArrayKey)));
	
	if (descArray != NULL) {
		if (CFGetTypeID(descArray) == CFArrayGetTypeID()) {
			descCount = CFArrayGetCount(descArray);
			
			for (descIndex = 0; descIndex < descCount; descIndex++) {
				CFNumberRef thisDescNum;
				int 		thisDesc;
				
				thisDescNum = (CFNumberRef) CFArrayGetValueAtIndex(descArray, descIndex);
				if (   (thisDescNum == NULL) 
					|| (CFGetTypeID(thisDescNum) != CFNumberGetTypeID()) 
					|| ! CFNumberGetValue(thisDescNum, kCFNumberIntType, &thisDesc) ) {
					assert(false);
				} else {
					assert(thisDesc >= 0);
					junk = close(thisDesc);
					assert(junk == 0);
				}
			}
		} else {
			assert(false);
		}
	}
}

int BASReadDictioanaryTranslatingDescriptors(int fd, NSDictionary **dictPtr)
// Reads a dictionary and its associated descriptors (if any) from fd, 
// putting the dictionary (modified to include the translated descriptor 
// numbers) in *dictPtr.
//
// On success, the caller is responsible for releasing *dictPtr and for 
// closing any descriptors it references (BASCloseDescriptorArray makes 
// the second part easy).
{
	int 				err;
	int 				junk;
	CFDictionaryRef		dict;
	CFArrayRef 			incomingDescs;
	
    // Pre-conditions
	
	assert(fd >= 0);
	assert( dictPtr != NULL);
	assert(*dictPtr == NULL);
	
	dict = NULL;
	
	// Read the dictionary.
	
	err = BASReadDictionary(fd, &dict);
	
	// Now read the descriptors, if any.
	
	if (err == 0) {
		incomingDescs = (CFArrayRef) CFDictionaryGetValue(dict, CFSTR(kBASDescriptorArrayKey));
		if (incomingDescs == NULL) {
			// No descriptors.  Not much to do.  Just use dict as the response, 
            // NULLing it out so that we don't release it at the end.
			
			*dictPtr = dict;
			dict = NULL;
		} else {
			CFMutableArrayRef 		translatedDescs;
			CFMutableDictionaryRef	mutableDict;
			CFIndex					descCount;
			CFIndex					descIndex;
			
			// We have descriptors, so there's lots of stuff to do.  Have to 
			// receive each of the descriptors assemble them into the 
			// translatedDesc array, then create a mutable dictionary based 
			// on response (mutableDict) and replace the 
			// kBASDescriptorArrayKey with translatedDesc.
			
			translatedDescs  = NULL;
			mutableDict      = NULL;
			
			// Start by checking incomingDescs.
			
			if ( CFGetTypeID(incomingDescs) != CFArrayGetTypeID() ) {
				err = EINVAL;
			}
			
			// Create our output data.
			
			if (err == 0) {
                translatedDescs = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
                if (translatedDescs == NULL) {
                    err = coreFoundationUnknownErr;
                }
			}
			if (err == 0) {
				mutableDict = CFDictionaryCreateMutableCopy(NULL, 0, dict);
				if (mutableDict == NULL) {
					err = BASOSStatusToErrno( coreFoundationUnknownErr );
				}
			}
			
			// Now read each incoming descriptor, appending the results 
			// to translatedDescs as we go.  By keeping our working results 
			// in translatedDescs, we make sure that we can clean up if 
			// we fail.
			
			if (err == 0) {
				descCount = CFArrayGetCount(incomingDescs);
				
				// We don't actually depend on the descriptor values in the 
				// response (that is, the elements of incomingDescs), because 
				// they only make sense it the context of the sending process. 
				// All we really care about is the number of elements, which 
				// tells us how many times to go through this loop.  However, 
				// just to be paranoid, in the debug build I check that the 
				// incoming array is well formed.
				
#if !defined(NDEBUG)
				for (descIndex = 0; descIndex < descCount; descIndex++) {
					int 		thisDesc;
					CFNumberRef thisDescNum;
					
					thisDescNum = (CFNumberRef) CFArrayGetValueAtIndex(incomingDescs, descIndex);
					assert(thisDescNum != NULL);
					assert(CFGetTypeID(thisDescNum) == CFNumberGetTypeID());
					assert(CFNumberGetValue(thisDescNum, kCFNumberIntType, &thisDesc));
					assert(thisDesc >= 0);
				}
#endif
				
				// Here's the real work.  For descCount times, read a descriptor 
				// from fd, wrap it in a CFNumber, and append it to translatedDescs. 
				// Note that we have to be very careful not to leak a descriptor 
				// if we get an error here.
				
				for (descIndex = 0; descIndex < descCount; descIndex++) {
					int 		thisDesc;
					CFNumberRef thisDescNum;
					
					thisDesc = -1;
					thisDescNum = NULL;
					
					err = BASReadDescriptor(fd, &thisDesc);
					if (err == 0) {
						thisDescNum = CFNumberCreate(NULL, kCFNumberIntType, &thisDesc);
						if (thisDescNum == NULL) {
							err = BASOSStatusToErrno( coreFoundationUnknownErr );
						}
					}
					if (err == 0) {
						CFArrayAppendValue(translatedDescs, thisDescNum);
						// The descriptor is now stashed in translatedDescs, 
						// so this iteration of the loop is no longer responsible 
						// for closing it.
						thisDesc = -1;		
					}
					
                    if (thisDescNum != NULL) {
                        CFRelease(thisDescNum);
                    }
					if (thisDesc != -1) {
						junk = close(thisDesc);
						assert(junk == 0);
					}
					
					if (err != 0) {
						break;
					}
				}
			}
			
			// Clean up and establish output parameters.
			
			if (err == 0) {
				CFDictionarySetValue(mutableDict, CFSTR(kBASDescriptorArrayKey), translatedDescs);
				*dictPtr = mutableDict;
			} else {
				BASCloseDescriptorArray(translatedDescs);
                if (mutableDict != NULL) {
                    CFRelease(mutableDict);
                }
			}
            if (translatedDescs != NULL) {
                CFRelease(translatedDescs);
            }
		}
	}
	
    if (dict != NULL) {
        CFRelease(dict);
    }
	
	assert( (err == 0) == (*dictPtr != NULL) );
	
	return err;
}

int BASWriteDictionaryAndDescriptors(NSDictionary* dict, int fd)
// Writes a dictionary and its associated descriptors to fd.
{
	int 			err;
	CFArrayRef 		descArray;
	CFIndex			descCount;
	CFIndex			descIndex;
	
    // Pre-conditions
	
    assert(dict != NULL);
    assert(fd >= 0);
    
	// Write the dictionary.
	
	err = BASWriteDictionary((CFDictionaryRef)dict, fd);
	
	// Process any descriptors.  The descriptors are indicated by 
	// a special key in the dictionary.  If that key is present, 
	// it's a CFArray of CFNumbers that present the descriptors to be 
	// passed.
	
	if (err == 0) {
		descArray = (CFArrayRef) CFDictionaryGetValue((CFDictionaryRef)dict, CFSTR(kBASDescriptorArrayKey));
		
		// We only do the following if the special key is present.
		
		if (descArray != NULL) {
			
			// If it's not an array, that's bad.
			
			if ( CFGetTypeID(descArray) != CFArrayGetTypeID() ) {
				err = EINVAL;
			}
			
			// Loop over the array, getting each descriptor and writing it.
			
			if (err == 0) {
				descCount = CFArrayGetCount(descArray);
				
				for (descIndex = 0; descIndex < descCount; descIndex++) {
					CFNumberRef thisDescNum;
					int 		thisDesc;
					
					thisDescNum = (CFNumberRef) CFArrayGetValueAtIndex(descArray, descIndex);
					if (   (thisDescNum == NULL) 
						|| (CFGetTypeID(thisDescNum) != CFNumberGetTypeID()) 
						|| ! CFNumberGetValue(thisDescNum, kCFNumberIntType, &thisDesc) ) {
						err = EINVAL;
					}
					if (err == 0) {
						err = BASWriteDescriptor(fd, thisDesc);
					}
					
					if (err != 0) {
						break;
					}
				}
			}
		}
	}
	
	return err;
}