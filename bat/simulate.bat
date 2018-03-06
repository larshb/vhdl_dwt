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
REM xelab -debug typical dwt_2 -s dwt_2_tb
CALL xelab --nolog dwt_2_tb -s sim_snap
IF %ERRORLEVEL% NEQ 0 GOTO FAIL
CALL xsim --nolog -R sim_snap
IF %ERRORLEVEL% NEQ 0 GOTO FAIL

:SUCCESS
CALL "vbs/sim_success.vbs"
CALL "clean.bat"
EXIT /B 0

:FAIL
CALL "vbs/sim_fail.vbs"
CALL "clean.bat"
EXIT /B 1
