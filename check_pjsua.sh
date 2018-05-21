#!/bin/bash
#
# Description: Call telephones using softphone psjua
#
# Requiments: pjsua (from pjsip)

# Source Nagios utils
source /opt/plugins/utils.sh

# Binaries
pjsua="/opt/plugins/custom/pjsua"

# Logs
pjsua_log="/tmp/pjsua.log"

# Check for users who need help
if [ "${1}" = "--h" -o "${#}" = "0" ] || [ "${1}" = "--help" -o "${#}" = "0" ] || [ "${1}" = "-h" -o "${#}" = "0" ];
then
	echo "Usage: $0 <config-file> <phone-number>"
	exit "$STATE_UNKNOWN"
fi

# Check arguments
if [ $# -ne 2 ]
then
	echo "Usage: $0 <config-file> <phone-number>"
	exit "$STATE_UNKNOWN"
fi

# Check for pjsua binary
if [ ! -x /opt/plugins/custom/pjsua ]
then
        echo "Could not find pjsua program. Exiting."
        exit "$STATE_UNKNOWN"
fi

# Make phone call (logs to /tmp/pjsua.log, log-file is overriden every new run)
(sleep 10 && echo q) | "$pjsua" --config-file="$1" sip:"$2" >> /dev/null

## Parse log-file

# Check for registration
if ! grep -q "registration success, status=200" "$pjsua_log"
then
	echo "CRITICAL: Registration failed for $2. Please review $pjsua_log for more information."
	exit "$STATE_CRITICAL"
fi

# Check for call confirmation
if ! grep -q "state changed to CONFIRMED" "$pjsua_log"
then
	echo "CRITICAL: Could not CONFIRM call: $2. Please review $pjsua_log for more information."
	exit "$STATE_CRITICAL"
fi

# Check for unregistration
if ! grep -q "unregistration success" "$pjsua_log"
then
	echo "CRITICAL: Unregistration failed for $2. Please review $pjsua_log for more information."
	exit "$STATE_CRITICAL"
fi

# If above criterias was not met, exit OK
echo "OK: Registration and call completed successfully."
exit "$STATE_OK"
