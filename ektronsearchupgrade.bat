@echo off
setlocal EnableDelayedExpansion

:: This script calls the SearchUpgrade.exe tool as explained in
:: https://portal.ektron.com/kb/1032/ (Incorrect Search Results for PageBuilder Pages)
:: 
:: After this, you must run a full crawl in the site

:: Location of SearchUpgrade.exe
SET SEARCHUPGRADE_DIR=C:\Program Files (x86)\Ektron\CMS400v91\Utilities\SearchServer\SearchUpgrade
SET SEARCHUPGRADE_FILE=SearchUpgrade.exe

:: Values from Web.config
SET WEBCONFIG_connectionString=server=*****;database=******;Integrated Security=FALSE;user=*******;pwd=*******;
SET WEBCONFIG_WSPath=http://<siterootdomain>/Workarea/ServerControlWS.asmx
SET WEBCONFIG_ek_sitePath=/

echo.

:: Check variables
IF NOT EXIST "%SEARCHUPGRADE_DIR%" GOTO nodir
IF NOT EXIST "%SEARCHUPGRADE_DIR%\%SEARCHUPGRADE_FILE%" GOTO nofile

:: Check if is admin
openfiles > NUL 2>&1 
IF NOT %ERRORLEVEL% EQU 0 goto notadmin

:: Confirmation
echo This will reset your search and you must run a FULL CRAWL afterwards.
echo Are you sure (Y/[N])?
SET /P AREYOUSURE=
IF /I "%AREYOUSURE%" NEQ "Y" GOTO terminate

:: Do the job
"%SEARCHUPGRADE_DIR%\%SEARCHUPGRADE_FILE%" "%WEBCONFIG_connectionString%" "%WEBCONFIG_WSPath%" "%WEBCONFIG_ek_sitePath%"
echo.

:: Error handling
if ERRORLEVEL 1 goto error

echo Command successful.
echo.
echo GO TO EKTRON WORKAREA, SETTINGS-^>CONFIGURATION-^>SEARCH-^>NODE STATUS
echo AND CLICK THE BUTTON "Request a Full Crawl"
echo.

goto end

-------------------------------------------------------------
:notadmin
echo You must run this command as Administrator.
echo Right click %~n0%~x0 and select "Run as administrator"
echo.
goto end

-------------------------------------------------------------
:nodir
echo The directory "%SEARCHUPGRADE_DIR%" doesn't exist.
echo.
call echo Edit "%~dp0%~n0%~x0" and fix the variable SEARCHUPGRADE_DIR.
echo.
echo Set it to something like
echo SET SEARCHUPGRADE_DIR=C:\Program Files\Ektron\CMS400v...\Utilities\SearchServer\SearchUpgrade
echo (no ending backslash, no quotes)
echo.
goto end

-------------------------------------------------------------
:nofile
echo The file "%SEARCHUPGRADE_FILE%" wasn't found in "%SEARCHUPGRADE_DIR%".
echo.
call echo Edit "%~dp0%~n0%~x0" and fix the variable SEARCHUPGRADE_FILE.
echo.
echo Also check the variable SEARCHUPGRADE_DIR, it must be something like
echo SET SEARCHUPGRADE_DIR=C:\Program Files\Ektron\CMS400v...\Utilities\SearchServer\SearchUpgrade
echo (no ending backslash, no quotes)
echo Now it is set to "%SEARCHUPGRADE_DIR%"
echo.
goto end

-------------------------------------------------------------
:error
echo :( There was an error running the command.
echo.
goto end

-------------------------------------------------------------
:end
echo Press any key to exit/close
pause > NUL 2>&1 
echo.
goto terminate

-------------------------------------------------------------
:terminate
