@setlocal enableextensions enabledelayedexpansion
@set LC_ALL='C'
@set DEBUG=&rem
@set RAWDEBUG=&rem
@set PARAMS="%*"
@if not x%PARAMS:/rawdebug=%==x%PARAMS% (@set DEBUG=1&@set RAWDEBUG=1&@prompt $s&@echo on) else (@echo off)
@if not x%PARAMS:/debug=%==x%PARAMS% set DEBUG=1

:: Startup
call:init

if "%ABORT%" == "1" (
	set ABORT=&rem
	goto end
)

:: Read providedoptions and setup local variables
call:processArguments %*

:: If does not find the configuration file, abort the execution.
@if "%VERBOSE%"=="1" echo Reading configuration file %CONFIG%
if not exist %CONFIG% (
	echo.
	echo Ops... Configuration file not found^^! :'(
	echo.
	echo You must create the file %CONFIG%, containing a list of paths for your projects' roots
	echo You can use # to create comment lines and keep life organized.
	echo.
	echo hgchg /help for additional help.
	echo.
	goto end
)

:: Process all the projects listed in the configuration file. The results will be
:: written to the file %TEMPFILE%
set TEMPFILE=%TEMP%\%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%%RANDOM%%RANDOM%%RANDOM%.txt
@if "%VERBOSE%"=="1" echo Processing projects...
@if "%VERBOSE%"=="1" echo Temporary file = %TEMPFILE%
call:processProjects

IF NOT "%ATLEASTONE%"=="1" (
	echo No project processed. Check the configuration file %CONFIG%
	goto end
)

:: Now that the results are stored in %TEMPFILE%, will build a command to output the results.
:: This is just a secondary parsing of the output (using piped commands like grep, clip, sed, etc).
:: The output format is mainly given by the template used.
::
:: Note about using pipes in commands:
:: The pipes escaping is not passed by through multiple variable attributions. Due to that,
:: escaped batch-pipes (^|) must be written as (;;;) and escaped regex-pipes as (,,,), to be
:: replaced by proper pipes after the command is totally written.
::
SET COMMAND=type %TEMPFILE%
if not "%GREPIN%" == ""  SET COMMAND=%COMMAND% ;;; grep -i "%GREPIN%"
if not "%GREPOUT%" == "" SET COMMAND=%COMMAND% ;;; grep -i -v "%GREPOUT%"
if "%MODE_MIN%"=="1" SET COMMAND=%COMMAND% ;;; cut -f "1,4" ;;; sed "s/	/\//g" ;;; sort ;;; uniq

:: Write the escaped pipes:
:: ;;; = ^|
:: ,,, = \|
SET COMMAND=%COMMAND:;;;=^^^|%
SET COMMAND=%COMMAND:,,,=\|%

:: Run the command, sending the results to the right place

:: Clipboard
if "%CLIP%"=="1" (
	@if "%VERBOSE%"=="1" echo Sending contents to clipboard
	%COMMAND% | clip
	goto :cmdProcessed
)

:: Output file
if not "%OUTPUT%"=="x" (
	@if "%VERBOSE%"=="1" echo Writing results to %OUTPUT%
	%COMMAND% > %OUTPUT%
	goto :cmdProcessed
)

:: Just run the command, sending the results to the main output
%COMMAND%


:cmdProcessed

:: release resources
@if "%VERBOSE%"=="1" echo Deleting %TEMPFILE%
del %TEMPFILE%
set TEMPFILE=&rem
goto end


:: ------------------------------------------------------------------------------
:: FUNCTION init
::
:: 		Script startup
::
:init

	@set VERBOSE=&rem

	if not x%PARAMS:/help=%==x%PARAMS% goto helpme
	if not x%PARAMS:/?=%==x%PARAMS% goto helpme
	if not x%PARAMS:/check=%==x%PARAMS% goto checkDependencies	

	call:resetVars

	@if "%DEBUG%"=="1" echo [DEBUG] function call init
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set TODAY=%date:~6,4%-%date:~3,2%-%date:~0,2%
	set STARTDATE=%TODAY%
	set FINALDATE=%TODAY%
	set DATEPARAM=--date "%STARTDATE% to %FINALDATE%"

	SET MYPATH=%~dp0
	SET CONFIG=%MYPATH%hgchg.cfg

	SET OUTPUT=x

	:: Interrupt options
	:: If any interrupt option is used, other options are ignored.
	:: help, ?, check
	
	@if "%RAWDEBUG%"=="1" prompt $s

goto:eof




