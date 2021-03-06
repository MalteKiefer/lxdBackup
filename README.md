# lxdBackup

## Installation
To install **lxdBackup** you only have to clone the repo.

```bash
git clone https://codeberg.org/beli3ver/lxdBackup
```

To run the program just add the path to your enviroment Path variable or just do:

```bash
bash lxdBackup.sh
```
**Attention: without parameter the program will do nothing**

## Running

To run the backup program you must start it with one of these parameters:

```bash
	-a | --all                    backup all container
	-cj | --cron                  backup script im cron modus, look in the docu for more information
	-c= | --container=            backup container
	-d= | --dir=                  path to the backup dir
	-doi | --delete-old-images    delete old images
	-doa | --delete-old-archives  delete old archives
	-s= | --sshport=              SSH Port
	-rs= | --rsyncpath=           Path for rsync target
	-h | --help                   show this help message
	-p= | --pass=                 password for gpg encryption
	-v | --version                print version & third party version
```

The easiest would be to do:

```bash
/usr/bin/bash lxdBackup.sh --all
```

## Cron
To run the software in the cron modus start it with this parameter:

```bash
/usr/bin/bash lxdBackup.sh --cron
```

It is important that on of these two paramter is set:

```bash
export ALL_CONTAINER=y
```
or
```bash
export LXCCONTAINER=name-of-the-container
```
optional you can change the backup dir
```bash
export BACKUPDIR=/backup/
```

For GPG support look at the GPG section.

To get a log when you run the program in the cron mode just do something like this in your crontab:

```
#that will run every 4 hours
0 */4 * * * /usr/bin/bash /path/to/lxdBackup/lxdbackup.sh --cron > /path/to/log
```

## GPG
To use the GPG encryption you must set the a GPG passphrase as a enviroment variable or at the begining of the script call:

```bash
/usr/bin/bash lxdBackup.sh --pass=myStrongPassword --all
```

**Attention: It is important that the `--pass=` is the first parameter when you call the script!**

The enviroment variable looks like this:

```bash
export GPGPASS=myStrongPassword

/usr/bin/bash lxdBackup.sh --all
```

## Log

Sample log output:

```bash
 [01/16/2020 08:47:54] [INFO] Snapshot: Succesfully created snaphot 01-16-20-08-47 on container proxy
 [01/16/2020 08:47:54] [INFO] Publish: Succesfully published an image of proxy-BACKUP-01-16-20-08-47 to proxy-BACKUP-01-16-20-08-47-IMAGE
 [01/16/2020 08:47:54] [INFO] Image: Succesfully exported an image of proxy-BACKUP-01-16-20-08-47-IMAGE to /tmp/lxdbackup/proxy-BACKUP-01-16-20-08-47-IMAGE.tar.gz
 [01/16/2020 08:47:54] [INFO] Archiv: Succesfully encrypted
 [01/16/2020 08:47:54] [INFO] ##################################################
 [01/16/2020 08:47:54] [INFO] ### Your GPG Password: myStrongPassword ###
 [01/16/2020 08:47:54] [INFO] ##################################################
 ```
