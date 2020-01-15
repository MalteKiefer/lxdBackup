#!/bin/#!/usr/bin/env bash

#########################
####### FUNCTIONS #######
#########################


usage()
{
  echo -e  "$(basename "$0") -- script to backup and sync lxd container to external/internal repo"
  echo -e  ""
  echo -e "\t-h --help"
  echo -e  "\t-h | --help     show this help message"
  echo -e  "\t-p | --pass     password for gpg encryption"
  echo -e  "\t-v | --version  print version & third party version"
  echo -e  ""
}
version() {
  echo -e  "Version: ${VERSION}"
  echo -e  "GPG Version: $(gpg --version | head -n1 | awk '{print $3}')"
  echo -e  "RSYNC Version: $(rsync --version | head -n1 | awk '{print $3}')"
}

#########################
######### VARS ##########
#########################

VERSION=0.0.1
AUTO_DELETE_OLD_IMAGES=y
AUTO_DELETE_OLD_ARCHIVES=y
GPG_ENCRYPTION=y
LOG_FILE="/var/log/lxdbackup.log"
LOG_FILE_TIMESTAMP="%m/%d/%Y %H:%M:%S"
GPGPASS=""
WORKDIR="/tmp/lxdbackup"
BACKUPDATE=$(date +"%m-%d-%y-%H-%M")

#########################
######### MAIN ##########
#########################

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -v | --version)
        version
        exit
        ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done
