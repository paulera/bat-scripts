::
::   TODO:
::   /only - grep -i    - filter
::   /hide - grep -i -v
::   always create a temp file. it will reduce the script and improve speed.
::           

@setlocal enableextensions enabledelayedexpansion
@set TEMPFILE="deleteme.txt"&rem
@set DEBUG=&rem
@set RAWDEBUG=&rem
@set VERBOSE=&rem

@set PARAMS="%*"
@if not x%PARAMS:/rawdebug=%==x%PARAMS% (@set DEBUG=1&@set RAWDEBUG=1&@prompt $s&@echo on) else (@echo off)
if not x%PARAMS:/debug=%==x%PARAMS% set DEBUG=1
if not x%PARAMS:/help=%==x%PARAMS% goto helpme
if not x%PARAMS:/?=%==x%PARAMS% goto helpme
set PARAMS=&rem


set TEMPFILE=%TEMP%\%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%%RANDOM%%RANDOM%%RANDOM%.txt

call:resetVars
call:init
call:processArguments %*

SET OUTPUT=x

if "%CLIP%"=="1" (

	@if "%VERBOSE%"=="1" echo Processing projects...
	call:processProjects

	@if "%VERBOSE%"=="1" echo Temporary file %TEMPFILE% created
	
	@if "%VERBOSE%"=="1" echo Sending contents to clipboard
	type %TEMPFILE% | clip

	if NOT "%OUTPUT%"=="x" (
		@if "%VERBOSE%"=="1" echo Sending contents to the file %OUTPUT%
		type %TEMPFILE% > %OUTPUT%
	)

	@if "%VERBOSE%"=="1" echo Removing %TEMPFILE%
	del %TEMPFILE%

	set TEMPFILE=&rem
)

if NOT "%CLIP%"=="1" (
 	if not "%OUTPUT%"=="x" (
		@if "%VERBOSE%"=="1" echo Processing projects and sending contents to the file %OUTPUT%
		call:processProjects > %OUTPUT%
	) else (
		@if "%VERBOSE%"=="1" echo Processing projects...
		call:processProjects
	)
)



goto end

:: ------------------------------------------------------------------------------
:: THIS IS THE processProjects FUNCTION
:: List here the projects to process. Remember to end calls with backslash, and use quotes.
:: example:
::  call:processPath "c:\full path\to\the project\root\"
::                   ^                                ^^
:processProjects
	@if "%DEBUG%"=="1" echo [DEBUG] function call processProjects
	call:processPath "C:\projects\app\trunk\components\"
	call:processPath "C:\projects\data\trunk\datafeed"
goto:eof
:: ------------------------------------------------------------------------------
:processPath
	@if "%DEBUG%"=="1" echo [DEBUG] function call processPath
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set TARGETDIR=%~1
	set TARGETDIR1=%TARGETDIR:~0,-1%
	for %%f in (%TARGETDIR1%) do set FOLDERNAME=%%~nxf
	
	cd %TARGETDIR%

	@if "%VERBOSE%"=="1" echo Getting data for %TARGETDIR%	

	if "%MODE_MIN%"=="1" (
		call:minMode
	) else if "%MODE_TAB%"=="1" (
		call:tabMode
	) else (
		call:normalMode
	)

	@if "%RAWDEBUG%"=="1" prompt $s
goto:eof
:: ------------------------------------------------------------------------------
:minMode
	@if "%DEBUG%"=="1" echo [DEBUG] function call minMode
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set PROJECTNAME=%FOLDERNAME%
	set BASETEMPLATE=%PROJECTNAME%/{file}
	set TEMPLATE={files %% '%BASETEMPLATE%\n'}

	if "%USER%"=="" if not "%MIN_WARNING%"=="1" (
		SET MIN_WARNING=1
		echo.
		echo   +---------------------------------------------------------------+
		echo   ^| Be careful, you are using the /min option without /u or /me . ^|
		echo   ^| It means that the files below might be commited by any user   ^|
		echo   ^| Use hgchg /help for more info                                 ^|
		echo   +---------------------------------------------------------------+
		echo.
	)

	if "%CLIP%"=="1" (
		echo.|clip
		hg log -v %USER% %DATEPARAM% --template "%TEMPLATE%" | sort | uniq >> %TEMPFILE%
	) else (
		hg log -v %USER% %DATEPARAM% --template "%TEMPLATE%" | sort | uniq
	)
	
	@if "%RAWDEBUG%"=="1" prompt $s
