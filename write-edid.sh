#!/bin/bash
#
# Writes EDID information over a given I2C-Bus to a monitor.
# Use: 1. write-edid.sh <bus> <data>
#      2. write-edid.sh <bus>
# The second variant expects data on stdin.
#
# You can find out the bus number with ic2detect -l. Address 0x50
# should be available as the EDID data goes there.
#
# This script expects ascii information representing chunks of hex data
# as input. The bytewise presented data should be separated by spaces
# and/or line breaks. For instance, this is the digital (!) EDID data
# for a Samsung SyncMaster T220 monitor:
#
#   00 FF FF FF FF FF FF 00 4C 2D E5 03 32 32 57 54
#   0E 12 01 03 80 2F 1E 78 2A EE 91 A3 54 4C 99 26
#   0F 50 54 BF EF 80 B3 00 81 80 81 40 71 4F 01 01
#   01 01 01 01 01 01 7C 2E 90 A0 60 1A 1E 40 30 20
#   36 00 DA 28 11 00 00 1A 00 00 00 FD 00 38 4B 1E
#   51 0E 00 0A 20 20 20 20 20 20 00 00 00 FC 00 53
#   79 6E 63 4D 61 73 74 65 72 0A 20 20 00 00 00 FF
#   00 48 39 58 51 34 30 31 30 34 38 0A 20 20 00 45
#
# Take care, you can destroy some hardware by messing around with i2c-tools.
# The scripts expects root permissions.
#
# This script is provided as is, without any further warrenty. It is
# released in public domain.
# 
# Tom Kazimiers
 
# i2c bus
BUS=""

# File name
FILE=""

if [ "$#" -lt "1" ]; then
  echo "Please specifiy a valid i2c bus as first parameter and the date as second one."
  echo "Use: write-edid <bus> <data>"
  exit 1
fi

BUS="$1"

# Make sure we get a file name as command line argument.
# If not, read it from std. input
if [ "$2" == "" ]; then
  FILE="/dev/stdin"
else
  FILE="$2"
  # make sure file exists and is readable
  if [ ! -f $FILE ]; then
    echo "$FILE : does not exist"
    exit 1
  elif [ ! -r $FILE ]; then
    echo "$FILE : can not be read"
    exit 2
  fi
fi

# Set loop separators to end of line and space
IFSBAK=$IFS
export IFS=$' \n\t\r'
# some field
edidLength=128
count=0
chipAddress="0x50"

exec 3<&0
exec 0<"$FILE"
for chunk in $(cat $FILE)
do
  # if we have reached 128 byte, stop
  if [ "$count" -eq "$edidLength" ]; then
    echo "done"
    break
  fi
  # convert counter to hex numbers of lentgh two, padded with zeros
  h=$(printf "%02x" "$count")
  dataAddress="0x$h"
  dataValue="0x$chunk"
  # give some feedback
  echo "Writing byte $dataValue to bus $BUS, chip-adress $chipAddress, data-adress $dataAddress"
  # write date to bus (with interactive mode disabled)
  i2cset -y "$BUS" "$chipAddress" "$dataAddress" "$dataValue"
  # increment counter
  count=$(($count+1))
  # sleep a moment
  sleep 0.1s
done
exec 0<&3

# restore backup IFS
IFS=$IFSBAK

echo "Writing done, here is the output of i2cdump -y $BUS 0x50:"
i2cdump -y "$BUS" 0x50
exit 0