:: ------------------------------------------------------------------------------
:: FUNCTION processProjects
::
::		Read the configuration file and calls the processPath function for
::		each path
::
:processProjects
	@if "%DEBUG%"=="1" echo [DEBUG] function call processProjects
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s
	for /f "eol=# tokens=*" %%a in (%CONFIG%) do (
		if not exist %%a (
			echo Folder not found: %%a
		) else (
			call:processPath %%a
			SET ATLEASTONE=1
		)
	)
	@if "%RAWDEBUG%"=="1" prompt $s
goto:eof




:: ------------------------------------------------------------------------------
:: FUNCTION processPath
::
::		Calls the correct template function, and runs the hg log command
::
:processPath
	@if "%DEBUG%"=="1" echo [DEBUG] function call processPath
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	:: gets the target directory and the last folder name (to use as project name)
	set TARGETDIR=%~1
	set TARGETDIR1=%TARGETDIR:~0,-1%
	for %%f in (%TARGETDIR1%) do set FOLDERNAME=%%~nxf

	:: Decide the template to use
	if "%MODE_MIN%"=="1" (
		:: use the tab mode for /min. After this, will cut, sort and uniq.
		call:prepareTemplateTab
	) else if "%MODE_TAB%"=="1" (
		call:prepareTemplateTab
	) else (
		call:prepareTemplateNormal
	)

	:: runs the hg log command.
	@if "%VERBOSE%"=="1" echo Getting data for %TARGETDIR%	
	hg log -v %USER% %DATEPARAM% --template "%TEMPLATE%" %TARGETDIR% | sed "s/ +0000//g" | sort | uniq >> %TEMPFILE%

	@if "%RAWDEBUG%"=="1" prompt $s
goto:eof




:: ------------------------------------------------------------------------------
:: FUNCTION prepareTemplateNormal
::
:: 		Template to be used on screen. Use mainly tabs, but fill the projectname
::		with spaces to make all look aligned.
::
:prepareTemplateNormal

	@if "%DEBUG%"=="1" echo [DEBUG] function call prepareTemplateNormal
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set PROJECTNAME=%FOLDERNAME%                &rem
	set PROJECTNAME=%PROJECTNAME:~0,14%

	set BASETEMPLATE=%PROJECTNAME%
	if "%REV%" == "1" set BASETEMPLATE=%BASETEMPLATE%	r{rev}
	if "%WITHTIME%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{isodatesec(date)}
	if NOT "%WITHTIME%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{shortdate(date)}
	if "%AGE%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{age(date)}
	set BASETEMPLATE=%BASETEMPLATE%	{user(author)}
	set BASETEMPLATE=%BASETEMPLATE%	{file}
	if "%COMMENTS%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{firstline(desc)}

	set TEMPLATE={files %% '%BASETEMPLATE%\n'}

	@if "%RAWDEBUG%"=="1" prompt $s	
goto:eof




:: ------------------------------------------------------------------------------
:: FUNCTION prepareTemplateTab
::
:: 		Template best to parse data. Similar to normal, but doesn't complete spaces
::
:prepareTemplateTab
	@if "%DEBUG%"=="1" echo [DEBUG] function call prepareTemplateNormal
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set PROJECTNAME=%FOLDERNAME%&rem

	set BASETEMPLATE=%PROJECTNAME%
	if "%REV%" == "1" set BASETEMPLATE=%BASETEMPLATE%	r{rev}
	if "%WITHTIME%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{isodatesec(date)}
	if NOT "%WITHTIME%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{shortdate(date)}
	if "%AGE%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{age(date)}
	set BASETEMPLATE=%BASETEMPLATE%	{user(author)}
	set BASETEMPLATE=%BASETEMPLATE%	{file}
	if "%COMMENTS%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{firstline(desc)}

	set TEMPLATE={files %% '%BASETEMPLATE%\n'}

	@if "%RAWDEBUG%"=="1" prompt $s	
goto:eof




