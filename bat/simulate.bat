:COMPILE
CALL xvhdl --nolog^
 ../rtl/utils.vhd^
 ../rtl/pipe.vhd^
 ../rtl/mem.vhd^
 ../rtl/dwt_1.vhd^
 ../rtl/dwt_2.vhd
IF %ERRORLEVEL% NEQ 0 GOTO FAIL

CALL xvlog --nolog^
 ../tb/dwt_2_tb.v
IF %ERRORLEVEL% NEQ 0 GOTO FAIL

echo [101;102m Compilation successfull! [0m

:PROMPT
REM Ensure efficient workflow by skipping some simulations,
REM as the pesky Xilinx WebTALK is too damn slow.
SET /P CONFIRMATION=Continue with simulation? (Y/[N])?
IF /I "%CONFIRMATION%" NEQ "Y" GOTO CLEAN

:ELABORATE
CALL xelab --nolog dwt_2_tb -s sim_snap
IF %ERRORLEVEL% NEQ 0 GOTO FAIL

:SIMULATE
CALL xsim --nolog -R sim_snap
IF %ERRORLEVEL% NEQ 0 GOTO FAIL

:SUCCESS
CALL "vbs/sim_success.vbs"

:CLEAN
CALL "clean.bat"
EXIT /B 0

:FAIL
CALL "vbs/sim_fail.vbs"
CALL "clean.bat"
EXIT /B 1
