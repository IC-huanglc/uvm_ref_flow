clean:
	rm  *.log -rf csrc *fsdb simv*

comp:
	vcs -timescale=1ns/1ns -sverilog -kdb -lca ${UVM_HOME}/src/dpi/uvm_dpi.cc -CFLAGS -DVCS -debug_all -full64 +vcs+lic+wait -f filelist/tb.f -l com.log -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a

sim:
	./simv -l sim.log +UVM_TESTNAME=uart_sequence_test +UVM_VERBOSITY=UVM_HIGH

all: clean comp sim
