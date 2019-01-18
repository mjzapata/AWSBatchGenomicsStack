#!/bin/bash

#Example: ./sleepProgressBar.sh 5 6
#sleeps interval of 5 seconds, 6 times


if [ $# -eq 2 ]; then

	SLEEPINTERVAL=$1
	SLEEPCOUNT=$2
	COUNTER=0
	while [  $COUNTER -lt $SLEEPCOUNT ]; do
	     let COUNTER=COUNTER+1 
	     echo -n "."
	     sleep $SLEEPINTERVAL
	done
	echo ""
else
	echo "wrong number of arguments"

fi

