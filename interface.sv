//***************INTERFACE********************//

interface dut_if (
    input bit clk
);
  //input signals
  logic data_in, valid_in;
  logic [31:0] paddr, p_wdata;
  logic p_write, psel, pen, rst;

  //output signals
  logic [31:0] prdata;
  logic out_port1, out_port2, out_port3, out_port4;
  logic valid_out;
endinterface
