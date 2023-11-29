	rm  *.log -rf csrc *fsdb
    vcs -timescale=1ns/1ns \
        -sverilog \
        -kdb \
        -lca \
    	${UVM_HOME}/src/dpi/uvm_dpi.cc \
    	-CFLAGS -DVCS \
        -debug_all \
        -full64 \
        +vcs+lic+wait \
        -f filelist/tb.f \
    	-l com.log \
        -P ${NOVAS_HOME}/share/PLI/VCS/LINUX64/novas.tab ${NOVAS_HOME}/share/PLI/VCS/LINUX64/pli.a

    ./simv -l sim.log \
         +UVM_TESTNAME=uart_sequence_test \
         +UVM_VERBOSITY=UVM_HIGH \

