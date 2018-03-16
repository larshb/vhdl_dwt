source ps7_init.tcl;
source cubedma.tcl;

proc send_data {} {
	start_mm2s_simple_transfer 0 [expr 128*128+1];
}

connect;
targets 2;
init;