#!/bin/bash
# 2019-03-07 / dosman / parse rtl_433 csv files and eliminate empty columns
#			Assumed that first row is header, if multiple header
#			rows exist it will cause output to match the input.
#############################################################################

usage() {
	echo "Reads in rtl_433 csv files and reduces unused columns"
	echo "Usage:"
	echo "$0 <inputfile.csv>"
	exit
}

if [[ -z $1 ]];then
	usage
elif [[ ! -e $1 ]];then
	usage
else
	INPUT=$1
fi

#############################################################################

buildArray() {
# Build an array that indicates which columns to keep, which ones to reduce
typeset INPUT=$1
for line in `cat $INPUT | tr " " "~"`;do
	if [[ -z $LINESKIP ]];then
		# Assume we want to ignore the top header row which has all fields full
		typeset LINESKIP=0
		continue
	fi
	typeset COUNT=1
	#ENDCOUNT=174

	#tracking array == COLUMN
	for col in `echo $line | sed "s/,/-\n/g"`;do
		#echo "COUNT = $COUNT // col = \"${col}\""
		if [[ $col == "-" ]];then
			# column is empty, exclude
			if [[ ${COLUMN[$COUNT]} == "" ]];then
				# only set to zero if empty, we want to build out 1s for every populated column
				COLUMN[$COUNT]=0
			fi
		else
			# column has data, keep column
			COLUMN[$COUNT]=1
		fi
		COUNT=`expr $COUNT + 1`
	done
	unset LINESKIP
done
}

columnReduce() {
typeset INPUT=$1
for line in `cat $INPUT | tr " " "~"`;do
	typeset COUNT=1
	for col in `echo $line | sed "s/,/-\n/g"`;do
		if [[ ${COLUMN[$COUNT]} == 1 ]];then
			if [[ $col != "-" ]];then
				echo $col |tr "~" " " | sed "s/-$/,/g" | tr -d "\n"
			else
				printf ","
			fi
		fi
		COUNT=`expr $COUNT + 1`
	done
	printf "\n"
done
}

#############################################################################

buildArray $INPUT
columnReduce $INPUT

