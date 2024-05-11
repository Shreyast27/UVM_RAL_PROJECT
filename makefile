all: clean compile simulate

compile:
	vlib work;
	vlog -sv top.sv \
	-timescale 1ns/1ns \
	-l covtest.log

simulate:
	vsim \
	work.top \
	-voptargs=+acc=npr \
	-c -do "log -r /*; run -all;  exit"
	gtkwave dump.vcd

clean:
	rm -rf transcript *.vcd *.wlf work/ *.log
