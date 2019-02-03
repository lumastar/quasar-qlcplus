#!/bin/bash

# This script requires wiringPi and uses the 'gpio' command that it provides

if [ -z $1 ] || [ -z $1 ] || [ -z $1 ]; then
	echo "usage: $0 [input pin BCM number] [output pin BCM number] [no kiosk temp file path]"
	exit 1
fi

# Get the BCM GPIO pin number and location to create temportary QLC+ no kiosk
# indicator file
INPUT_PIN=$1
OUTPUT_PIN=$2
NO_KIOSK_PATH=$3

echo "input pin: $INPUT_PIN, output pin: $OUTPUT_PIN, no kiosk path: $NO_KIOSK_PATH"

# If the GPIO pin numbers are not in range then exit
if [ "$INPUT_PIN" -lt 0 ] || [ "$INPUT_PIN" -gt 27 ] || [ "$OUTPUT_PIN" -lt 0 ] || [ "$OUTPUT_PIN" -gt 27 ]; then
	echo "BCM pin numbers must be between 0 and 27"
	exit 1
fi

# Option -g to use BCM numbers, same as QLC+
gpio -g mode "$INPUT_PIN" in
# Use interneal pull up resistors
gpio -g mode "$INPUT_PIN" up
# Set mode to output
gpio -g mode "$OUTPUT_PIN" out

# The number of seconds for which the pin has been read as '1'
COUNT=0

# Sleep for 2 seconds so QLC+ has time to start, then get process ID to watch
sleep 2
PID=$(pidof qlcplus)

# Write 1 to illuminate LED
gpio -g write "$OUTPUT_PIN" 1

# Loop while QLC+ process ID is active
# Note that checking process by ID rather than by name prevents
# this script from running through a QLC+ restart which can lead
# to undesirable behaviour
while ps -p $PID > /dev/null; do
	if [[ $(gpio -g read $INPUT_PIN) = 0 ]]; then
		((COUNT++))
		if [[ "$COUNT" -ge 12 ]]; then
			gpio -g write "$OUTPUT_PIN" 0
			sleep 1
		elif [[ "$COUNT" -ge 8 ]]; then
			gpio -g write "$OUTPUT_PIN" 0
			sleep 0.125
			gpio -g write "$OUTPUT_PIN" 1
			sleep 0.125
			gpio -g write "$OUTPUT_PIN" 0
			sleep 0.125
			gpio -g write "$OUTPUT_PIN" 1
			sleep 0.125
			gpio -g write "$OUTPUT_PIN" 0
			sleep 0.125
			gpio -g write "$OUTPUT_PIN" 1
			sleep 0.125
			gpio -g write "$OUTPUT_PIN" 0
			sleep 0.125
			gpio -g write "$OUTPUT_PIN" 1
			sleep 0.125
		elif [[ "$COUNT" -ge 4 ]]; then
			gpio -g write "$OUTPUT_PIN" 0
			sleep 0.25
			gpio -g write "$OUTPUT_PIN" 1
			sleep 0.25
			gpio -g write "$OUTPUT_PIN" 0
			sleep 0.25
			gpio -g write "$OUTPUT_PIN" 1
			sleep 0.25
		else
			gpio -g write "$OUTPUT_PIN" 0
			sleep 0.5
			gpio -g write "$OUTPUT_PIN" 1
			sleep 0.5
		fi
	else
		if [[ "$COUNT" -ge 12 ]]; then
			gpio -g write "$OUTPUT_PIN" 0
			reboot
			exit 0
		elif [[ "$COUNT" -ge 8 ]]; then
			gpio -g write "$OUTPUT_PIN" 0
			touch "$NO_KIOSK_PATH"
			service qlcplus restart
			exit 0
		elif [[ "$COUNT" -ge 4 ]]; then
			gpio -g write "$OUTPUT_PIN" 0
			service qlcplus restart
			exit 0
		fi
		COUNT=0
		sleep 1
	fi
done

gpio -g write "$OUTPUT_PIN" 0
exit 0