:: ------------------------------------------------------------------------------
:: FUNCTION processArguments
::
:: Set different variables according to the parameters
::
:processArguments

	@if "%DEBUG%"=="1" echo [DEBUG] function call processArguments
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	:: reached the end of the parameters
	if "%1"=="" (
		@if "%RAWDEBUG%"=="1" prompt $s
		goto:eof
	)
	
	:: gets the first string as OPTION, jump to the following, and gets it as VALUE.
	set OPTION=%1
	shift
	set VALUE=%1

	:: if the option doesn't start with /, it means I'm reading a value. So, skip.
	if not "%OPTION:~0,1%"=="/" goto:processArguments

	:: if the value starts with /, it means I'm reading the next option as it was a VALUE.
	:: So, reset it.
	if "%VALUE:~0,1%"=="/" set VALUE=&rem

	@if "%DEBUG%"=="1" echo [DEBUG] Detected option %OPTION% %VALUE%

	:: do tasks according to the option and it's value
	if "%OPTION%"=="/u" set USER=%USER% -u %VALUE%
	if "%OPTION%"=="/me" set USER=%USER% -u %USERNAME%
	if "%OPTION%"=="/1" set USER=%USER% -u %USERNAME%
	if "%OPTION%"=="/sd" set STARTDATE=%VALUE%
	if "%OPTION%"=="/fd" set FINALDATE=%VALUE%
	if "%OPTION%"=="/rd" set RELDATE=%VALUE%
	if "%OPTION%"=="/date" set SINGLEDATE=%VALUE%	
	if "%OPTION%"=="/min" set MODE_MIN=1
	if "%OPTION%"=="/m" set MODE_MIN=1
	if "%OPTION%"=="/clip" set CLIP=1
	if "%OPTION%"=="/r" set REV=1
	if "%OPTION%"=="/rev" set REV=1
	if "%OPTION%"=="/a" set AGE=1
	if "%OPTION%"=="/age" set AGE=1
	if "%OPTION%"=="/c" set COMMENTS=1
	if "%OPTION%"=="/time" set WITHTIME=1
	if "%OPTION%"=="/rd" set RELDATE=%VALUE%
	if "%OPTION%"=="/v" set VERBOSE=1
	if "%OPTION%"=="/verbose" set VERBOSE=1
	if "%OPTION%"=="/t" set MODE_TAB=1
	if "%OPTION%"=="/tab" set MODE_TAB=1
	if "%OPTION%"=="/o" set OUTPUT="%VALUE:/=\%"
	if "%OPTION%"=="/out" set OUTPUT="%VALUE:/=\%"
	if "%OPTION%"=="/w" (
		if not "%GREPIN%" == "" set GREPIN=%GREPIN%\,,,%VALUE%
		if "%GREPIN%" == "" set GREPIN=%VALUE%
	)
	if "%OPTION%"=="/wo" (
		if not "%GREPOUT%" == "" set GREPOUT=%GREPOUT%\,,,%VALUE%
		if "%GREPOUT%" == "" set GREPOUT=%VALUE%
	)
	
	:: set the date parameter according to the options
	set DATEPARAM=--date "%STARTDATE% to %FINALDATE%"
	if NOT "%RELDATE%" == "" (
		set DATEPARAM=--date %RELDATE%
	)
	if NOT "%SINGLEDATE%" == "" (
		set DATEPARAM=--date "%SINGLEDATE% to %SINGLEDATE%"
	)

	goto processArguments

goto:eof




