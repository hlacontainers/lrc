#!/bin/sh

#
# Copyright 2020 Tom van den Berg (TNO, The Netherlands).
# SPDX-License-Identifier: Apache-2.0
#

SplitAdvertisedAddress() {
	#split address
	#Format: <HOST> [:<TCPMIN>[-<TCPMAX>] [: <UDPMIN>[-<UDPMAX>] ] ]
	OLDIFS=$IFS
	PITCH_ADV_ADDRESS=$1
	IFS=:
	set -- $PITCH_ADV_ADDRESS
	PITCH_ADV_HOST=$1
	PITCH_ADV_TCPPORTRANGE=$2
	PITCH_ADV_UDPPORTRANGE=$3
	IFS=-
	set -- $PITCH_ADV_TCPPORTRANGE
	PITCH_ADV_TCPMIN=$1
	PITCH_ADV_TCPMAX=$2
	set -- $PITCH_ADV_UDPPORTRANGE
	PITCH_ADV_UDPMIN=$1
	PITCH_ADV_UDPMAX=$2
	IFS=$OLDIFS
	
	# Set defaults
	X=${PITCH_ADV_TCPMIN:=6000}
	X=${PITCH_ADV_TCPMAX:=$((PITCH_ADV_TCPMIN))}
	X=${PITCH_ADV_UDPMIN:=$((PITCH_ADV_TCPMAX+1))}
	X=${PITCH_ADV_UDPMAX:=$((PITCH_ADV_UDPMIN+PITCH_ADV_TCPMAX-PITCH_ADV_TCPMIN))}
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
		
		while [ -z "$HOSTIP" ]; do
			echo "LRC: wait for DNS to respond with IP address for host "$HOSTNAME
			sleep 1
			HOSTIP=$(getent hosts "$HOSTNAME" | awk '{print $1; exit}')
		done
	fi
	
	# get the interface used to reach the specific host/IP.
	NETIF=$(ip route get "$HOSTIP" | head -1 | sed -e 's/^.* dev \([^ ]*\) .*$/\1/')

	if [ -n "${LRC_DEBUG}" ]; then
		echo "LRC: Found interface $NETIF for host $HOSTNAME with IP address $HOSTIP"	
	fi
}

SplitCRCAddress() {
	#split address
	#format: <CRCHOST>:<CRCPORT>@<BOOSTERHOST>:<BOOSTERPORT>
	OLDIFS=$IFS
	ADDRESS=$1
	IFS=@
	set -- $ADDRESS
	PITCH_CRCHOSTPORT=$1
	PITCH_BOOSTHOSTPORT=$2
	IFS=:
	set -- $PITCH_CRCHOSTPORT
	PITCH_CRCHOST=$1
	PITCH_CRCPORT=$2
	set -- $PITCH_BOOSTHOSTPORT
	PITCH_BOOSTHOST=$1
	PITCH_BOOSTPORT=$2
	IFS=$OLDIFS
}

initEnvironmentVars() {
	if [ -z "$JAVA_HOME" ]; then
		echo "JAVA_HOME not set"
		exit 1
	fi

	if [ -z "$LRC_HOME" ]; then
		export LRC_HOME=/usr/local/lrc
	fi
	
	if [ -z "$LRC_CLASSPATH" ]; then
		export LRC_CLASSPATH=${LRC_HOME}/code/lib/prti1516e.jar:${LRC_HOME}/code/lib/prticore.jar:${LRC_HOME}/code/lib/booster1516.jar
		export CLASSPATH=${LRC_CLASSPATH}:${CLASSPATH}
	fi

	if [ -z "$LRC_LIBRARYPATH" ]; then
		export LRC_LIBRARYPATH=${LRC_HOME}/code/lib/gcc41_64:${JAVA_HOME}/lib/amd64:${JAVA_HOME}/lib/amd64/server
		export LD_LIBRARY_PATH=${LRC_LIBRARYPATH}:${LD_LIBRARY_PATH}
	fi
	
	if [ -z "$PITCH_LRC_SETTINGS_FILE" ]; then
		PITCH_LRC_SETTINGS_FILE=${LRC_HOME}/code/prti1516eLRC.settings
	fi
	
	if [ -z "$PITCH_LRC_LOGGING_FILE" ]; then
		PITCH_LRC_LOGGING_FILE=${LRC_HOME}/code/prti1516e.logging
	fi
	
	# Pitch expects settings files under /root/prti1516e
	mkdir -p /root/prti1516e

	if [ -f "${PITCH_LRC_SETTINGS_FILE}" ]; then
		if [ "${PITCH_LRC_SETTINGS_FILE}" != "/root/prti1516e/prti1516eLRC.settings" ]; then
			cp ${PITCH_LRC_SETTINGS_FILE} /root/prti1516e
		fi
	fi

	if [ -f "${PITCH_LRC_LOGGING_FILE}" ]; then
		if [ "${PITCH_LRC_LOGGING_FILE}" != "/root/prti1516e/prti1516e.logging" ]; then
			cp ${PITCH_LRC_LOGGING_FILE} /root/prti1516e
		fi
	fi

	PITCH_LRC_SETTINGS_FILE=/root/prti1516e/prti1516eLRC.settings
	PITCH_LRC_LOGGING_FILE=/root/prti1516e/prti1516e.logging
}

