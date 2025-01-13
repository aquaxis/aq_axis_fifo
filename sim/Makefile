VIVADO_DIR := /tools/Xilinx/Vivado/2024.2
XVLOG := $(VIVADO_DIR)/bin/xvlog
XELAB := $(VIVADO_DIR)/bin/xelab
XSIM  := $(VIVADO_DIR)/bin/xsim

SRC_DIR   := ../rtl
TB_DIR   := ../tb
SRC_FILES := $(shell ls $(SRC_DIR)/*.sv) $(shell ls $(SRC_DIR)/*.v) $(shell ls $(TB_DIR)/*.sv) $(shell ls $(TB_DIR)/*.v) 

TOP := tb_aq_axis_fifo

gui: clean sim ./start.tcl
	$(XSIM) $(TOP) -gui -t ./start.tcl

cli: clean sim ./cli.tcl
	$(XSIM) $(TOP) -t ./cli.tcl

dump: sim ./dump.tcl
	$(XSIM) $(TOP) -t ./dump.tcl -wdb dump.wdb

wave: dump.wdb
	$(XSIM) dump.wdb -gui

sim: $(SRC_FILES)
	$(XVLOG) -sv $(SRC_FILES)
	$(XELAB) $(TOP) --debug all -timescale 1ns/1ps

clean:
	rm -rf *.log *.jou *.pb xsim.dir *.sh *.wdb .Xil *.tcl

./dump.tcl:
	echo 'log_wave -r *'  > $@
	echo 'run all'       >> $@

./start.tcl:
	echo 'create_wave_config;' > $@
	echo 'add_wave /;' >> $@
	echo 'set_property needs_save false [current_wave_config];' >> $@
	echo 'run 10 us;' >> $@

./cli.tcl: ./start.tcl 
	cat start.tcl > $@
	echo 'exit;' >> $@
