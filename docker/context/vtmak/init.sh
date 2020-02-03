#!/bin/sh

#
# Copyright 2020 Tom van den Berg (TNO, The Netherlands).
# SPDX-License-Identifier: Apache-2.0
#

# This script processes MAK RTI environment variables.

SplitAddress() {
	#split address
	#format: <HOST>:<PORT>
	OLDIFS=$IFS
	ADDRESS=$1
	IFS=:
	set -- $ADDRESS
	MAK_RTIEXECHOST=$1
	MAK_RTIEXECPORT=$2
	IFS=$OLDIFS
}

GetNetworkInterface() {
	# host we want to "reach"
	HOSTNAME=$1
	
	# if host is an ip address then do not use DNS
	if expr "$HOSTNAME" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
		HOSTIP=$HOSTNAME
	else
		# resolve hostname (works with dns and /etc/hosts).
		HOSTIP=$(getent hosts "$HOSTNAME" | awk '{print $1; exit}')
	fi
				
	if [ -z "$HOSTIP" ]; then
		# get the interface used to reach an arbitrary host/IP.
		NETIF=$(ip route get 8.8.8.8 | head -1 | sed -e 's/^.* src \([^ ]*\) .*$/\1/')
		echo "LRC: No DNS entry found for host $HOSTNAME, using $NETIF of external gateway"
	else
		# get the interface used to reach the specific host/IP.
		NETIF=$(ip route get "$HOSTIP" | head -1 | sed -e 's/^.* src \([^ ]*\) .*$/\1/')
		echo "LRC: Found interface $NETIF for host $HOSTNAME with IP address $HOSTIP"	
	fi
}

initEnvironmentVars() {
	if [ -z "$LRC_HOME" ]; then
		export LRC_HOME=/usr/local/lrc
		export RTI_HOME=${LRC_HOME}/code
	fi
	
	if [ -z "$LRC_CLASSPATH" ]; then
		export LRC_CLASSPATH=${RTI_HOME}/lib/hla.jar
		export CLASSPATH=${LRC_CLASSPATH}:${CLASSPATH}
	fi

	if [ -z "$LRC_LIBRARYPATH" ]; then
		export LRC_LIBRARYPATH=${RTI_HOME}/lib/java:${RTI_HOME}/lib
		export LD_LIBRARY_PATH=${LRC_LIBRARYPATH}:${LD_LIBRARY_PATH}
	fi
	
	if [ -z "$MAK_RTI_RID_FILE" ]; then
		export RTI_RID_FILE=${RTI_HOME}/rid.mtl
	else
		export RTI_RID_FILE=${MAK_RTI_RID_FILE}
	fi
	
	# Copy file to a local location since it may potentially be mounted from different containers
	cp $RTI_RID_FILE /tmp/rid.mtl
	RTI_RID_FILE=/tmp/rid.mtl
	
	export RTI_ASSISTANT_DISABLE=1
}

# Set defaults (same as in rtiexec)
X=${MAK_RTI_CONFIGURE_CONNECTION_WITH_RID:=1}
X=${MAK_RTI_USE_RTI_EXEC:=1}
X=${MAK_RTI_FOM_DATA_TRANSPORT_TYPE_CONTROL:=2}
X=${MAK_RTI_MOM_SERVICE_AVAILABLE:=1}
X=${MAK_RTI_THROW_EXCEPTION_CALL_NOT_ALLOWED_FROM_WITHIN_CALLBACK:=1}
X=${MAK_RTI_CHECK_FLAG:=1}
X=${MAK_RTI_ENABLE_HLA_OBJECT_NAME_PREFIX:=1}
X=${MAK_RTI_STRICT_FOM_CHECKING:=1}
X=${MAK_RTI_STRICT_NAME_RESERVATION:=1}
X=${MAK_RTI_RTIEXEC_PERFORMS_LICENSING:=1}
X=${MAK_RTI_USE_32BITS_FOR_VALUE_SIZE:=1}

initEnvironmentVars

