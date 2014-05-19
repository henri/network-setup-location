#!/bin/bash

###### Setup Locations
###### This version designed to support 10.4.x, 10.5.x, 10.6.x and 10.7.x
###### This Script configures various network settings 
###### Settings are primarily stored in a New Location
###### (C)2008 Henri Shustak
###### Licensed Under the BSD 3-Clause License (BSD New License)

# Version 3.1

####
#### Settings
#### 

NCUTIL="/sbin/ncutil"
NETWORKSETUP="networksetup"
SCSELECT="/usr/sbin/scselect"
LOCATION1="NEW_LOCATION"
AUTOPROXYURL="http://wpad/proxy.pac"
#AIRPORTNETWORK="wireless_SSID"
#AIRPORTNETWORKPW=""
ETHERNETSERVICENAME="Ethernet"
AIRPORTSERVICENAME="AirPort" # 10.6 and ealier
AIRPORTSERVICENAME_107="Wi-Fi" # 10.7 and later

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
#### Configure AirPort service name for 10.7 (Lion)
####

if [ $darwin_version -ge 11 ] ; then
	AIRPORTSERVICENAME="${AIRPORTSERVICENAME_107}"
fi


####
#### Install NCUtil Appropriate for the target OS
####

path_to_this_script=`dirname "${0}"`

if [ $darwin_version == 8 ] ; then
    ncutil_source="${path_to_this_script}/ncutil/10.4/ncutil"
fi

if [ $darwin_version == 9 ] ; then
    ncutil_source="${path_to_this_script}/ncutil/10.5/ncutil"
fi

if [ "${ncutil_source}" == "" ] && [ $darwin_version -le 9 ] ; then
    logger -s -t "NCUTIL Installation" -p user.error "ERROR : Installing ncutil. This installer only contents versions for Mac OS 10.4.x, 10.5.x. and 10.6.x Network setup has failed."
    exit -1
fi


# Install NCUTIL (pre 10.6 systems)
if [ $darwin_version -le 9 ] ; then
    # Pre 10.6 install ncutil to assist with network setup
    ditto -rsrc "${ncutil_source}" "${NCUTIL}"
    chown root:wheel "${NCUTIL}"
    chmod 755 "${NCUTIL}"
    if ! [ -f "${NCUTIL}" ] ; then
         logger -s -t "NCUTIL Installation" -p user.error "ERROR : Installing ncutil. Network setup has failed."
         exit -1
    fi
fi


####
#### Setup the Network
####

# Create Location
if [ $darwin_version -gt 9 ] ; then
    # Mac OS 10.6 and later
    $NETWORKSETUP -createlocation $LOCATION1 populate
else
    # Pre Mac OS 10.6 (10.5 and 10.4)
    $NCUTIL create-location $LOCATION1
fi

# Activate the new Location
$SCSELECT $LOCATION1

# If we are running on OS 10.4 then use ncutil for setting the proxies.
if [ $darwin_version == 8 ] ; then
    tiger_ard_networksetup="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Support/networksetup"
    if [ -f "${tiger_ard_networksetup}" ] ; then
        # Configue the location for the 10.4 (tiger) networksetup utilty.
        NETWORKSETUP="${tiger_ard_networksetup}"
        ETHERNETSERVICENAME="Built-in Ethernet"
    else
        logger -s -t "NCUTIL Installaion" -p user.error "ERROR : Locating ARD networksetup utilty. Network setup has failed."
        exit -1
    fi
else

    # Running 10.5 or later so use networksetup for a more complete network setup
    
    # Enable Auto Proxy Configuration File
    $NETWORKSETUP -setautoproxyurl "$ETHERNETSERVICENAME" $AUTOPROXYURL
    $NETWORKSETUP -setautoproxyurl "$AIRPORTSERVICENAME" $AUTOPROXYURL

    # Turn on the AirPort - This is not working... 
    # Therefore, It is important to ensure that the Air Port is on manually
    #$NETWORKSETUP -setairportpower on
    #sleep 60
    
    # Connect to the Wireless Network - disabled -
    # $NETWORKSETUP -setairportnetwork $AIRPORTNETWORK $AIRPORTNETWORKPW
    
    # Disable IPv6 
    $NETWORKSETUP -setv6off "$ETHERNETSERVICENAME"
    $NETWORKSETUP -setv6off "$AIRPORTSERVICENAME"

    # Disable AppleTalk
    if [ $darwin_version -le 9 ] ; then
	    # If we are on 10.5 or earlier version of the operating system.
	    $NETWORKSETUP -setappletalk "$ETHERNETSERVICENAME" off
	    $NETWORKSETUP -setappletalk "$AIRPORTSERVICENAME" off
    fi
    
    # Set the network services order
    BLUETOOTHSERVICENAME=`networksetup -listallnetworkservices | grep "Bluetooth"`
    $NETWORKSETUP -ordernetworkservices $ETHERNETSERVICENAME $AIRPORTSERVICENAME FireWire "$BLUETOOTHSERVICENAME"

fi



exit 0