goto:eof
:: ------------------------------------------------------------------------------
:normalMode
	@if "%DEBUG%"=="1" echo [DEBUG] function call normalMode
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set PROJECTNAME=%FOLDERNAME%                &rem
	set PROJECTNAME=%PROJECTNAME:~0,14%

	set BASETEMPLATE=%PROJECTNAME%
	if "%REV%" == "1" set BASETEMPLATE=%BASETEMPLATE%	r{rev}
	set BASETEMPLATE=%BASETEMPLATE%	{isodatesec(date)}
	if "%AGE%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{age(date)}
	set BASETEMPLATE=%BASETEMPLATE%	{user(author)}
	set BASETEMPLATE=%BASETEMPLATE%	{file}
	if "%COMMENTS%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{firstline(desc)}

	set TEMPLATE={files %% '%BASETEMPLATE%\n'}

	if "%CLIP%"=="1" (
		echo.|clip
		hg log -v %USER% %DATEPARAM% --template "%TEMPLATE%" >> %TEMPFILE%
	) else (
		hg log -v %USER% %DATEPARAM% --template "%TEMPLATE%"
	)

	@if "%RAWDEBUG%"=="1" prompt $s	
goto:eof
:: ------------------------------------------------------------------------------
:tabMode
	@if "%DEBUG%"=="1" echo [DEBUG] function call normalMode
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set PROJECTNAME=%FOLDERNAME%&rem

	set BASETEMPLATE=%PROJECTNAME%
	if "%REV%" == "1" set BASETEMPLATE=%BASETEMPLATE%	r{rev}
	set BASETEMPLATE=%BASETEMPLATE%	{isodatesec(date)}
	if "%AGE%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{age(date)}
	set BASETEMPLATE=%BASETEMPLATE%	{user(author)}
	set BASETEMPLATE=%BASETEMPLATE%	{file}
	if "%COMMENTS%" == "1" set BASETEMPLATE=%BASETEMPLATE%	{firstline(desc)}

	set TEMPLATE={files %% '%BASETEMPLATE%\n'}

	if "%CLIP%"=="1" (
		echo.|clip
		hg log -v %USER% %DATEPARAM% --template "%TEMPLATE%" >> %TEMPFILE%
	) else (
		hg log -v %USER% %DATEPARAM% --template "%TEMPLATE%"
	)

	@if "%RAWDEBUG%"=="1" prompt $s	
goto:eof
:: ------------------------------------------------------------------------------
:: FUNCTION init
:: Script startup
:init
	@if "%DEBUG%"=="1" echo [DEBUG] function call init
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	set TODAY=%date:~6,4%-%date:~3,2%-%date:~0,2%
	set STARTDATE=%TODAY%
	set FINALDATE=%TODAY%
	set DATEPARAM=--date "%STARTDATE% to %FINALDATE%"

	@if "%RAWDEBUG%"=="1" prompt $s

goto:eof
:: ------------------------------------------------------------------------------
:: FUNCTION setBaseTemplate
:: ------------------------------------------------------------------------------
:: FUNCTION processArguments
:: Read all arguments and set differente variables according to their presence and values
:processArguments
	@if "%DEBUG%"=="1" echo [DEBUG] function call processArguments
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	:: reached the end of the parameters
	if "%1"=="" (
		@if "%RAWDEBUG%"=="1" prompt $s
		goto:eof
	)
	
	:: get the supposed parameters
	set OPTION=%1
	shift
	set VALUE=%1

	:: test if the option starts with "/" and is a proper option
	if not "%OPTION:~0,1%"=="/" goto:processArguments

	@if "%DEBUG%"=="1" echo [DEBUG] Detected argument %OPTION% %VALUE%

	:: do tasks according to the option and it's value
	if "%OPTION%"=="/u" set USER=%USER% -u %VALUE%
	if "%OPTION%"=="/me" set USER=%USER% -u %USERNAME%
	if "%OPTION%"=="/1" set USER=%USER% -u %USERNAME%
	if "%OPTION%"=="/sd" set STARTDATE=%VALUE%
	if "%OPTION%"=="/fd" set FINALDATE=%VALUE%
	if "%OPTION%"=="/rd" set RELDATE=%VALUE%
	if "%OPTION%"=="/min" set MODE_MIN=1
	if "%OPTION%"=="/m" set MODE_MIN=1
	if "%OPTION%"=="/clip" set CLIP=1
	if "%OPTION%"=="/r" set REV=1
	if "%OPTION%"=="/rev" set REV=1
	if "%OPTION%"=="/a" set AGE=1
	if "%OPTION%"=="/c" set COMMENTS=1
	if "%OPTION%"=="/rd" set RELDATE=%VALUE%
	if "%OPTION%"=="/v" set VERBOSE=1
	if "%OPTION%"=="/t" set MODE_TAB=1
	if "%OPTION%"=="/tab" set MODE_TAB=1
	if "%OPTION%"=="/o" set OUTPUT="%VALUE:/=\%"
	if "%OPTION%"=="/out" set OUTPUT="%VALUE:/=\%"

	if "%RELDATE%" == "" (
		set DATEPARAM=--date "%STARTDATE% to %FINALDATE%"
	) else (
		set DATEPARAM=--date %RELDATE%
	)

	goto processArguments

