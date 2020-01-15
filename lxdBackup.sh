#!/usr/bin/env bash

#########################
######### VARS ##########
#########################

VERSION=0.0.2
GPG_ENCRYPTION=y
LOG_FILE="/var/log/lxdbackup.log"
LOG_FILE_TIMESTAMP=$(date +"%m/%d/%Y %H:%M:%S")
LOG_LEVEL="> /dev/null"
GPGPASS=""
WORKDIR="/tmp/lxdbackup"
BACKUPDATE=$(date +"%m-%d-%y-%H-%M")
LXC=$(which lxc $LOG_LEVEL)
AWK=$(which awk $LOG_LEVEL)
RSYNC=$(which rsync $LOG_LEVEL)
GPG=$(which gpg $LOG_LEVEL)
GPG_TTY=$(tty)
ERROR="\033[0;31m [$LOG_FILE_TIMESTAMP] [ERROR] "
SUCCSESS="\033[0;32m [$LOG_FILE_TIMESTAMP] [INFO] "
NC="\033[0m"

#########################
####### FUNCTIONS #######
#########################

usage()
{
    echo -e  "$(basename "$0") -- script to backup and sync lxd container to external/internal repo"
    echo -e  ""
    echo -e  "\t-d | --debug                  debug level: info, error, nothing"
    echo -e  "\t-doi | --delete-old-images    delete old images"
    echo -e  "\t-doa | --delete-old-archives  delete old archives"
    echo -e  "\t-h | --help                   show this help message"
    echo -e  "\t-p= | --pass=                  password for gpg encryption"
    echo -e  "\t-v | --version                print version & third party version"
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
        if $LXC image delete $LXCIMAGE $LOG_LEVEL; then
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
        if rm $WORKDIR/* $LOG_LEVEL; then
            echo -e "${SUCCSESS}Archiv: Auto delete succesfully. ${NC}"
        else
            echo -e "${ERROR}Archiv: Auto delete not succesfully. ${NC}"
        fi
    fi
}

main() {
    if [ ! -d "$WORKDIR" ]; then
        mkdir $WORKDIR && cd $WORKDIR
        echo -e "${SUCCSESS}Backup directory: $WORKDIR created for temporary backup storage ${NC}"
    else
        cd $WORKDIR
    fi

    # Create snapshot with date as name
    if $LXC snapshot $LXCCONTAINER $BACKUPDATE $LOG_LEVEL; then
        echo -e "${SUCCSESS}Snapshot: Succesfully created snaphot $BACKUPDATE on container $LXCCONTAINER ${NC}"
    else
        echo -e "${ERROR}Snapshot: Could not create snaphot $BACKUPDATE on container $LXCCONTAINER ${NC}"
        return 1
    fi

    if $LXC publish --force $LXCCONTAINER/$BACKUPDATE --alias $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE $LOG_LEVEL; then
        echo -e "${SUCCSESS}Publish: Succesfully published an image of $LXCCONTAINER-BACKUP-$BACKUPDATE to $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE ${NC}"
    else
        echo -e "${ERROR}Publish: Could not create image from $LXCCONTAINER-BACKUP-$BACKUPDATE to $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE ${NC}"
        cleanup
        return 1
    fi

    # Export lxc image to image.tar.gz file.
    if $LXC image export $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE $LOG_LEVEL; then
        echo -e "${SUCCSESS}Image: Succesfully exported an image of $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE to $WORKDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz ${NC}"
    else
        echo -e "${ERROR}Image: Could not publish image from $LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE to $WORKDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz ${NC}"
        cleanup
        exit 1
    fi

    if [[ $GPG_ENCRYPTION =~ ^[Yy]$ ]]
    then
        if [ -z "$GPGPASS" ]
        then
            echo -e "${ERROR}Archiv: Passphrase not set. Can not encrypt archives. ${NC}"
        else
            if echo $GPGPASS | gpg --batch --yes --passphrase-fd 0 --cipher-algo AES256 -c $WORKDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz; then
                echo -e "${SUCCSESS}Archiv: Succesfully encrypted ${NC}"
                echo -e "${SUCCSESS}########################################################## ${NC}"
                echo -e "${SUCCSESS}### Your GPG Password:$GPGPASS ### ${NC}"
                echo -e "${SUCCSESS}########################################################## ${NC}"
                rm  $WORKDIR/$LXCCONTAINER-BACKUP-$BACKUPDATE-IMAGE.tar.gz
            else
                echo -e "${ERROR}Archiv: Cloud not encrypt archiv. ${NC}"
                cleanup
                exit 1
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
        -h | --help)
            usage
            exit
            ;;
        -v | --version)
            version
            exit
            ;;
        -d | --debug)
            if [[ $VALUE == "info" ]]; then
              LOG_LEVEL="2> /dev/null"
            elif [[ $VALUE == "error" ]]; then
              LOG_LEVEL="1> /dev/null"
            else
              LOG_LEVEL="> /dev/null"
            fi
            ;;
        -doi | --delete-old-images)
            check_software
            delete_old_images
            ;;
        -doa | --delete-old-archives)
            delete_old_archives
            ;;
        -p | --pass)
            GPGPASS=$VALUE
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
check_software
for LXCCONTAINER in $CONTAINERLIST
do
  main
done