:: ------------------------------------------------------------------------------
:helpme
	@if "%DEBUG%"=="1" echo [DEBUG] function call helpme
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	echo.
	echo hgchg.bat: List changes in all Tortoise HG projects
	echo author: paulo amaral
	echo version date: 2014-12-17
	echo.
	echo Syntax: hgchg  [/me]  [/u ^<username^> ...]  [ [/sd ^<start date^>] [/fd ^<final date^>] ^| [/rd ^<-X days^>] ]  [/w ^<word^> ...]  [/wo ^<word^> ...]  [/rev]  [/age]  [/c]  [/min]  [/tab]  [/clip]  [/o ^<outputfile^>]  [/help]
	echo.
	echo   ## USERS ##
	echo   -----------
	echo.
	echo     /u username : Show changes only for specific users. /u can be used many
	echo                   times. ex: hgchg /u user1 /u user2 /u user3
	echo     /me or /1 : Show changes for the current logged user.
	echo.
	echo   ## FILTERS ##
	echo   ----------
	echo.
	echo     /sd ^<start date^>     Start date in the format YYYY-MM-DD. Current date is the default.
	echo     /fd ^<final date^>     Final date in the format YYYY-MM-DD. Current date is the default.
	echo     /rd ^<-X^>             Gets data from X days ago until today. Overrides /sd and /fd
	echo     /date ^<YYYY-MM-DD^>   Gets data from a specific date. Overrides /sd, /fd and /rd.
	echo.
	echo     /w ^<word^>     Only results WITH the word. /w can be used many times.
	echo     /wo ^<word^>    Only results WITHOUT the word. /wo can be used many times.
	echo.
	echo   ## LIST STYLE ##
	echo   ----------------
	echo.
	echo     /rev or /r       Show revision number
	echo     /age or /a       Show age, e.g. "10 hours ago", "2 weeks ago"
	echo     /c               Show commit comments (first line only)
	echo     /time            Show the time with the date
	echo     /tab or /t       Tab mode - split columns using tabs, useful with /clip to use on excel
	echo     /min or /m       Minimal mode (list unique files, sorted). Overrides /r and /a.
	echo     /clip            Output the results to the clipboard instead of displaying them
	echo     /o ^<outputfile^>  Output the results to the specified file. USE DOUBLE QUOTES or
	echo                      ESCAPE BACKSLASH (use c:\\file.txt instead of c:\file.txt)
	echo.
	echo   ## OTHERS ##
	echo   ------------
	echo.
	echo     /help or /?  Display this help (using "/?" doesn't work)
	echo     /v           Verbose
	echo     /debug       Show debug messages.
	echo     /rawdebug    Show debug messages and echoes every line executed in the script (ECHO ON)
	echo     /check       Check dependencies and show instructions about how to properly install them.
	echo.
	echo   ## HOW DEFINE THE PROJECTS LIST ##
	echo   ----------------------------------
	echo.
	echo     Create a file HGCHG.CFG in the same place where the HGCHG.BAT is located,
	echo     containing a list of the projects' root folders
	echo.


	@if "%RAWDEBUG%"=="1" prompt $s

	set ABORT=1

goto:eof




:: ------------------------------------------------------------------------------
:checkDependencies
	echo.
	echo Checking dependency: SED.EXE
	WHERE SED.exe
	IF %ERRORLEVEL% NEQ 0 SET MISSINGDEP=1
	echo.
	echo Checking dependency: SORT.EXE
	WHERE SORT.exe
	IF %ERRORLEVEL% NEQ 0 SET MISSINGDEP=1	
	echo.
	echo Checking dependency: UNIQ.EXE
	WHERE UNIQ.exe
	IF %ERRORLEVEL% NEQ 0 SET MISSINGDEP=1	
	echo.
	echo Checking dependency: CUT.EXE
	WHERE CUT.exe
	IF %ERRORLEVEL% NEQ 0 SET MISSINGDEP=1	
	echo.
	IF "%MISSINGDEP%" == "1" (
		echo WARNING: One or more dependencies missing. hgchg may not work properly.
		echo To fix:
		echo   * Download: http://sourceforge.net/projects/unxutils/	
		echo   * Unzip anywhere
		echo   * Add the folder ^<unxutils\usr\local\wbin^> to the PATH environment variable
		echo.
		echo   Alternatively, you can just download the files from the wbin folder and
		echo   copy them to your windows/system32 folder
		echo.
	)
	set MISSINGDEP=&rem

	set ABORT=1

goto:eof




:: ------------------------------------------------------------------------------
:: FUNCTION resetVars
:resetVars
	@if "%DEBUG%"=="1" echo [DEBUG] function call resetVars
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set COMMAND=&rem
	set BASETEMPLATE=&rem
	set USER=&rem
	set HELP=&rem
	set MODE_MIN=&rem
	set PROJECTNAME=&rem
	set TEMPLATE=&rem
	set TARGETDIR=&rem
	set TARGETDIR1=&rem
	set MIN_WARNING=&rem
	set CLIP=&rem
	set REV=&rem
	set AGE=&rem
	set COMMENTS=&rem
	set RELDATE=&rem
	set DATEPARAM=&rem
	set FINALDATE=&rem
	set STARTDATE=&rem
	set FOLDERNAME=&rem
	set REV=&rem
	set TODAY=&rem
	set OPTION=&rem
	set VALUE=&rem
	set MODE_TAB=&rem
	set OUTPUT=&rem
	set GREPIN=&rem
	set GREPOUT=&rem
	set MYPATH=&rem
	set CONFIG=&rem
	set PARAMS=&rem
	set WITHTIME=&rem
	set SINGLEDATE=&rem
	set ATLEASTONE=&rem

	@if "%RAWDEBUG%"=="1" prompt $s
goto:eof




:: ------------------------------------------------------------------------------

:end
@if "%DEBUG%"=="1" echo [DEBUG] function call end
call:resetVars
@if "%1"=="/rawdebug" (
	@prompt $p$g
)
@set DEBUG=&rem
@set RAWDEBUG=&rem
@set VERBOSE=&rem
@set TEMPFILE=&rem

