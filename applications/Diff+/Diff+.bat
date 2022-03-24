@echo off
setlocal EnableDelayedExpansion

REM See :about for app details

REM Switch to the batch file directory.
pushd "%~dp0"

REM Bind numeral-only date + time to variable, if needed
for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined _now set _now=%%x
set _todayIso=%_now:~0,4%-%_now:~4,2%-%_now:~6,2%
set /a _execDayInt=%_now:~0,8%
REM We prefix a 9, to make sure that the integer does not start with zero
set /a _execTimeInt=9%_now:~8,6%
REM Place-holder for filenames
set _fn=
REM Set to 1 if you want feedback on the command line
set _diagnostics=0
REM Placeholder to count the number of parameters
set _argCount=0
REM The fully resolved URI of this batch file
set _thisBatchName=%0

REM The next three parameters point to files: the XSLT, the output, and the
REM Saxon engine. Be sure to use Unix-style path separators, and write any
REM relative paths against the directory of the batch file.

REM Where is the XSLT file?
set _xslPath=Diff+.xsl
REM Where is the output directory?
set _outputDir=../../output

REM Where should any output go? Check the target stylesheet to see what output
REM if any there is. If there is none, or the output is of no consequence, leave
REM it blank. If you do wish primary output, preface the value of !_xslOutput!
REM with -o:, e.g., -o:!_xslPath!.output.xml
set _xslOutput=-o:%_outputDir%/%_xslPath%.output.xml
REM Where is the Saxon processor?
set _saxonPath=../../processors/saxon.jar
REM what command-line options should be set for Saxon? For details see
REM https://saxonica.com/documentation/index.html#!using-xsl/commandline
set _saxonOptions=
REM What is the name of the one parameter that is expecting the sequence of resolved URLs?
set _keyParameter=resolved-uris-to-lists-of-main-input-resolved-uris
REM What other parameters declared by the stylesheet if any should be provided? 
REM Follow https://saxonica.com/documentation/index.html#!using-xsl/commandline
set _otherParameters=

REM Set up temporary file. Presumes that the user has write permissions.
set _tempFile=%Time: =0%
set _tempFile=%_tempFile::=%
set _tempFile=%_tempFile:.=%
set _tempFile=%temp%\~miru-%_tempFile:,=%.tmp
type NUL > "%_tempFile%"

REM Set up MIRU list parameter.
set _miruList=file:/!_tempFile: =%%20!
set _miruList=%_miruList:\=/%

if not exist %_xslPath% (
	echo Cannot find the XSLT application at %_xslPath%
	goto slowexit
)

if not exist %_saxonPath% (
	echo Cannot find the Saxon processor at %_saxonPath%
	goto slowexit
)

REM Anyone who simply clicks on the batch file should be given instructions only
if [%1]==[] goto about

REM Escape parentheses in the parameters otherwise the command
REM will get tripped up.
set _allBatchParams=%*
set _allBatchParamsRevised=%_allBatchParams:(=^^^(%
set _allBatchParamsRevised=%_allBatchParamsRevised:)=^^^)%

if %_diagnostics% == 1 (
	echo parameters as revised: %_allBatchParamsRevised%
)

REM Process input URIs to find files in subdirectories. Doing so at this point is much
REM faster than asking the XSLT code to do so, because the shell will use native methods.
for %%G in (%_allBatchParamsRevised%) do (
    set /A _argCount+=1
	echo %%G
    set _fn=%%G
	REM Normalize URI to XSLT specs: the file:/ protocol, percent-20
	REM for spaces, drop quotation marks, and normalize slashes. UNC 
	REM paths are doubled in XSLT syntax
	set _fn=file:/!_fn: =%%20!
	set _fn=!_fn:\\=////!
	set _fn=!_fn:\=/!
	set _fn=!_fn:"=!
    if %_diagnostics% == 1 echo input url: !_fn!
	REM If it is a directory with a file inside, iterate over its contents
    if exist %%G\* (
        if %_diagnostics% == 1 echo !_fn! is a directory
        for /f "tokens=*" %%U in ('dir %%G /B /S') do (
			set _dirFn=%%U
			set _dirFn=file:/!_dirFn: =%%20!
			set _dirFn=!_dirFn:\\=////!
			set _dirFn=!_dirFn:\=/!
			set _dirFn=!_dirFn:"=!
            if not exist %%U\* (
                if %_diagnostics% == 1 echo adding file: !_dirFn!
				@echo !_dirFn!>> "%_tempFile%"
            )
			set /A _subCount+=1
        )
    ) else (
        if %_diagnostics% == 1 echo adding file: !_fn!
		@echo !_fn!>> "%_tempFile%"
    )
)

REM build the command line that will be sent to Saxon 
set _saxonComLine=java -cp !_saxonPath! net.sf.saxon.Transform -xsl:!_xslPath! -s:!_xslPath! !_xslOutput! !_saxonOptions! !_otherParameters! !_keyParameter!=!_miruList!

if !_diagnostics! == 1 (
    echo Number of parameters: !_argCount!
    echo Path to starting ^(master^) XSLT: !_xslPath!
	echo Path to primary output: !_xslOutput!
    echo Path to Saxon processor: !_saxonPath!
	echo Path to list of MIRUs: !_miruList!
    echo Command line about to be executed: 
	echo.
	echo !_saxonComLine!
	echo.
	echo If the command fails, and you wish to diagnose, copy the line above and run
	echo again in a shell, from here, the context directory of the batch file:
	echo %cd%
	set /P _goAhead="Do you wish to proceed (y = yes; anything else = no)? "
	if /I "!_goAhead!"=="y" (
		echo Executing the command.
		) else (
		exit /B
	)
)
REM Execute the command
!_saxonComLine!

echo.
if !_diagnostics! == 1 (
	echo Do not forget to delete temporary file !_tempFile!
	) else (
	del !_tempFile!
)

REM Open up the HTML output
for %%G in (%_outputDir%\*.HTM*) do (
	set _currDT=%%~tG
	set /a _currDayInt=!_currDT:~6,4!!_currDT:~0,2!!_currDT:~3,2!
	if !_currDayInt! geq %_execDayInt% (
		set _currDayHalf=!_currDT:~17,2!
		set /a _currTimeInt=9!_currDT:~11,2!!_currDT:~14,2!59
		REM add 12 hours if it is PM
		if !_currDayHalf!==PM set /a _currTimeInt+=120000
		if !_currTimeInt! geq %_execTimeInt% (
			echo Opening %%G
			start "" "%%G"
		)
	)
)

REM if primary output has been generated, open it
if exist !_xslOutput! (
	set /P _openOutput="Do you wish to open the primary output, saved at !_xslOutput! (y = yes; anything else = no)? "
	if /I "!_openOutput!"=="y" start "" !_xslOutput!
)

REM Pause to let the user read messages from the XSLT application.
pause
exit /B

:about

REM documentation start
echo. Handler for TAN Diff+
REM documentation end

REM instructions start
echo.
echo To use: In Windows Explorer drag onto this batch file any files or directories 
echo you want to be processed. The resolved URIs are passed as a list to the parameter
echo $%_keyParameter% in the XSLT stylesheet at: 
echo %_xslPath%
REM instructions end

:slowexit

pause
exit /B