::if 0 {#<BOF name="infodump.tcl" vers="2.0" />
@goto start
::#--------------------------------------------------
::# MS BAT/CMD Header Section
::#--------------------------------------------------
:start
@echo off
set SCRIPT=%0
if exist %SCRIPT%.bat set SCRIPT=%SCRIPT%.bat
if exist %SCRIPT%.cmd set SCRIPT=%SCRIPT%.cmd
:: Default to tclsh
set INTERP=tclsh
:: Check if the filename contains ".tk"
echo %0 | findstr /i ".tk" >nul
if %errorlevel% equ 0 set INTERP=wish
:: Check if the first argument is "-gui"
if /i "%~1"=="-gui" (
    set INTERP=wish
    shift
)

:: Run the selected interpreter
echo "exec %INTERP% %SCRIPT% %*"
%INTERP% %SCRIPT% %*
goto :eof
}
#--------------------------------------------------
# Tcl / Tk Code Payload Begins Here
#--------------------------------------------------
proc :eof {args} {}
proc ::rem {args} {}
package require Tcl "9.0"
namespace eval ::infodump {
    variable {vsAppVers} "2.0"
    variable {sInfodumpVers} "2.0"
    variable vlArgC $::argc
    variable vlArgV $::argv
    source "01init.tcl"
    source "02proc.tcl"
    source "03term.tcl"
    source "object.tcl"

    # Import the exported object procedure directly into this scope
    namespace import ::infodump::object::fnGetObjects

    fnStep1
    fnStep2
    fnStep3
}
;#<EOF name="infodump.tcl" vers="2.0" />:EOF
::rem just in case the cmd.exe processor gets replaced with something that
::rem tries to find an actual :EOF lable...
:eof