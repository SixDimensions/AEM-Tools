#!/bin/bash
if [ -z "$1" ]; then
    echo "No Sightly JS Class name supplied...exiting..."
    exit 1
else
	tail -f error.log | grep "$1"
fi