initEnvironmentVars

# Change settings in config file
if [ -f "${PITCH_LRC_SETTINGS_FILE}" ]; then
	SplitCRCAddress $PITCH_CRCADDRESS

	if [ -n "$PITCH_BOOSTHOST" ]; then
		if [ -z "$PITCH_CRCHOST" ]; then
			PITCH_CRCHOST="crc"
		fi		
		if [ -z "$PITCH_BOOSTPORT" ]; then
			PITCH_BOOSTPORT="8688"
		fi
		PITCH_CRCADDRESS=${PITCH_CRCHOST}@${PITCH_BOOSTHOST}:${PITCH_BOOSTPORT}
		PITCH_MASTERADDRESS=${PITCH_BOOSTHOST}:${PITCH_BOOSTPORT}

		# Only determine the adapter when we have waited for the master to be up
		if [ "$LRC_MASTERADDRESS" = "$PITCH_MASTERADDRESS" ]; then
			if [ -z "${PITCH_LRCADAPTER}" ]; then
				GetNetworkInterface $PITCH_BOOSTHOST
				PITCH_LRCADAPTER=$NETIF
			fi
		fi
	else
		if [ -z "$PITCH_CRCHOST" ]; then
			PITCH_CRCHOST="crc"
		fi		
		if [ -z "$PITCH_CRCPORT" ]; then
			PITCH_CRCPORT="8989"
		fi
		PITCH_CRCADDRESS=${PITCH_CRCHOST}:${PITCH_CRCPORT}
		PITCH_MASTERADDRESS=${PITCH_CRCHOST}:${PITCH_CRCPORT}

		# Only determine the adapter when we have waited for the master to be up
		if [ "$LRC_MASTERADDRESS" = "$PITCH_MASTERADDRESS" ]; then
			if [ -z "${PITCH_LRCADAPTER}" ]; then
				GetNetworkInterface $PITCH_CRCHOST
				PITCH_LRCADAPTER=$NETIF
			fi		
		fi
	fi

	if [ -n "${LRC_DEBUG}" ]; then
		echo "LRC: Set crcAddress to ${PITCH_CRCADDRESS}"
	fi

	# Set the CRC address 
	sed -i "s/crcAddress.*/crcAddress=$PITCH_CRCADDRESS/" $PITCH_LRC_SETTINGS_FILE

	# Set the LRC Adapter 
	if [ -n "$PITCH_LRCADAPTER" ]; then
		sed -i "s/LRC.adapter.*/LRC.adapter=$PITCH_LRCADAPTER/" $PITCH_LRC_SETTINGS_FILE

		if [ -n "${LRC_DEBUG}" ]; then
			echo "LRC: Set LRC.adapter to ${PITCH_LRCADAPTER}"
		fi
	fi

	# Set the Booster Adapter 
	if [ -n "$PITCH_BOOSTERADAPTER" ]; then
		sed -i "s/Booster.adapter.*/Booster.adapter=$PITCH_BOOSTERADAPTER/" $PITCH_LRC_SETTINGS_FILE

		if [ -n "${LRC_DEBUG}" ]; then
			echo "LRC: Set Booster.adapter to ${PITCH_BOOSTERADAPTER}"
		fi
	fi

	# Set the LRC advertise address 
	if [ -n "${PITCH_ADVERTISE_ADDRESS}" ]; then
		SplitAdvertisedAddress $PITCH_ADVERTISE_ADDRESS
		
		if [ -n "${LRC_DEBUG}" ]; then
			echo "LRC: Set advertise host and port ranges to ${PITCH_ADV_HOST}:${PITCH_ADV_TCPMIN}-${PITCH_ADV_TCPMAX}:${PITCH_ADV_UDPMIN}-${PITCH_ADV_UDPMAX}"
		fi
	
		if [ -n "$PITCH_ADV_HOST" ]; then
			sed -i "s/LRC.TCP.advertise.mode.*/LRC.TCP.advertise.mode=User/" $PITCH_LRC_SETTINGS_FILE
			sed -i "s/LRC.TCP.advertise.address.*/LRC.TCP.advertise.address=$PITCH_ADV_HOST/" $PITCH_LRC_SETTINGS_FILE
		fi
	
		if [ -n "$PITCH_ADV_TCPMIN" ]; then
			sed -i "s/LRC.TCP.port-range.start.*/LRC.TCP.port-range.start=$PITCH_ADV_TCPMIN/" $PITCH_LRC_SETTINGS_FILE
		fi
	
		if [ -n "$PITCH_ADV_TCPMAX" ]; then
			sed -i "s/LRC.TCP.port-range.end.*/LRC.TCP.port-range.end=$PITCH_ADV_TCPMAX/" $PITCH_LRC_SETTINGS_FILE
		fi

		if [ -n "$PITCH_ADV_UDPMIN" ]; then
			sed -i "s/LRC.UDP.port-range.start.*/LRC.UDP.port-range.start=$PITCH_ADV_UDPMIN/" $PITCH_LRC_SETTINGS_FILE
		fi
	
		if [ -n "$PITCH_ADV_UDPMAX" ]; then
			sed -i "s/LRC.UDP.port-range.end.*/LRC.UDP.port-range.end=$PITCH_ADV_UDPMAX/" $PITCH_LRC_SETTINGS_FILE
		fi
	fi

	# Set the Booster advertise address 
	if [ -n "${PITCH_BOOSTER_ADVERTISE_ADDRESS}" ]; then
		SplitAdvertisedAddress $PITCH_BOOSTER_ADVERTISE_ADDRESS
	
		if [ -n "${LRC_DEBUG}" ]; then
			echo "LRC: Set advertise data to ${PITCH_ADV_HOST}:${PITCH_ADV_TCPMIN}-${PITCH_ADV_TCPMAX}:${PITCH_ADV_UDPMIN}-${PITCH_ADV_UDPMAX}"
		fi

		if [ -n "$PITCH_ADV_HOST" ]; then
			sed -i "s/LRC.booster.advertise.mode.*/LRC.booster.advertise.mode=User/" $PITCH_LRC_SETTINGS_FILE
			sed -i "s/LRC.booster.advertise.address.*/LRC.booster.advertise.address=$PITCH_ADV_HOST/" $PITCH_LRC_SETTINGS_FILE
		fi
	
		if [ -n "$PITCH_ADV_TCPMIN" ]; then
			sed -i "s/LRC.booster.tcp.port-range.start.*/LRC.booster.tcp.port-range.start=$PITCH_ADV_TCPMIN/" $PITCH_LRC_SETTINGS_FILE
		fi
	
		if [ -n "$PITCH_ADV_TCPMAX" ]; then
			sed -i "s/LRC.booster.tcp.port-range.end.*/LRC.booster.tcp.port-range.end=$PITCH_ADV_TCPMAX/" $PITCH_LRC_SETTINGS_FILE
		fi

		if [ -n "$PITCH_ADV_UDPMIN" ]; then
			sed -i "s/LRC.booster.udp.port-range.start.*/LRC.booster.udp.port-range.start=$PITCH_ADV_UDPMIN/" $PITCH_LRC_SETTINGS_FILE
		fi
	
		if [ -n "$PITCH_ADV_UDPMAX" ]; then
			sed -i "s/LRC.booster.udp.port-range.end.*/LRC.booster.udp.port-range.end=$PITCH_ADV_UDPMAX/" $PITCH_LRC_SETTINGS_FILE
		fi
	fi	
fi

# Change settings in config file
if [ -f "$PITCH_LRC_LOGGING_FILE" ]; then
	if [ -n "$PITCH_ENABLETRACE" ]; then
		sed -i "s/traceRTIambassador=.*/traceRTIambassador=true/" $PITCH_LRC_LOGGING_FILE
		sed -i "s/traceFederateAmbassador=.*/traceFederateAmbassador=true/" $PITCH_LRC_LOGGING_FILE
		sed -i "s/traceToConsole=.*/traceToConsole=true/" $PITCH_LRC_LOGGING_FILE
	fi
fi
