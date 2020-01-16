#!/usr/bin/env bash

#########################
######### VARS ##########
#########################

VERSION=0.1.0
VERSION_SERVER=$(curl --silent https://codeberg.org/beli3ver/lxdBackup/raw/branch/master/VERSION)
GPG_ENCRYPTION=y
LOG_TIMESTAMP=$(date +"%m/%d/%Y %H:%M:%S")
if [ -z "$BACKUPDIR" ]; then BACKUPDIR="/tmp/lxdbackup"; fi
BACKUPDATE=$(date +"%m-%d-%y-%H-%M")
LXC=$(which lxc 2> /dev/null)
AWK=$(which awk 2> /dev/null)
GPG=$(which gpg 2> /dev/null)
SSH=$(which ssh 2> /dev/null)
RSYNC=$(which rsync 2> /dev/null)
SSH_PORT=
RSYNC_PATH=
GPG_TTY=$(tty)
ERROR="\033[0;31m [$LOG_TIMESTAMP] [ERROR] "
SUCCSESS="\033[0;32m [$LOG_TIMESTAMP] [INFO] "
NC="\033[0m"

#########################
####### FUNCTIONS #######
#########################

usage()
{
    echo -e  "$(basename "$0") -- script to backup and sync lxd container to external/internal repo"
    echo -e  ""
    echo -e  "\t-a | --all                    backup all container"
    echo -e  "\t-cj | --cron                  backup script im cron modus, look in the docu for more information"
    echo -e  "\t-c= | --container=            backup container"
    echo -e  "\t-d= | --dir=                  path to the backup dir"
    echo -e  "\t-doi | --delete-old-images    delete old images"
    echo -e  "\t-doa | --delete-old-archives  delete old archives"
    echo -e  "\t-s= | --sshport=              SSH Port"
    echo -e  "\t-rs= | --rsyncpath=           Path for rsync target"
    echo -e  "\t-h | --help                   show this help message"
    echo -e  "\t-p= | --pass=                 password for gpg encryption"
    echo -e  "\t-v | --version                print version & third party version"
    echo -e  ""
}

version_check() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

version() {
    echo -e "Version: ${VERSION}"
    echo -e "Server Version: ${VERSION_SERVER}"
    if version_check ${VERSION_SERVER} ${VERSION}; then
        echo -e "\033[0;31m[WARNING] You don't have the latest version. Please update to the latest version!\033[0m"
    fi
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

    if [ -z "$GPG" ]; then
        echo -e "${ERROR}GPG command NOT found?${NC}";
        exit 1 ;
    fi

    if [ -z "$SSH" ]; then
        echo -e "${ERROR}SSH command NOT found?${NC}";
        exit 1 ;
    fi

    if [ -z "$RSYNC" ]; then
        echo -e "${ERROR}RSYNC command NOT found?${NC}";
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
        if $LXC image delete $LXCIMAGE > /dev/null; then
            echo -e "${SUCCSESS}Image: Auto delete from $LXCIMAGE succesfully. ${NC}"
        else
            echo -e "${ERROR}Image: Can not delete $LXCIMAGE. ${NC}"
        fi
    done
}

delete_old_archives() {
    if [ ! -d "$BACKUPDIR" ]; then
        echo -e "${ERROR}Archiv: Auto delete from old archives not possible. There are no archives in the current working dir. Current working dir: ${BACKUPDIR} ${NC}"
    else
        if rm $BACKUPDIR/* > /dev/null; then
            echo -e "${SUCCSESS}Archiv: Auto delete succesfully. ${NC}"
        else
            echo -e "${ERROR}Archiv: Auto delete not succesfully. ${NC}"
        fi
    fi
}

sync() {
  [ -f $BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz.gpg ] FILE=$BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz.gpg
  [ -f $BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz ] FILE=$BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz
  if [[ -z "$RSYNC_PATH" && -z $RSYNC ]]
  then
    if [ -z $SSH_PORT ]
    then
      if $RSYNC --progress --delete $FILE $RSYNC_PATH > /dev/null; then
        echo -e "${SUCCSESS}SYNC: Sync $FILE succesfully. ${NC}"
      else
        echo -e "${ERROR}SYNC: Cloud not sync $FILE. ${NC}"
      fi
    else
      if $RSYNC --progress -e "ssh -p$SSH_PORT" --delete $FILE $RSYNC_PATH > /dev/null; then
        echo -e "${SUCCSESS}SYNC: Sync $FILE succesfully. ${NC}"
      else
        echo -e "${ERROR}SYNC: Cloud not sync $FILE. ${NC}"
      fi
    fi
  fi
}

backup_all() {
    for LXCCONTAINER in $CONTAINERLIST
    do
        backup
    done
}

backup() {
    if [ ! -d "$BACKUPDIR" ]; then
        mkdir $BACKUPDIR && cd $BACKUPDIR
        echo -e "${SUCCSESS}Backup directory: $BACKUPDIR created for temporary backup storage ${NC}"
    else
        cd $BACKUPDIR
    fi

    # Create snapshot with date as name
    if $LXC snapshot $LXCCONTAINER $BACKUPDATE > /dev/null; then
        echo -e "${SUCCSESS}Snapshot: Succesfully created snaphot $BACKUPDATE on container $LXCCONTAINER ${NC}"
    else
        echo -e "${ERROR}Snapshot: Could not create snaphot $BACKUPDATE on container $LXCCONTAINER ${NC}"
        return 1
    fi

    if $LXC publish --force $LXCCONTAINER/$BACKUPDATE --alias $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE > /dev/null; then
        echo -e "${SUCCSESS}Publish: Succesfully published an image of $LXCCONTAINER-BACKUP-$BACKUPDATE to $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE ${NC}"
    else
        echo -e "${ERROR}Publish: Could not create image from $LXCCONTAINER-BACKUP-$BACKUPDATE to $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE ${NC}"
        return 1
    fi

    # Export lxc image to image.tar.gz file.
    if $LXC image export $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE > /dev/null; then
        echo -e "${SUCCSESS}Image: Succesfully exported an image of $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE to $BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz ${NC}"
    else
        echo -e "${ERROR}Image: Could not publish image from $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE to $BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz ${NC}"
        exit 1
    fi

    if [[ $GPG_ENCRYPTION =~ ^[Yy]$ ]]
    then
        if [ -z "$GPGPASS" ]
        then
            echo -e "${ERROR}Archiv: Passphrase not set. Can not encrypt archives. ${NC}"
            sync
        else
            if echo $GPGPASS | gpg --batch --yes --passphrase-fd 0 --cipher-algo AES256 -c $BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz; then
                echo -e "${SUCCSESS}Archiv: Succesfully encrypted ${NC}"
                echo -e "${SUCCSESS}################################################## ${NC}"
                echo -e "${SUCCSESS}### Your GPG Password: $GPGPASS ### ${NC}"
                echo -e "${SUCCSESS}################################################## ${NC}"
                rm  $BACKUPDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz
                sync
            else
                echo -e "${ERROR}Archiv: Can not encrypt archiv. ${NC}"
                sync
            fi
        fi
    fi
}

#########################
######### MAIN ##########
#########################

## validate parameters and arguments
###
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -p | --pass)
            GPGPASS=$VALUE
            ;;
        -d | --dir)
            BACKUPDIR=$VALUE
            ;;
        -s | --sshport)
            SSH_PORT=$VALUE
            ;;
        -rs | --rsyncpath)
            RSYNC_PATH=$VALUE
            ;;
        -a | --all)
            check_software
            backup_all
            ;;
        -cj | --cron)
            check_software
            if [[ -z "$ALL_CONTAINER" || $ALL_CONTAINER =~ ^[Nn]$ ]]; then
                if [ -z "$LXCCONTAINER" ]; then
                    echo -e "${ERROR}No container set, it is not possible to backup anything. Please take a look at the docu.${NC}";
                    exit 1 ;
                else
                    backup
                fi
            else
                backup_all
            fi

            ;;
        -c | --container)
            check_software
            LXCCONTAINER=$VALUE
            backup
            ;;
        -doi | --delete-old-images)
            check_software
            delete_old_images
            ;;
        -doa | --delete-old-archives)
            delete_old_archives
            ;;
        -h | --help)
            usage
            exit
            ;;
        -v | --version)
            version
            exit
            ;;
        *)
            echo -e "${ERROR}Software: unknown parameter \"$PARAM\"${NC}"
            usage
            exit 1
            ;;
    esac
    shift
done
