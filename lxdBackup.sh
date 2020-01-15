#!/bin/#!/usr/bin/env bash

#########################
####### FUNCTIONS #######
#########################

help_message() {
echo "$(basename "$0") [-h] [-c] -- script to backup and sync lxd container to external/internal repo

--- Parameters ---
    -h  show this help message
    -c  path to config file (default: ~/.config/lxdbackup/config)"
}

#########################
######### VARS ##########
#########################
#YES/NO => y/n

AUTO_DELETE_OLD_IMAGES=y
AUTO_DELETE_OLD_ARCHIVES=y
GPG_ENCRYPTION=y
LOG_FILE="/var/log/lxdbackup.log"
LOG_FILE_TIMESTAMP="%m/%d/%Y %H:%M:%S"
GPGPASS="myStrongPassword"
WORKDIR="/tmp/lxdbackup"
BACKUPDATE=$(date +"%m-%d-%y-%H-%M")

#########################
######### MAIN ##########
#########################

while getopts ':hc:' option; do
  case "$option" in
    h) help_message
       exit
       ;;
    c) source $OPTARG
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       help_message >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       help_message >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))
