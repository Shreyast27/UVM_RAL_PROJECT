//*************TESTBENCH**************//
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "interface.sv"
`include "test.sv"
`include "dut.sv"

module top;
  bit clk = 0;
  bit rst;
  always #2 clk = ~clk;

  initial begin
    //clk = 0;
    rst = 0;
    #5;
    rst = 1;
  end
  dut_if vif (clk);

  //DUT Instantiation
  dut DUT (
      .clk(vif.clk),
      .rst(vif.rst),
      .data_in(vif.data_in),
      .valid_in(vif.valid_in),
      .paddr(vif.paddr),
      .psel(vif.psel),
      .pen(vif.pen),
      .p_write(vif.p_write),
      .p_wdata(vif.p_wdata),
      .out_port1(vif.out_port1),
      .out_port2(vif.out_port2),
      .out_port3(vif.out_port3),
      .out_port4(vif.out_port4),
      .valid_out(vif.valid_out),
      .prdata(vif.prdata)
  );

  initial begin
    // set interface in config_db
    uvm_config_db#(virtual dut_if)::set(null, "*", "vif", vif);
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars();
    #10000 $finish; //simulation takes roughly 6270ns for sending 10 packets
  end

  initial begin
     run_test("main_test");
  end
endmodule
