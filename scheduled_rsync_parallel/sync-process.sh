#!/bin/bash

echo $0
echo "$@"
echo "$#"

# Need to fix: For now I am having issues with spaces and things in the options.
# if [[ $# -gt 0 ]]; then
#     # Grabs command line parameters for linking files
#     for i in $@
#     do
#         case ${i} in
#             # Where is the rsync bin
#             --rsyncbin=*)
#             RSYNCBIN=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
#             ;;
#             # rsync options
#             --rflags=*)
#             RFLAGS=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
#             ;;
#             # rsync protocol options
#             --rproto=*)
#             RPROTO=`echo ''\'"${i}"''\' | sed 's/[-a-zA-Z0-9]*=//'`
#             ;;
#             # source files to copy
#             --source=*)
#             SOURCE=`echo ''\"$i''\" | sed 's/[-a-zA-Z0-9]*=//'`
#             ;;
#             # destination of copy
#             --dest=*)
#             DEST=`echo ''\"$i''\" | sed 's/[-a-zA-Z0-9]*=//'`
#             ;;
#             # log directory
#             --logdir=*)
#             LOGDIR=`echo ''\"$i''\" | sed 's/[-a-zA-Z0-9]*=//'`
#             ;;
#             *)
#             # unknown option
#             echo "Unknown option! Please specify: $0 --rsyncbin= --rflags= --rproto= --source= --dest= --logdir="
#             exit 1
#             ;;
#         esac
#     done

RSYNCBIN="${1}"
RFLAGS="${2}"
RPROTO="${5}"
SOURCE="${3}"
DEST="${4}"
#LOGDIR="${5}"

echo `date`
echo ''\'"executing: $0 $@"''\'
if [[ "X${RPROTO}" == "X" ]]
then
    echo "no rproto options"
    echo ${RSYNCBIN} ${RFLAGS} "${SOURCE}" "${DEST}"
    time ${RSYNCBIN} ${RFLAGS} "${SOURCE}" "${DEST}"
else
    # NOTE: this does not currectly work due to an issue with quotes. It is either the rproto single quotes or
    # source/destination with server inside quotes.
    echo "using rproto options"
    echo ${RSYNCBIN} ${RFLAGS} "'"${RPROTO}"'" "'"${SOURCE}"'" "'"${DEST}"'"
    echo "remote parallel ssh does not currently work"
    # ${RSYNCBIN} ${RFLAGS} "'"${RPROTO}"'" "${SOURCE}" "${DEST}"
fi

echo `date`
echo "done"

# else
#     echo "Please specify: $0 --rsyncbin= --rflags= --rproto= --source= --dest= --logdir="
# fi