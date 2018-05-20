#!/bin/bash
#
# Description: Present a top5 of longest users online. Send alarm if any user passes thresholds.
#
# Author: Robert Claesson <rclaesson@op5.com> 2018
#

# Source naemon utilities
source /opt/plugins/utils.sh

# Binaries
ldapsearch=$(which ldapsearch)

# Today's date
today=$(date +%F)

# Help message
help="$0 \n
Usage: $0 -H host/IP -b BaseDN -u bind-user -p bind-password -w warning-threshold -c critical-threshold\n
Options:
-H Hostname of Active Directory server
-b Base DN (e.g "dc=demo-ad,dc=op5,dc=com")
-u Bind username
-p Bind password
-w Warning threshold
-c Critical threshold"

# Check for people who need help
if [ "${1}" = "--h" -o "${#}" = "0" ] || [ "${1}" = "--help" -o "${#}" = "0" ] || [ "${1}" = "-h" -o "${#}" = "0" ];
        then
        echo -e "${help}";
        exit $STATE_UNKNOWN
fi

# Setup variables
while getopts "H:b:u:p:w:c:" input; do
        case ${input} in
        H)      host=${OPTARG};;
        b)      basedn=${OPTARG};;
        u)      username=${OPTARG};;
        p)      password=${OPTARG};;
        w)      warning=${OPTARG};;
        c)      critical=${OPTARG};;
        *)      $help ; exit $STATE_UNKNOWN;;
        \?)     $help ; exit $STATE_UNKNOWN;;
        esac
done

# Get timestamp per user from Active Directory
query=$("$ldapsearch" -LLL -h "$host" -b "$basedn" -D "$username" -w $password -s sub "(&(objectClass=user)(objectCategory=person))" lastLogonTimestamp sAMAccountName | grep -v dn | sed '/^ / d' | awk '/^USER/{user=$0}/^sAMAccountName/{sAMAccountName=$0}/^lastLogonTimestamp/{if(prev!=user){print user};print sAMAccountName;print $0;prev=user}' | cut -d":" -f2 | awk '!(NR%2){print$0p}{p=$0}' | sed 's/^ *//g' | sort | head -n 5 | sed 's/$/,/')


# Loop through timestamps
IFS=','
while read -r timestamp user
do
        # Separate timestamp & user
		user=$(echo $timestamp | cut -d" " -f2)
        timestamp=$(echo $timestamp | cut -d" " -f1)
        # Convert to epoch
        timestamp=$((($timestamp/10000000)-11676009600))
        # Convert to human readable
        timestamp=$(date -d @$timestamp +%F)
        # Calculate days between login and now
        date_diff=$(( ($(date -d "$today" +%s) - $(date -d "$timestamp" +%s) )/(60*60*24) ))
	# Compare date diff against thresholds
	if [ $date_diff -ge $critical ]
	then
		echo "CRITICAL: user $user logged in $date_diff days ago."
		state=2
	elif  [ $date_diff -ge $warning ]
	then
		echo "WARNING: user $user logged in $date_diff days ago."
		# Set exit code to warning if critical has not been met
		if [ -z ${state+x} ]
		then
			state=1
		fi
	else
        	echo "OK: user $user logged in $date_diff days ago."
	fi
done <<< "$query"

# Finish with exit status
exit $state
