#!/bin/bash
# **************************************************************************
# * $Copyright: Copyright (c) Raja Challagulla. All rights reserved $
# **************************************************************************
# Version 1.0

# NetBackup Client Installation Script on Linux

#set the log file
install_token="BIQBNVABRHXKAJIJ"
bpconf_file_master="$PWD/bpconf.txt"
bpconf_file="/usr/openv/netbackup/bp.conf"
nbu_binary="/usr/openv/netbackup/bin"
scripts_dir="/usr/openv/netbackup/ext/db_ext"
nbu_master="<master Server>"

# Providing exec permission to /tmp folder temporarily for the client installation
tmp_permission () {
  ret_value=$(mount -o remount,exec /tmp)
    if [ $? -eq 0 ]
  then
    echo "exec permission set for /tmp successfully"
  else
    echo "ERROR: unable to set exec permission for /tmp File System. Aborting the install" 1>&2
    exit 1
  fi
}

#start the NBU Cliet binary Installation
run_client_install () {
if [ -f "$PWD"/install ]
then
if ! $( (echo y; echo y; echo rhel-guest; echo y; echo q; echo y) | "$PWD"/install ) 2>/dev/null
then
  echo "Client installation is Done"
else
  echo "Client Installation is failed"
  exit 1
fi
else
  echo "ERROR: Client install script is not found in the current directory. Make sure to be in the NBU Client binaries folder" 1>&2
  exit 1
fi
}

# Get NetBackup certificate
get_certificate () {
echo "Getting the CA Certificare"
get_CA_cert=$(echo y | "$nbu_binary"/nbcertcmd -getCAcertificate) 2>&1
if [ $? -ne 0 ]
then
echo "Error in getting the CA certificates. Check communication to Master server $nbu_master".
exit 1
fi
echo "getting the client certificate"
get_cert=$( "$nbu_binary"/nbcertcmd -getcertificate -token $install_token) 2>&1
if [ $? -ne 0 ]
then
echo "Error in getting the client certificates. Check communication to Master server $nbu_master".
exit 1
fi
}

# Update bp.conf file with Master/Media servers
update_bpconf () {
echo "Modifying the bp.conf file"
backup_bpconf=$(cp $bpconf_file /usr/openv/netbackup/backup_bp.conf)
backup_bpconf_file="/usr/openv/netbackup/backup_bp.conf"
create_bpconf_file=$(echo y | cp -f $bpconf_file_master $bpconf_file)
origi_client_name=$( grep CLIENT_NAME $backup_bpconf_file | awk '{print $3}')
update_bpconf_file=$(sed -i "s/client_name/$origi_client_name/g" $bpconf_file )
}

#installing the plugins
install_plugin () {
echo "Starting the NetBackup Database plugin installation"
echo "Is this host running with any of the Databases i.e MariaDB, MySQL, PostgresSQL? Please type Yes/No:"
read -r response_1
if [ "$response_1" == "Yes" ] || [ "$response_1" == "y" ] || [ "$response_1" == "YES" ] || [ "$response_1" == "Y" ] || [ "$response_1" == "yes" ]
 then
 printf "Please provide the Database Type that is running on this host:\n"
 printf "1.MariaDB\n"
 printf "2.MySQL\n"
 printf "3.PostgresSQL\n"
 echo "Please provide the numerical response: "
 read -r response_2
 if [ "$response_2" -eq 1 ]
 then
   echo "Installing MariaDB Plugin"
   install_mariadb=$( echo y | rpm -ivh VRTSnbmariadbagent.rpm )
   copy_script=$(cp -f $PWD/mariadb_db_backup.txt "$scripts_dir"/mariadb_backup)
   set_permission=$( chmod +x "$scripts_dir"/mariadb_backup )
    elif [ "$response_2" -eq 2 ]
 then
   echo "Installing MySQL Plugin"
   install_mysql=$(echo y | rpm -ivh VRTSnbmysqlagent.rpm )
   copy_script=$(cp -f $PWD/mysql_db_backup.txt "$scripts_dir"/mysql_backup)
   set_permission=$( chmod +x "$scripts_dir"/mysql_backup )
    elif [ "$response_2" -eq 3 ]
 then
   echo "Installing PostgresSQL Plugin"
   install_pgsql=$(echo y | rpm -ivh VRTSnbpostgresqlagent.rpm )
   copy_script=$(cp -f $PWD/pgsql_db_backup.txt "$scripts_dir"/pgsql_backup)
   set_permission=$( chmod +x "$scripts_dir"/pgsql_backup )
    else
 echo "Invalid Option Choosen. Skipping the Database plugin installation."
 fi
else
echo "Skipping the Database plugin Installation"
fi
}

tmp_revert () {
  mod_tmp_perm=$(mount -o remount,noexec /tmp)
  ret_value=$mod_tmp_perm
  if [ $? -eq 0 ]
  then
    echo "exec permission reverted for /tmp successfully"
  else
    echo "ERROR: unable to revert /exec permission for /tmp." 1>&2
   fi
}

echo "Executing the NBU Client install script"
echo "Setting the exec permission on /tmp temporarily"
tmp_permission
echo "Executing the binaries installation"
run_client_install
echo "Getting the certificates"
get_certificate
echo "Updating the bp.conf file"
update_bpconf
echo "Installing the Database plugins"
install_plugin
echo "Reverting the exec permission on /tmp"
tmp_revert
echo ""
echo "********* Post Check***********"
echo " Run '/usr/openv/netbackup/bin/bpclntcmd -pn' command."
echo " If the above command does not return any output, contact IBS Team"
echo "The Installation is successful!"