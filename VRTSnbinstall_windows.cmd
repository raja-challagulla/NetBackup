@echo off
@REM bcpyrght
@REM **************************************************************************
@REM * $Copyright: Copyright (c) Raja Challagulla. All rights reserved $
@REM **************************************************************************
@REM ecpyrght
@REM Version 1.0

@REM NetBackup Client Software Installation on Windows

set binary_dir="C:\Users\Administrator\Downloads\NBU82\x64"
set scripts_dir="D:\Program Files\Veritas\NetBackup\DbExt"
set nbu_bin="D:\Program Files\Veritas\NetBackup\bin"
set nbu_master=rhel-guest
set install_token=BIQBNVABRHXKAJIJ
echo Installing Veritas NetBackup Client software
echo(
cd /D %binary_dir%
call client_silent_install.cmd
if %ERRORLEVEL% NEQ 0 GOTO failed

echo Getting the security certificates
echo(
cd /D %nbu_bin%
echo yes|.\nbcertcmd -getCAcertificate > NUL 2>&1
.\nbcertcmd -getcertificate -token %install_token% > NUL 2>&1

echo Copying the MS-SQL Backup scripts
echo(
echo SQLINSTANCE $ALL >%scripts_dir%\MsSql\mssql_db_backup.bch
echo OPERATION BACKUP >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo DATABASE $ALL >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo SQLHOST "%COMPUTERNAME%" >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo NBSERVER "%nbu_master%" >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo MAXTRANSFERSIZE 6 >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo BLOCKSIZE 7 >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo PREFERREDREPLICA TRUE >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo NUMBUFS 2 >>%scripts_dir%\MsSql\mssql_db_backup.bch
echo ENDOPER TRUE >>%scripts_dir%\MsSql\mssql_db_backup.bch


echo SQLINSTANCE $ALL >%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo OPERATION BACKUP >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo DATABASE $ALL >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo SQLHOST "%COMPUTERNAME%" >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo NBSERVER "%nbu_master%" >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo MAXTRANSFERSIZE 6 >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo BLOCKSIZE 7 >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo PREFERREDREPLICA TRUE >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo NUMBUFS 2 >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo OBJECTTYPE TRXLOG >>%scripts_dir%\MsSql\mssql_tlog_backup.bch
echo ENDOPER TRUE >>%scripts_dir%\MsSql\mssql_tlog_backup.bch

echo MS-SQL DB Plugin is included by default.
echo(
echo Installing the Additional Database plugins
echo(
echo Is this host running with any of the Databases i.e. MariaDB, MySQL, PostgresSQL?
echo(
set /p resp="Enter Yes/No: "

if %resp%==yes GOTO plugin
if %resp%==Yes GOTO plugin
if %resp%==YES GOTO plugin
if %resp%==y GOTO plugin
if %resp%==Y GOTO plugin

if %resp%==no GOTO ending
if %resp%==NO GOTO ending
if %resp%==No GOTO ending
if %resp%==n GOTO ending
if %resp%==N GOTO ending
echo Invalid option. Skipping the database plugin installation
echo(
GOTO postchecks

:plugin
echo(
echo Please Provide the Database Type that is running on this host from the below list:
echo(
echo 1. MariaDB
echo 2. MySQL
echo 3. PostgresSQL
echo(
set /p presponse="Please provide A Numerical response : "
if %presponse%==1 goto mariadb
if %presponse%==2 goto mysql
if %presponse%==3 goto pgsql
echo Invalid option. Skipping the database plugin installation
echo(
GOTO postchecks
:end

:pgsql
echo Installing the Postgres SQL plugin
cd /D %binary_dir%\NBPostgreSQLAgent_8.2_AMD64\
Setup.exe -s
xcopy %binary_dir%\pgsql_db_backup.txt %scripts_dir%\pgsql_db_backup.bat* /Y /F
echo PostgresSQL DB plugin installation is Done
echo(
GOTO postchecks
:end

:mysql
echo Installing MySQL Plugin
cd /D %binary_dir%\NBMySQLAgent_8.2_AMD64\
Setup.exe -s
xcopy %binary_dir%\mysql_db_backup.txt %scripts_dir%\mysql_db_backup.bat* /Y /F
echo MySQL DB plugin installation is Done
echo(
GOTO postchecks
:end

:mariadb
echo Installing MariaDB Plugin
cd /D %binary_dir%\NBMariaDBAgent_8.2_AMD64\
Setup.exe -s
xcopy %binary_dir%\mariadb_db_backup.txt %scripts_dir%\mariadb_db_backup.bat* /Y /F
echo Maria DB plugin installation is Done
echo(
GOTO postchecks
:end

:ending
echo No plugins are installed
GOTO postchecks
:end

:postchecks
echo(
echo Run the below command to validate the connectivity to master server. If there is no response for this command, please contact IBS Team.
echo(
echo cd "D:\Program Files\Veritas\NetBackup\bin\"
echo .\bpclntcmd.exe -pn
echo(
echo NBU Client Install Script is completed!
exit /b
:end

:failed
echo Client Installation failed. Check connectivity to NetBackup Master server %nbu_master%.
echo Exiting the Script.
exit /b
:end

:EOF
