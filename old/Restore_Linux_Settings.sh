#!/bin/bash
# use this to do a FULL backup to internal backup drive.
# fetch the linux version you are about to back up:
current_version=$(lsb_release -a | sed -n 's/Description:[\t]//p' | tr " " _)
source="/media/Daten/Linux_Backup/"
zip_files=$(find "$source" -mindepth 1 -maxdepth 1 -type f) # make array of zip files stored in source
#echo $zip_files
echo "Detected Linux Version:"
echo $current_version
echo "#########################################################"
echo "#########################################################"
echo "Detected backups of settings in $source."
echo "Please select Distribution to import settings from:"
echo ""
restore_methods=('complete (not recommended)' 'selected setting-files only' 'Quit') ## array of restoring options
options=($zip_files "Quit") ## adding quit as additional option
PS3="Please enter selection: "
QUIT="QUIT THIS PROGRAM"

select FILENAME in ${options[@]};
do
  case $FILENAME in
		"Quit")
            break
            ;;
        *)
          	echo "You picked $FILENAME ($REPLY)"
		  	echo "Now please select with which method you would like to restore your linux settings"
	     	 
          	;;
  esac
done

fi

################################################################################################################
################################################################################################################
echo "PLEASE BE SURE TO START SCRIPT WITH SUDO COMMAND!"
#echo "Starting Backup. We'll begin with Thinderbird (separate folder, non compressed)"
sleep 1
#mkdir -p /media/Daten/Email-Backups/Thunderbird_current_Backup
#rsync -auv --log-file=/home/user/$(date +%Y%m%d)_rsync.log --progress /home/user/.thunderbird/ /media/Daten/Email-Backups/Thunderbird_current_Backup
#echo "Thunderbird backup finished."
echo "Backing up home folder of current Linux distribution"
sleep 1
mkdir -p $destination
zip -r -y -u $destination$version /home/
echo "Backed up your home folder of Linux. This can become important when installing a new release of Linux Mint (personal settings)"
sleep 1
echo "Now backing up your etc-settings (all of them...thats why we are now encrypting)"
sleep 1
zip -r -y -u -e $destination$version /etc/
echo "Backed up your etc folder of Linux. This can become important when installing a new release of Linux Mint (some program settings)"
sleep 1
echo "Making a list of all of the programs you have installed with package manager"
sleep 1
mkdir -p /Installed_Programs
dpkg --list | grep -v -e '-dev' -e 'ii  lib' >/Installed_Programs/packages.txt
echo "Making a list of all of the programs you have installed from source or binaries"
sleep 1
ls -1 /opt >/Installed_Programs/binary_packages.txt
ls -1 /usr/local/bin >/Installed_Programs/source_packages.txt
echo "Getting your Repro Key (public key)"
sleep 1
apt-key exportall > /Installed_Programs/Repo.keys
echo "Adding new files to zip"
sleep 1
zip -r -y -u $destination$version /Installed_Programs/
echo "Backup script has finished. Have a nice day."
read -p "Press any key to continue... " -n1 -s

################################################################################################################
################################################################################################################
#echo "backing up the Daten drive to the Backup drive"
#rsync -auv --log-file=/home/user/$(date +%Y%m%d)_rsync.log --progress /media/Daten/ /media/Backup
#echo "Backup script has finished. Have a nice day."
#read -p "Press any key to continue... " -n1 -s


