#!/bin/bash
echo 'INFO: You may need root privilege to execute this.'

echo 268 > /sys/class/backlight/intel_backlight/brightness
