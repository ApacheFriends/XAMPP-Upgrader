/*
 
 XAMPP
 Copyright (C) 2010 by Apache Friends
 
 Authors of this file:
 - Christian Speich <kleinweby@apachefriends.org>
 
 This file is part of XAMPP.
 
 XAMPP is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 XAMPP is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with XAMPP.  If not, see <http://www.gnu.org/licenses/>.
 
 */

static NSString* UpgradeErrorDomain = @"UpgradeErrorDomain";

enum {
	/* Upgrade corrupt errors */
	errUpgradeHelperMissing = 5001,
	errUpgradeBundleMissing = 5002,
	errUnpackBundleFailed = 5003,
    
	/* Get upgrade errors */
	errConnectUpgradeHelper = 6001,
	errAccessControlGet = 6002,
	errAccessControlDenied = 6003,
	
	/* Prepare errors */
	errGetTempDir = 7001,
	errCreateTempDir = 7002,
	errRemoveTempDir = 7003,
    
    errAlreadyUptToDate = 8001,
    errNoDowngrade,
    errNotUpgradable
};