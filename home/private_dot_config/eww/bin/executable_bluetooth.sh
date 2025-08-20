#!/bin/sh

set -o pipefail

if [ "$(bluetoothctl show | grep "Powered: yes" -c)" -eq 0 ]; then
	echo "󰂲"
else
  if [ "$(bluetoothctl devices Connected | grep "^Device" -c)" -eq 0 ]; then
		echo ""
	else
		echo "󰂱"
	fi
fi