goto:eof
:: ------------------------------------------------------------------------------
:helpme
	@if "%DEBUG%"=="1" echo [DEBUG] function call helpme
	@if "%RAWDEBUG%"=="1" prompt $s$s$s$s$s

	echo.
	echo hgchg.bat: List changes in all Tortoise HG projects
	echo.
	echo Syntax: hgchg  [/me]  [/u ^<username^> ...]  [ [/sd ^<start date^>] [/fd ^<final date^>] ^| [/rd ^<-X days^>] ] [/rev]  [/age]  [/c]  [/min]  [/tab]  [/clip]  [/o <outputfile>]  [/help]
	echo.
	echo   ## USERS ##
	echo   -----------
	echo.
	echo     /u username : Show changes only for specific users. /u can be used many
	echo                   times. ex: hgchg /u user1 /u user2 /u user3
	echo     /me or /1 : Show changes for the current logged user.
	echo.
	echo   ## DATE ##
	echo   ----------
	echo.
	echo     /sd ^<start date^>   Start date in the format YYYY-MM-DD. Current date is the default.
	echo     /fd ^<final date^>   Final date in the format YYYY-MM-DD. Current date is the default.
	echo     /rd ^<-X^>           Bring data from X days ago until today. Overrides /sd and /fd
	echo.
	echo   ## LIST STYLE ##
	echo   ----------------
	echo.
	echo     /rev or /r       Show revision number
	echo     /age or /a       Show age, e.g. "10 hours ago", "2 weeks ago"
	echo     /c               Show commit comments (first line only)
	echo     /tab or /t       Tab mode - split columns using tabs, useful with /clip to use on excel
	echo     /min or /m       Minimal mode (list unique files, sorted). Overrides /r and /a.
	echo                          SORT.EXE and UNIQ.EXE are required. How to install:
	echo                          * Download: http://sourceforge.net/projects/unxutils/
	echo                          * Unzip anywhere
	echo                          * Add the folder ^<unxutils\usr\local\wbin^> to the PATH variable
	echo     /clip            Output the results to the clipboard instead of displaying them
	echo     /o ^<outputfile^>  Output the results to the specified file. USE DOUBLE QUOTES or
	echo                      ESCAPE BACKSLASH (use c:\\file.txt instead of c:\file.txt)
	echo.
	echo   ## OTHERS ##
	echo   ------------
	echo.
	echo     /help or /?  Display this help (using "/?" doesn't work)
	echo     /v           Verbose
	echo     /debug       Must be the first parameter. Show debug messages.
	echo     /rawdebug    Must be the first parameter. Show debug messages and echoes
	echo                  every line executed in the script.
	echo.
	echo   ## HOW TO CHANGE THE PROJECTS LIST ##
	echo   -------------------------------------
	echo.
	echo     Open the hgchg.bat file and edit the processProjects functions (the first one),
	echo     adding a call the the processPath function like below:
	echo.
	echo             call:processPath "c:\full path\to\the project\root\"
	echo.
	echo.
	echo   author: paulo amaral
	echo   version date: 2014-12-12

	@if "%RAWDEBUG%"=="1" prompt $s
goto:eof
:: ------------------------------------------------------------------------------
:: FUNCTION resertVars
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

