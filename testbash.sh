#!/bin/bash

function test(){
	echo "$@"
	echo "$1"
	echo "$2"

	if [ -z $2 ];then
		echo "inside -z"
	fi

	if [ -n $2 ];then
		echo "inside -n"
	fi
}

echo "out in main $@"

test "$@"
