
//**////////**************Testbench Environment**********//////////**************//

//****************WRITE SEQUENCE ITEM************************//

class seq_item extends uvm_sequence_item;
  // Packet variable
  rand bit [15:0] src_addr;
  rand bit [15:0] dest_addr;
  rand bit [15:0] id;
  rand bit [15:0] data;

  bit [63:0] packet;
  bit [63:0] input_packet;
  bit [63:0] output_packet;

  // Add field macros for the new signals and packet
  `uvm_object_utils_begin(seq_item)
    `uvm_field_int(src_addr, UVM_ALL_ON)
    `uvm_field_int(dest_addr, UVM_ALL_ON)
    `uvm_field_int(id, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(packet, UVM_ALL_ON)
    `uvm_field_int(input_packet, UVM_ALL_ON)
    `uvm_field_int(output_packet, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "seq_item");
    super.new(name);
  endfunction
endclass



//***********MAIN_SEQUENCE*******************//
class main_seq extends uvm_sequence #(seq_item);
  seq_item req;
  `uvm_object_utils(main_seq)

  function new(string name = "main_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "***Base sequence***: Inside Body", UVM_LOW);
    repeat (10) begin //sending 10 packets
      `uvm_do(req);
      repeat (65) #4; //delay added to read output packets without interfering with input packets
    end
  endtask
endclass

//************************WRITE_SEQUENCER****************************//
class write_sequencer extends uvm_sequencer #(seq_item);
  `uvm_component_utils(write_sequencer)

  function new(string name = "write_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

//*********************WRITE_DRIVER*********************//

class write_driver extends uvm_driver #(seq_item);

  virtual dut_if vif;
  seq_item req;

  `uvm_component_utils(write_driver)

  function new(string name = "write_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Not set at top level");
  endfunction

  task run_phase(uvm_phase phase);
    @(posedge vif.clk) vif.rst <= 1'b0;
    @(posedge vif.clk) vif.rst <= 1'b1;
    forever begin
      seq_item_port.get_next_item(req);
      data_write();  // Call data_write task with the received sequence item
      seq_item_port.item_done();
    end
  endtask

  task data_write();
    int i;
    `uvm_info(get_type_name(), $sformatf("src_addr =%b and dest_addr =%b  and id =%b and data =%b",
                                         req.src_addr, req.dest_addr, req.id, req.data), UVM_NONE)

    req.packet = {req.src_addr, req.dest_addr, req.id, req.data}; //packet format

    `uvm_info(get_type_name(), $sformatf("packet=%b", req.packet), UVM_NONE)

    @(posedge vif.clk);
    vif.valid_in <= 1; //valid must be high to drive data
    foreach (req.packet[i]) begin //driving packet(64-bit)
      vif.data_in <= req.packet[i];
      @(posedge vif.clk);
    end
    vif.valid_in <= 0; //valid is driven low after packet sent

  endtask
endclass

//*********************WRITE_MONITOR*********************//

class write_monitor extends uvm_monitor;

  `uvm_component_utils(write_monitor)

  //Handle to virtual interface
  virtual dut_if vif;

  //Declaring a handle of sequence_item in write monitor
  seq_item req;

  //Declaring  analysis port
  uvm_analysis_port #(seq_item) item_got_port_wr_monitor;

  function new(string name = "write_monitor", uvm_component parent);
    super.new(name, parent);
    item_got_port_wr_monitor = new("item_got_port_wr_monitor", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    req = seq_item::type_id::create("item_got_wr_monitor");
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("Monitor: ", "No vif is found!")
    else `uvm_info("Monitor: ", "Vif found", UVM_NONE)
  endfunction

  virtual task run_phase(uvm_phase phase);
    int i = 63;
    forever begin
      @(posedge vif.clk)
      if (vif.valid_in == 1) begin
        req.input_packet[i] = vif.data_in;  //input_packet receives data_in
        i--;
        if (i == -1) begin
          item_got_port_wr_monitor.write(req);
          i = 63;
          `uvm_info(get_type_name(), $sformatf("input packet=%b and time =%0t ", req.input_packet, $time), UVM_NONE)
        end
      end
    end
  endtask
endclass

//********************WRITE_AGENT*********************//

class write_agent extends uvm_agent;

  write_sequencer write_seqr;
  write_driver write_dri;
  write_monitor write_mon;

  `uvm_component_utils(write_agent)

  function new(string name = "write_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      write_seqr = write_sequencer::type_id::create("write_seqr", this);
      write_dri  = write_driver::type_id::create("write_dri", this);
    end
    write_mon = write_monitor::type_id::create("write_mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) write_dri.seq_item_port.connect(write_seqr.seq_item_export);
  endfunction
endclass

//*********************READ_MONITOR*********************//

class read_monitor extends uvm_monitor;

  `uvm_component_utils(read_monitor)

  //Handle to virtual interface
  virtual dut_if vif;
  //Declaring a handle of sequence_item in write monitor
  seq_item req;
  bit vari;
  //Declaring  analysis port
  uvm_analysis_port #(seq_item) item_got_port_rd_monitor;

  function new(string name = "read_monitor", uvm_component parent);
    super.new(name, parent);
    item_got_port_rd_monitor = new("item_got_port_rd_monitor", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    req = seq_item::type_id::create("req");
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
      `uvm_fatal("Monitor: ", "No vif is found!")
    else `uvm_info("Monitor: ", "Vif found", UVM_NONE)
  endfunction

  virtual task run_phase(uvm_phase phase);
  //internal counters to receive the 64-bit packets. Counter decrements when bits are received.
    int i = 64;
    int j = 64;
    int k = 64;
    int l = 64;

    super.run_phase(phase);

    forever begin
      @(posedge vif.clk)
      if (vif.valid_out) begin
        if (vif.paddr == 32'd8 && vif.p_wdata == 32'd1) begin
          repeat (64) begin
            i--;
            vari = vif.out_port1; //receiving bit from port1 and storing to vari
            req.output_packet = {req.output_packet[62:0], vari}; //concatenation to create output packet
            @(posedge vif.clk);
          end
        end else if (vif.paddr == 32'd8 && vif.p_wdata == 32'd2) begin
          repeat (64) begin
            j--;
            vari = vif.out_port2; //receiving bit from port2 and storing to vari;
            req.output_packet = {req.output_packet[62:0], vari}; //concatenation to create output packet;
            @(posedge vif.clk);
          end
        end else if (vif.paddr == 32'd8 && vif.p_wdata == 32'd4) begin
          repeat (64) begin
            k--;
            vari = vif.out_port3; //receiving bit from port3 and storing to vari;
            req.output_packet = {req.output_packet[62:0], vari}; //concatenation to create output packet;
            @(posedge vif.clk);
          end
        end else if (vif.paddr == 32'd8 && vif.p_wdata == 32'd8) begin
          repeat (64) begin
            l--;
            vari = vif.out_port4; //receiving bit from port4 and storing to vari;
            req.output_packet = {req.output_packet[62:0], vari}; //concatenation to create output packet;
            @(posedge vif.clk);
          end
        end
        `uvm_info(get_type_name(), $sformatf("outputpacket=%b", req.output_packet), UVM_NONE)

      end
      if (i == 0 || j == 0 || k == 0 || l == 0) begin
        item_got_port_rd_monitor.write(req); //if packet is complete, write to scoreboard
        //reset counters
        i = 64;
        j = 64;
        k = 64;
        l = 64;
      end
    end
  endtask
endclass

//*********************READ_AGENT*********************//
class read_agent extends uvm_agent;
  read_monitor read_mon;

  `uvm_component_utils(read_agent)

  function new(string name = "read_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    read_mon = read_monitor::type_id::create("read_mon", this); //passive agent, and hence only read monitor is created
  endfunction
endclass

//*********************SCOREBOARD*********************//

`uvm_analysis_imp_decl(_activeport)
`uvm_analysis_imp_decl(_passiveport)
class scoreboard extends uvm_scoreboard;
  int pkt_num = 0;
  bit [63:0] input_packet;
  bit [63:0] output_packet;
  `uvm_component_utils(scoreboard)
  uvm_analysis_imp_activeport #(seq_item, scoreboard)  active;
  uvm_analysis_imp_passiveport #(seq_item, scoreboard) passive;

  // new - constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    active  = new("activeport", this);
    passive = new("passiveport", this);

  endfunction : build_phase

  // write
  virtual function void write_activeport(seq_item req);
    input_packet = req.input_packet;
    //     $display("IN SCB input_packet is %b", req.packet);
  endfunction

  virtual function void write_passiveport(seq_item req);
    //     $display("write_passiveport %t", $time);
    output_packet = req.output_packet;
    pkt_num++;
    check_1;
  endfunction

  virtual function void check_1;
    //super.check_phase(phase);
    $display("PACKET - %0d", pkt_num);
    if (input_packet[63:48] == output_packet[47:32])
      $display(
          "Source address match: input = %h, output = %h", input_packet[63:48], output_packet[47:32]
      );
    else
      $display(
          "Source address mismatch: input = %h, output = %h",
          input_packet[63:48],
          output_packet[47:32]
      );

    if (input_packet[47:32] == output_packet[63:48])
      $display(
          "Destination address match: input = %h, output = %h",
          input_packet[47:32],
          output_packet[63:48]
      );
    else
      $display(
          "Destination address mismatch: input = %h, output = %h",
          input_packet[47:32],
          output_packet[63:48]
      );

    if (input_packet[15:0] == output_packet[15:0])
      $display("Data match: input = %h, output = %h", input_packet[15:0], output_packet[15:0]);
    else
      $display("Data mismatch: input = %h, output = %h", input_packet[15:0], output_packet[15:0]);

    if (input_packet[31:16] == output_packet[31:16])
      $display("ID match: input = %h, output = %h", input_packet[31:16], output_packet[31:16]);
    else
      $display("ID mismatch: input = %h, output = %h", input_packet[31:16], output_packet[31:16]);

    $display("---------------------------------------------");
  endfunction


endclass
