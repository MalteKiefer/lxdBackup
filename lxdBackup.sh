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
}

check_software() {
    if [ -z "$LXC" ]; then
        echo -e "${ERROR}LXC command NOT found?${NC}";
        exit 1 ;
    else
      CONTAINERLIST="$(${LXC} list -c ns | ${AWK} '!/NAME/{ if ( $4 == "RUNNING" ) print $2}')"
      IMAGELIST="$(${LXC} image list -c f | ${AWK} '!/FINGERPRINT/{ print $2}')"
    fi

    if [ -z "$AWK" ]; then
        echo -e "${ERROR}RESTIC command NOT found?${NC}";
        exit 1 ;
    fi

    if [ -z "$RSYNC" ]; then
        echo -e "${ERROR}RSYNC command NOT found?${NC}";
        exit 1 ;
    fi

    if [ -z "$GPG" ]; then
        echo -e "${ERROR}GPG command NOT found?${NC}";
        exit 1 ;
    fi

    if [ -z "$LXC" ]; then
        echo -e "${ERROR}LXC command NOT found?${NC}";
        exit 1 ;
    fi

}

delete_old_images() {
  for LXCIMAGE in $IMAGELIST
  do
    if $LXC image delete $LXCIMAGE; then
      echo -e "${SUCCSESS}Image: Auto delete from $LXCIMAGE succesfully. ${NC}"
    else
      echo -e "${ERROR}Image: Cloud not delete $LXCIMAGE. ${NC}"
    fi
  done
}

delete_old_archives() {
  if [ ! -d "$WORKDIR" ]; then
    echo -e "${ERROR}Archiv: Auto delete from old archives not possible. There are no archives in the current working dir. Current working dir: ${WORKDIR} ${NC}"
  else
    if rm $WORKDIR/*; then
      echo -e "${SUCCSESS}Archiv: Auto delete succesfully. ${NC}"
    else
      echo -e "${ERROR}Archiv: Auto delete not succesfully. ${NC}"
    fi
  fi
}


#########################
######### VARS ##########
#########################

VERSION=0.0.1
GPG_ENCRYPTION=y
LOG_FILE="/var/log/lxdbackup.log"
LOG_FILE_TIMESTAMP="%m/%d/%Y %H:%M:%S"
GPGPASS=""
WORKDIR="/tmp/lxdbackup"
BACKUPDATE=$(date +"%m-%d-%y-%H-%M")
LXC=$(which lxc 2> /dev/null)
AWK=$(which awk 2> /dev/null)
RSYNC=$(which rsync 2> /dev/null)
GPG=$(which gpg)
GPG_TTY=$(tty)
ERROR='\033[0;31m'
SUCCSESS='\033[0;32m'
NC='\033[0m'

#########################
######### MAIN ##########
#########################

## check the software on the system
###
check_software

## validate parameters and arguments
###
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
        -doi | --delete-old-images)
            delete_old_images
            ;;
        -doa | --delete-old-archives)
            delete_old_archives
            ;;
        *)
            echo -e "${ERROR}ERROR: unknown parameter \"$PARAM\"${NC}"
            usage
            exit 1
            ;;
    esac
    shift
done

## run backup
###
main
