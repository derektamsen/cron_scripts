#!/bin/bash

# declare variables here
RSYNC="/usr/bin/rsync"                  # file location of rsync
RPROTO="ssh -i /root/.ssh/rsync-key"    # rsync proto options
FLAGS="-av -e"                          # rsync flags
SOURCE="/tmp/file_to_send"              # files to send
DEST="server2:/tmp/"                    # directory to store files
LOCKFILE="/var/lock/ha-sync"            # file location for lock file


echo "Starting sync ${SOURCE} to ${DEST}"

if [[ ! -f ${LOCKFILE} ]];
then
    touch ${LOCKFILE}
    time ${RSYNC} ${FLAGS} "${RPROTO}" ${SOURCE} ${DEST}
    rm -f ${LOCKFILE}

    echo "Finished sync ${SOURCE} to ${DEST}"
else
    echo Lock file exists...Exiting...
    echo "ERROR: Syncing ${SOURCE} to ${DEST}"
    exit 1
fi