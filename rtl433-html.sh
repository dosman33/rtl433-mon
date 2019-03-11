#!/bin/bash
# 2019-03-07 / dosman / Parse rtl_433 csv files into html viewable/navigable output
#
# Call from cron like this:
#0,10,20,30,40,50 * * * * /home/pi/bin/rtl433-html.sh /var/www/html/rtl433/csv/$(/bin/date +\%Y\%m\%d)_rtl.log
#
#############################################################################

DATE=`date`
COLUMNREDUCE=/home/pi/bin/column-reduce.sh

DATEFILE=`date +%Y%m%d`
OUTPATH=/var/www/html/rtl433
DB=${OUTPATH}/rtl433.state.csv

HTMLOUT=${OUTPATH}/${DATEFILE}.html
# symlink "daily.html" to current date file or something

HTMLTITLE="RTL 433"

#############################################################################

TMP1=/tmp/$$_rtl433_parse01.tmp
TMP2=/tmp/$$_rtl433_parse02.tmp
TMP3=/tmp/$$_rtl433_parse03.tmp

cleanup() {
        rm -rf $TMP1
        rm -rf $TMP2
        rm -rf $TMP3
}
trap 'echo "--Interupt signal detected, cleaning up and exiting" ; cleanup ; exit 1' 2 3        #SIGINT SIGQUIT

usage() {
	#echo "Reads in rtl_433 csv files and updates a state file for persistant stats on transmissions"
	echo "Reads in rtl_433 csv files and reduces empty columns. Output can be html-ified"
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

date_mangle() {
# Subtract n number of days from current date, default output is numeric dates with leading zeros on 1-digit days and months
# $1 = number of days to subtract, assumes 1 if nothing specified

# $2 = changes output formatting if specified, valid input: -0, -1, -2:
# Default output:                        09 06 10  = June 9th, 2010
# No leading zeros:                 -0:  9 6 10    = June 9th, 2010
# Alpha month:                      -1:  09 Jun 10 = June 9th, 2010
# No leading zeros and alpha month: -2:  9 Jun 10  = June 9th, 2010

if [[ -z $1 ]];then
        typeset day_in=1
else
        typeset day_in=$1
fi
if [[ -n $2 ]];then
        # Configure how output should look: default is no leading zeros for numbers, all numeric output
        typeset zero
        typeset alpha
        case $2 in
                -0) zero=1 ;;
                -1) alpha=1 ;;
                -2) zero=1 ; alpha=1 ;;
                *) # invalid input, just give default output
                   true
                   ;;
        esac
fi

typeset MM=`date +"%m"`
typeset DD=`date +"%d"`
typeset YY=`date +"%y"`
typeset i0001=0
until [[ $i0001 = $day_in ]]
do
        i0001=`expr $i0001 + 1`
        DD=`expr $DD - 1`
        #if [[ $DD -eq 0 ]];then
        if [[ $DD == "0" ]];then
                DD=31
                MM=`expr $MM - 1`
                if [[ $(echo ${MM}|wc -c|tr -d " ") = "2" ]];then
                        MM=0${MM}
                fi
                #echo 'if [[ $MM -eq 0 ]];then---------------------------------------'
                # This chokes on 9-12 (months) because it thinks 0 is octal rather than decimal... Need to fix some day - NTH 10-12-12
                # It hits this when called on the first day of a new month from Oct - Dec!
                #if [[ $MM -eq 0 ]];then
                if [[ $MM == "0" ]];then
                        MM=12
                        YY=`expr $YY - 1`
                #elif [[ $MM -eq 2 && DD=29 ]];then
                elif [[ $MM == "2" && $DD == "29" ]];then
                        DD=28
                fi
                if [ $MM == "4" ];then DD=30;fi
                if [ $MM == "6" ];then DD=30;fi
                if [ $MM == "9" ];then DD=30;fi
                if [ $MM == "11" ];then DD=30;fi
        fi
done
if [[ $alpha = 1 ]];then
        case $MM in
                01) MM=Jan ;;
                02) MM=Feb ;;
                03) MM=Mar ;;
                04) MM=Apr ;;
                05) MM=May ;;
                06) MM=Jun ;;
                07) MM=Jul ;;
                08) MM=Aug ;;
                09) MM=Sep ;;
                10) MM=Oct ;;
                11) MM=Nov ;;
                12) MM=Dec ;;
        esac
fi
if [[ $zero = 1 && $alpha != 1 ]];then
        #Strip leading 0's
        MM=`expr $MM + 0`   # Strip leading 0's
        DD=`expr $DD + 0`   # Strip leading 0's
elif [[ $zero = 1 && $alpha = 1 ]];then
        #Strip leading 0's, don't do month as it's not numeric
        DD=`expr $DD + 0`   # Strip leading 0's
else
        #Insert zero into day if single digit number; months already do this by default
        if [[ $(echo ${DD}|wc -c|tr -d " ") = "2" ]];then
                DD=0${DD}
        fi
fi
#echo "${MM}${DD}0000${YY}"     # old AIX errpt date format
#echo "$DD $MM $YY"
echo "20${YY}${MM}${DD}"
unset zero alpha DD MM YY i0001
}


htmlHeader(){

typeset YESTERDAY=`date_mangle 1`

echo "<html><head><title>${HTMLTITLE}</title></head>
<META HTTP-EQUIV=\"REFRESH\" content=\"300\">
<META HTTP-EQUIV=\"EXPIRES\" content=\"Sat, 01 Jan 2000 00:00:00 GMT\">
</head><body bgcolor=\"white\">
<table width=\"50%\"><tr><td>
<dl><dd>
<h1>${HTMLTITLE}</h1>
<B>Last Updated:</B> $DATE <br>
<a href=\"/rtl433/${YESTERDAY}.html\">Prior Day</a>
<!--
<a href=\" \">Next Day</a>
-->
<table border width=\"80%\">
<tr bgcolor=\"#bbbbbb\">"

#<TH>TEMPERATURE</TH><TH>STATUS</TH></tr>" > $HTMLOUT

}

htmlFooter() {

echo "</table>
<br><br>Output generated by $0
</body></html>"

}

#############################################################################

$COLUMNREDUCE $INPUT > $TMP1
htmlHeader > $HTMLOUT

# uniq to filter out repeated tx packets which is common
COUNT=1
for line in `cat $TMP1 | uniq | tr " " "~"`;do
	# have to stick the dash in every field so we can pad out empty columns correctly
	for col in `echo $line | sed "s/,/-\n/g"`;do
		# Parse the header row differently from the data rows
		if [[ $COUNT == 1 ]];then
			# header row
			mycol=`printf "$col" | sed "s/-$//g"`
			printf "<th><B>$mycol</B></th>" | tr "~" " " >> $HTMLOUT
		else
			# data rows
			if [[ $col == "-" ]];then
				printf "<td> </td>" >> $HTMLOUT
			else
				mycol=`echo "$col" | sed "s/-$//g" | tr -d "\n"`
				printf "<td nowrap>$mycol</td>" | tr "~" " " >> $HTMLOUT
			fi
		fi
	done
	echo "</tr>" >> $HTMLOUT
	COUNT=2
done
htmlFooter >> $HTMLOUT

############################################################################
cleanup
