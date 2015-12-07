:: This script allocates space in RAM and mount as a disk. Then, it
:: moves the folder provided as parameter to this ram disk and replaces
:: it by a junction (symbolic link)
::
:: dependency:
:: * imdisk (http://www.ltr-data.se/opencode.html/#ImDisk)
:: * robocopy
:: Run as administrator
::

::echo off

:: check if user is admin
openfiles > NUL 2>&1
IF NOT %ERRORLEVEL% EQU 0 goto notadmin

IF "%1"=="" GOTO noparam
IF NOT EXIST "%1" GOTO noexist

:: ------------------------------------------------------


IF NOT EXIST %1\nul GOTO nodir
for %%a in (%1) do set currentfolder=%%~nxa
if "%currentfolder%" == "" goto nocurdir

IF EXIST R:\nul GOTO skipmount

:: allocates 500mb and mount as R:
imdisk -a -t vm -s 500m -m r: -p "/fs:ntfs /q /y"
IF NOT EXIST R:\nul GOTO notr

:skipmount
IF EXIST R:\%currentfolder%\nul goto diralready

echo d | xcopy /E /R /Y %1 %1.bkp
IF NOT EXIST %1.bkp\nul GOTO bkpfail

robocopy "%1" "R:\%currentfolder%" /E /IS /MOVE

IF NOT EXIST %1 GOTO makelink

:: original folder still exists, check if it is empty (http://ss64.com/nt/empty.html)
set _TMP=
for /f "delims=" %%a in ('dir /b %1') do set _TMP=%%a

IF {%_TMP%}=={} (
	rd /s /q %1
) ELSE (
	goto originalfoldernotempty
)

:makelink
mklink /J %1 R:\%currentfolder%
fsutil reparsepoint query "%1" >nul
if %errorlevel% == 1 goto nojunction

echo Keeping backup in sync... Let it running, don't close this window
robocopy "R:\%currentfolder%" "%1.bkp" /MIR /Z /W:5 /njh /njs /xj /MOT:1

goto end

:: ------------------------------------------------------

:originalfoldernotempty
echo Thought I just moved original folder to R:, but it is still there and not empty.
pause
goto end

:: ------------------------------------------------------

:nocurdir
echo Can't get the current dir. (wha????)
pause
goto end

:: ------------------------------------------------------

:nojunction
echo Failed to create junction %1 <-> R:\%currentfolder%
pause
goto end

:: ------------------------------------------------------

:diralready
echo R:\%currentfolder% already exists, can't proceed
pause
goto end


:: ------------------------------------------------------

:bkpfail
echo Failed to create %1.bkp
pause
goto end

:: ------------------------------------------------------

:nodir
echo %1 is not a directory
pause
goto end

:: ------------------------------------------------------

:notr
echo Can't create R: as ramdisk
pause
goto end

:: ------------------------------------------------------

:notadmin
echo You must run as administrator
pause
goto end

:: ------------------------------------------------------

:noexist
call echo %1 not found
pause
goto end

:: ------------------------------------------------------

:noparam
echo You must provide a folder
pause
goto end

:: ------------------------------------------------------
:end
