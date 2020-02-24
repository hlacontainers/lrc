#!/bin/sh

#
# Copyright 2020 Tom van den Berg (TNO, The Netherlands).
# SPDX-License-Identifier: Apache-2.0
#

# This script processes Portico environment variables.

initEnvironmentVars() {
	if [ -z "$JAVA_HOME" ]; then
		echo "JAVA_HOME not set"
		exit 1
	fi

	if [ -z "$LRC_HOME" ]; then
		export LRC_HOME=/usr/local/lrc
	fi
	
	if [ -z "$LRC_CLASSPATH" ]; then
		export LRC_CLASSPATH=${LRC_HOME}/code/lib/portico.jar
		export CLASSPATH=${LRC_CLASSPATH}:${CLASSPATH}
	fi

	if [ -z "$LRC_LIBRARYPATH" ]; then
		export LRC_LIBRARYPATH=${LRC_HOME}/code/lib/gcc4:${JAVA_HOME}/lib/amd64:${JAVA_HOME}/lib/amd64/server
		export LD_LIBRARY_PATH=${LRC_LIBRARYPATH}:${LD_LIBRARY_PATH}
	fi

	if [ -z "$PORTICO_RTI_RID_FILE" ]; then
		export RTI_RID_FILE=${LRC_HOME}/code/RTI.rid	
	else
		export RTI_RID_FILE=${PORTICO_RTI_RID_FILE}
	fi
	
	# Copy file to a local location since it may potentially be mounted from different containers
	cp $RTI_RID_FILE /tmp/RTI.rid
	RTI_RID_FILE=/tmp/RTI.rid
}

initEnvironmentVars

# Change settings in config file
if [ -f "${RTI_RID_FILE}" ]; then

	# PORTICO_LRCADAPTER is an alternative way to set the bindaddress (which appears only to work with IP address)
	if [ -n "$PORTICO_LRCADAPTER" ]; then
		# Use command ip to determine ip address
		PORTICO_JGROUPS_UDP_BINDADDRESS=`ip addr show $PORTICO_LRCADAPTER | grep 'inet ' | awk '{ print $2}' | cut -d '/' -f1`
	fi

	if [ -n "$PORTICO_LOGLEVEL" ]; then
		sed -i "s/^.*portico.loglevel.*/portico.loglevel = $PORTICO_LOGLEVEL/" $RTI_RID_FILE
	fi

	if [ -n "$PORTICO_JGROUPS_LOGLEVEL" ]; then
		sed -i "s/^.*portico.jgroups.loglevel.*/portico.jgroups.loglevel = $PORTICO_JGROUPS_LOGLEVEL/" $RTI_RID_FILE
	fi

	if [ -n "$PORTICO_UNIQUEFEDERATENAMES" ]; then
		sed -i "s/^.*portico.uniqueFederateNames.*/portico.uniqueFederateNames = $PORTICO_UNIQUEFEDERATENAMES/" $RTI_RID_FILE
	fi
	
	if [ -n "$PORTICO_JGROUPS_UDP_ADDRESS" ]; then
		sed -i "s/^.*portico.jgroups.udp.address.*/portico.jgroups.udp.address = $PORTICO_JGROUPS_UDP_ADDRESS/" $RTI_RID_FILE
	fi

	if [ -n "$PORTICO_JGROUPS_UDP_PORT" ]; then
		sed -i "s/^.*portico.jgroups.udp.port.*/portico.jgroups.udp.port = $PORTICO_JGROUPS_UDP_PORT/" $RTI_RID_FILE
	fi

	if [ -n "$PORTICO_JGROUPS_UDP_BINDADDRESS" ]; then
		sed -i "s/^.*portico.jgroups.udp.bindAddress.*/portico.jgroups.udp.bindAddress = $PORTICO_JGROUPS_UDP_BINDADDRESS/" $RTI_RID_FILE
	fi
fi
