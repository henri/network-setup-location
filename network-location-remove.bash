#!/bin/bash

###### Remove Locations
###### This version designed to support 10.6.x, 10.7.x and 10.8
###### This version has been tested with 10.8.2
###### This Script configures various network settings 
###### Settings are primarily stored in a New Location
###### (C)2008 Henri Shustak
###### Licensed Under the GNU GPL

# Version 1.0

####
#### Settings
#### 

LOCATION1="LOCATION_TO_DELETE"
NETWORKSETUP="networksetup"
SCSELECT="/usr/sbin/scselect"
LOGGER_TAG="Network Location Removal"

# Removal of the current location is not possible. In the event that the current location is the location to be removed,
# set the following varible to YES in order attempt a switch the system to the "Automatic" location in order to perform removal.
SWITCH_TO_AUTOMATIC_LOCATION_AUTOMATICALLY_TO_DELETE="YES" 

####
#### Preflight Checks
####

# Check we are running as root
currentUser=`whoami`
if [ $currentUser != "root" ] ; then
    echo This script must be run with super user privileges.
    exit -127
fi

# Find the version of darwin we are running
darwin_version=`uname -r | awk -F "." '{ print $1 }'`


####
#### Remove the Network Location
####


# Remove Location
if [ $darwin_version -gt 9 ] ; then
    # Mac OS 10.6 and later
    network_location_removal_return_data=`networksetup -deletelocation "${LOCATION1}" | grep "Could not remove the location" ; exit ${PIPESTATUS[0]}`
    network_location_removal_return_code=$?
    if [ "${network_location_removal_return_data}" != "" ] && [ $network_location_removal_return_code == 0 ] ; then
	if [ "${1}" == "recursion-active" ] || [ "${SWITCH_TO_AUTOMATIC_LOCATION_AUTOMATICALLY_TO_DELETE}" != "YES" ] ; then
		logger -s -t "LOGGER_TAG" -p user.error "Unable to remove location as it is the current location"
  		exit -30
	else
		# As we have not yet tried switching to an automatic location lets try doing that now and then re-run the script.
		$SCSELECT "Automatic" > /dev/null
		if [ $? == 0 ] ; then
			logger -s -t "LOGGER_TAG" -p user.notice "Switched to location \"Automatic\" in order to remove location \"${LOCATION1}\""
		else 
			logger -s -t "LOGGER_TAG" -p user.error "Unable to switch to Location \"Automatic\""
		fi
		"${0}" "recursion-active"
		recursion_return=$?
		if [ $recursion_return != 0 ] ; then
			exit $recursion_return
		fi 
	fi
    fi
    if [ $network_location_removal_return_code != 0 ] ; then
	logger -s -t "LOGGER_TAG" -p user.error "Unable to remove location \"${LOCATION1}\""
  	exit -25
    fi
else
    echo "ERROR! : Operating system is not supported."
    exit -20
fi

# Log the status of the location removal.
if [ "${1}" != "recursion-active" ] ; then
	logger -s -t "LOGGER_TAG" -p user.notice "Successfully removed Location \"${LOCATION1}\""
fi
exit 0





