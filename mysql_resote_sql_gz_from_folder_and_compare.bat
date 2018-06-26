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
REM DIR %folder%
REM DIR %folder% /S /B /A:-D *.sql.gz 2>NUL
DIR %folder% /S /B /O-S | findstr /E .sql.gz 2>NUL > backups.list
REM GOTO :end

SET db_prefix=%~2
REM ECHO DB Prefix : %2
IF "%db_prefix%"=="" (
	SET /P db_prefix=Please Enter DB Prefix : 
)
ECHO DB Prefix : %db_prefix%

SET /A index=0
DEL map.txt 2>NUL
DEL backup_files.list 2>NUL
set find=^"

set replace=

for /F "tokens=*" %%A in (backups.list) do CALL :do_line "%%A"
GOTO end

:do_line
SET line=%1
REM ECHO Line %index% is %line%
ECHO create database `%db_prefix%%index%` ^| mysql -uroot
REM ECHO create database `%db_prefix%%index%` | mysql -uroot
ECHO gunzip ^< %line% ^| mysql -uroot %db_prefix%%index%
REM gunzip < %line% | mysql -uroot %db_prefix%%index%

call set line=%%line:!find!=!replace!%%
FOR %%i IN ("%line%") DO (
	ECHO %%~ni >> backup_files.list
)

ECHO %line% - %db_prefix%%index% >> map.txt
ECHO %line% to %db_prefix%%index%

IF NOT %index% EQU 0 (
REM 	REM SET target_file=%line%_to_%previous_db%.mdc
REM 	ECHO Target File : %target_file%
REM 	PAUSE
REM 	REM COPY test.template %target_file%
	REM SET previous_db =""
)

SET /A index+=1

:end