# Change settings in config file
if [ -f "$RTI_RID_FILE" ]; then

	SplitAddress $MAK_RTIEXECADDRESS

	if [ -z "$MAK_RTIEXECHOST" ]; then
		MAK_RTIEXECHOST="rtiexec"
	fi		
	if [ -z "$MAK_RTIEXECPORT" ]; then
		MAK_RTIEXECPORT="4000"
	fi

	MAK_RTIEXECADDRESS=$MAK_RTIEXECHOST:$MAK_RTIEXECPORT

	if [ -n "$MAK_LRCADAPTER" ]; then
		NETIF=$MAK_LRCADAPTER
	else
		# Determine network interface to RTI Exec
		GetNetworkInterface $MAK_RTIEXECHOST
	fi

	sed -i "s/(setqb RTI_networkInterfaceAddr.*/(setqb RTI_networkInterfaceAddr \"$NETIF\")/" $RTI_RID_FILE

	sed -i "s/(setqb RTI_tcpNetworkInterfaceAddr.*/(setqb RTI_tcpNetworkInterfaceAddr \"$NETIF\")/" $RTI_RID_FILE

	sed -i "s/(setqb RTI_tcpForwarderAddr.*/(setqb RTI_tcpForwarderAddr \"$MAK_RTIEXECHOST\")/" $RTI_RID_FILE

	sed -i "s/(setqb RTI_tcpPort.*/(setqb RTI_tcpPort $MAK_RTIEXECPORT)/" $RTI_RID_FILE

	sed -i "s/(setqb RTI_udpPort.*/(setqb RTI_udpPort $MAK_RTIEXECPORT)/" $RTI_RID_FILE
	
	# Set the others
	if [ -n "$MAK_RTI_CONFIGURE_CONNECTION_WITH_RID" ]; then
		sed -i "s/(setqb RTI_configureConnectionWithRid.*/(setqb RTI_configureConnectionWithRid $MAK_RTI_CONFIGURE_CONNECTION_WITH_RID)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_USE_RTI_EXEC" ]; then
		sed -i "s/(setqb RTI_useRtiExec.*/(setqb RTI_useRtiExec $MAK_RTI_USE_RTI_EXEC)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_FOM_DATA_TRANSPORT_TYPE_CONTROL" ]; then
		sed -i "s/(setqb RTI_fomDataTransportTypeControl.*/(setqb RTI_fomDataTransportTypeControl $MAK_RTI_FOM_DATA_TRANSPORT_TYPE_CONTROL)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_MOM_SERVICE_AVAILABLE" ]; then
		sed -i "s/(setqb RTI_momServiceAvailable.*/(setqb RTI_momServiceAvailable $MAK_RTI_MOM_SERVICE_AVAILABLE)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_THROW_EXCEPTION_CALL_NOT_ALLOWED_FROM_WITHIN_CALLBACK" ]; then
		sed -i "s/(setqb RTI_throwExceptionCallNotAllowedFromWithinCallback.*/(setqb RTI_throwExceptionCallNotAllowedFromWithinCallback $MAK_RTI_THROW_EXCEPTION_CALL_NOT_ALLOWED_FROM_WITHIN_CALLBACK)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_CHECK_FLAG" ]; then
		sed -i "s/(setqb RTI_checkFlag.*/(setqb RTI_checkFlag $MAK_RTI_CHECK_FLAG)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_ENABLE_HLA_OBJECT_NAME_PREFIX" ]; then
		sed -i "s/(setqb RTI_enableHlaObjectNamePrefix.*/(setqb RTI_enableHlaObjectNamePrefix $MAK_RTI_ENABLE_HLA_OBJECT_NAME_PREFIX)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_STRICT_FOM_CHECKING" ]; then
		sed -i "s/(setqb RTI_strictFomChecking.*/(setqb RTI_strictFomChecking $MAK_RTI_STRICT_FOM_CHECKING)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_STRICT_NAME_RESERVATION" ]; then
		sed -i "s/(setqb RTI_strictNameReservation.*/(setqb RTI_strictNameReservation $MAK_RTI_STRICT_NAME_RESERVATION)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_RTIEXEC_PERFORMS_LICENSING" ]; then
		sed -i "s/(setqb RTI_rtiExecPerformsLicensing.*/(setqb RTI_rtiExecPerformsLicensing $MAK_RTI_RTIEXEC_PERFORMS_LICENSING)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_USE_32BITS_FOR_VALUE_SIZE" ]; then
		sed -i "s/(setqb RTI_use32BitsForValueSize.*/(setqb RTI_use32BitsForValueSize $MAK_RTI_USE_32BITS_FOR_VALUE_SIZE)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_NOTIFY_LEVEL" ]; then
		sed -i "s/.*(setqb RTI_notifyLevel.*/(setqb RTI_notifyLevel $MAK_RTI_NOTIFY_LEVEL)/" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_LOG_FILE_DIRECTORY" ]; then
		sed -i "s:.*(setqb RTI_logFileDirectory .*):(setqb RTI_logFileDirectory \"$MAK_RTI_LOG_FILE_DIRECTORY\"):" $RTI_RID_FILE
	fi

	if [ -n "$MAK_RTI_RTIEXEC_LOG_FILE_NAME" ]; then
		sed -i "s:.*(setqb RTI_rtiExecLogFileName.*):(setqb RTI_rtiExecLogFileName \"$MAK_RTI_RTIEXEC_LOG_FILE_NAME\"):" $RTI_RID_FILE
	fi
fi
