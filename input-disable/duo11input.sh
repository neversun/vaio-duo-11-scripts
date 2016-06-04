#!/bin/bash
# Modified by Robert Scheinpflug (https://github.com/neversun/vaio-duo-11-scripts)
if [ $# -ne 4 ]; then
  echo 'USAGE: ./duo11input.sh [disableTouchscreenOnDigitizer] [disableOpticalMouseOnKeyPressed] [enable TouchscreenOnDigitizerNotification] [enable OpticalMouseOnKeyPressedNotification]'
  echo 'example: /duo11input.sh true false false false'
  exit
fi

enableTouchscreenOnDigitizerDisabler=$1
enableOpticalMouseOnKeyPressedDisabler=$2

# Original by Aaron Fleming (https://help.ubuntu.com/community/Laptop/Sony/Vaio/Duo11/Trusty)
# Copied from:
# http://ubuntuforums.org/showthread.php?t=2141992&p=12892039#post12892039
# Adapted for Vaio Duo 11: removed reference to 'erasor', added references to 'key' and 'pad'
# let the key states clear
sleep 1
#Parameter
interval=0.2
#bash supports integer arithmetic. cleaned up nested ifs and "sleep $off" below.
#1. new value 'threshold' is effectively off / interval
#2. a counter increments every loop, which occurs every interval
#3. old code used to sleep for value of "off"
threshold=10
off=2
counter=0
counter2=0
DevNameTouch="N-trig DuoSense"
DevNamePen="N-trig DuoSense Pen"
DevNamePad="Crucialtek co.,LTD Optical Track Pad"
DevNameKey="AT Translated Set 2 keyboard"

#notification on or off
function boolean() {
  case $1 in
    true) echo true ;;
    TRUE) echo true ;;
    false) echo false ;;
    FALSE) echo false ;;
    *) echo "Err: Unknown boolean value \"$1\"" 1>&2; exit 1 ;;
  esac
}

notifyPen="$(boolean "$3")"
notifyPad="$(boolean "$4")"

#Initialize Variables
id_touch=$(xinput --list --id-only "$DevNameTouch")
id_pen=$(xinput --list --id-only "$DevNamePen")
id_pad=$(xinput --list --id-only "$DevNamePad")
id_key=$(xinput --list --id-only "$DevNameKey")

xPosPen=$(xinput --query-state $id_pen | grep valuator | cut -d= -f2 | head -n1)
xPosPenOld=$xPosPen
#no point setting these here - they should be empty (no keys held down) to start with anyway
#xPosKey=$(xinput --query-state $id_key | grep down | cut -d= -f2 | head -n1)
xPosKey=""
#xPosKeyOld=$xPosKey
xPosKeyOld=""

#Recognize movement of Pen or keypress
while true
do
  devEnabled=$(xinput --list-props $id_touch | awk '/Device Enabled/{print $NF}')
  padEnabled=$(xinput --list-props $id_pad | awk '/Device Enabled/{print $NF}')

  xPosPen=$(xinput --query-state $id_pen | grep valuator | cut -d= -f2 | head -n1)
  xPosKey=$(xinput --query-state $id_key | grep down | cut -d= -f2 | head -n1)

  # Touchscreen and pen section
  if [ "enableTouchscreenOnDigitizerDisabler" == "true" ]; then
    if [ $devEnabled == 1 ]; then
      if [ "$xPosPen" != "$xPosPenOld" ]; then
        xinput disable $id_touch
        ((counter=0))
        if [ "$notifyPen" == "true" ]; then
          notify-send -u low -t 1 -i display "$DevNameTouch disabled" "$DevNamePen active"
        fi
      fi
    else
      if [ "$xPosPen" == "$xPosPenOld" ]; then
        #if no movement increment counter
        ((counter++))
        #sleep $off
      fi
      if (( counter > threshold )); then
        #if no movement for several iterations then enable:
        xinput enable $id_touch
        ((counter=0))
        if [ "$notifyPen" == "true" ]; then
          notify-send -u low -t 1 -i display -i display "$DevNameTouch enabled"
        fi
      fi
    fi
  fi

  #Pad and keyboard section
  if [ "$enableOpticalMouseOnKeyPressedDisabler" == "true" ]; then
    if [ $padEnabled == 1 ]; then
      #if [ "$xPosKey" != "$xPosKeyOld" ]; then
      if [ "$xPosKey" == "down" ]; then
        xinput disable $id_pad
        ((counter2=0))
        if [ "$notifyPad" == "true" ]; then
          notify-send -u low -t 1 -i mouse "$DevNamePad disabled" "$DevNameKey active"
        fi
      fi
    else
      #echo "Touchscreen off"
      if [ "$xPosKey" == "$xPosKeyOld" ]; then
        #if no movement increment counter
        ((counter2++))
      fi
      if (( counter2 > threshold )); then
        xinput enable $id_pad
        ((counter2=0))
        if [ "$notifyPad" == "true" ]; then
          notify-send -u low -t 1 -i display -i mouse "$DevNamePad enabled"
        fi
      fi
    fi
  fi

  xPosPenOld=$xPosPen
  xPosKeyOld=$xPosKey

  sleep $interval
done
