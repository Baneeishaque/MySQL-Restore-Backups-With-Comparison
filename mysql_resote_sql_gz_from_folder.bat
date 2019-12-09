@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

SET mode=own
SET folder=%~1
IF "%folder%"=="" (
	SET /P folder=Please Provide .sql.gz Folder : 
) ELSE SET mode=CMD
ECHO Mode is %mode%

SET folder=%folder:"=%
ECHO Folder is %folder%
DIR %folder% /S /B /O-S | findstr /E .sql.gz 2>NUL > backups.list

SET db_prefix=%~2
IF "%db_prefix%"=="" (
	SET /P db_prefix=Please Enter DB Prefix : 
)
ECHO DB Prefix : %db_prefix%

SET /A index=0
DEL map.txt 2>NUL
DEL backup_files.list 2>NUL
DEL databases.list 2>NUL
set find=^"

set replace=

for /F "tokens=*" %%A in (backups.list) do CALL :do_line "%%A"
GOTO end

:do_line
SET line=%1
REM ECHO Line %index% is %line%
REM ECHO create database `%db_prefix%%index%` ^| mysql -uroot
ECHO create database `%db_prefix%%index%` | mysql -uroot -p1234 1>NUL
REM ECHO gunzip ^< %line% ^| mysql -uroot %db_prefix%%index%
gunzip < %line% | mysql -uroot -p1234 %db_prefix%%index% 1>NUL

call set line=%%line:!find!=!replace!%%
FOR %%i IN ("%line%") DO (
	SET backup_file_name=%%~ni.gz
	ECHO !backup_file_name!>> backup_files.list
)

ECHO %line% - %db_prefix%%index%>> map.txt
ECHO %line% to %db_prefix%%index%
ECHO %db_prefix%%index%>> databases.list
SET /A index+=1
REM PAUSE

:end