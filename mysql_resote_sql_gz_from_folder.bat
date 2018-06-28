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
ECHO create database `%db_prefix%%index%` | mysql -uroot 1>NUL
REM ECHO gunzip ^< %line% ^| mysql -uroot %db_prefix%%index%
gunzip < %line% | mysql -uroot %db_prefix%%index% 1>NUL

call set line=%%line:!find!=!replace!%%
FOR %%i IN ("%line%") DO (
	SET backup_file_name=%%~ni.gz
	ECHO !backup_file_name!>> backup_files.list
)

ECHO %line% - %db_prefix%%index%>> map.txt
ECHO %line% to %db_prefix%%index%

IF NOT %index% EQU 0 (

	REM ECHO Project File : !backup_file_name!_to_!previous_db!.mdc
	REM DEL ^"!backup_file_name!_to_!previous_db!.mdc^" 2>NUL
	REM COPY redgate_mdc_project.template /Y ^"!backup_file_name!_to_!previous_db!.mdc^" 1>NUL

	REM SET InputFile=!backup_file_name!_to_!previous_db!.mdc
	REM SET OutputFile=!backup_file_name!_to_!previous_db!.mdc_new
	REM REM ECHO Input File : !InputFile!
	REM REM ECHO Output File : !OutputFile!

	REM SET "_strFind=    <name>project_name</name>"
	REM SET "_strInsert=    <name>!backup_file_name!_to_!previous_db!</name>"

	REM > "!OutputFile!" (
	REM 	for /f "usebackq delims=" %%A in ("!InputFile!") DO (
	REM 		if "%%A" EQU "!_strFind!" ( ECHO !_strInsert! ) else ( ECHO %%A )
	REM 	)
	REM )

	REM DEL ^"!backup_file_name!_to_!previous_db!.mdc^"
	REM RENAME ^"!backup_file_name!_to_!previous_db!.mdc_new^" ^"!backup_file_name!_to_!previous_db!.mdc^"

	FOR /F "tokens=*" %%A in (databases.list) do CALL "C:\Program Files\Devart\dbForge Data Compare for MySQL\datacompare.com" /datacompare /source connection:"User Id=root;Password=;Host=localhost;Database=%db_prefix%%index%;Enlist=False;Transaction Scope Local=True;Character Set=utf8" /target connection:"User Id=root;Password=;Host=localhost;Database=%%A;Enlist=False;Transaction Scope Local=True;Character Set=utf8" /IgnoreComputedColumns:No /CompareViews:Yes /report:"%db_prefix%%index%_to_%%A.html" /reportformat:html /log:"%db_prefix%%index%_to_%%A.log"

)

ECHO %db_prefix%%index%>> databases.list
SET previous_db=!backup_file_name!
SET /A index+=1
REM PAUSE

:end