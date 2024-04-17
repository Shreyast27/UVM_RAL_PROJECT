`include "ral.sv"

class sequence_item extends uvm_sequence_item;
   rand bit [31:0]  addr;
   rand bit [31:0]  data;
   rand bit         write;
 
   `uvm_object_utils_begin (sequence_item)
      `uvm_field_int (addr, UVM_ALL_ON)
      `uvm_field_int (data, UVM_ALL_ON)
      `uvm_field_int (write, UVM_ALL_ON)
   `uvm_object_utils_end
 
   function new (string name = "sequence_item");
      super.new (name);
   endfunction
   constraint addr_c {addr inside {0, 4, 8};}
endclass

//-------------------------------------------------------------------//
class base_seq extends uvm_sequence#(sequence_item);
  sequence_item tr;
  `uvm_object_utils(base_seq)
  
  function new (string name = "base_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "Base seq: Inside Body", UVM_LOW);
    `uvm_do(tr);
  endtask
endclass

//--------------------TO DO ---------------------------------------//


class reg_seq extends uvm_sequence#(sequence_item);
  sequence_item tr;
  m_reg_block reg_model;
  uvm_status_e   status;
  uvm_reg_data_t read_data;
  `uvm_object_utils(reg_seq)
  
  function new (string name = "reg_seq");
    super.new(name);
  endfunction

  task body();
    //sequence_item tr = sequence_item::type_id::create ("tr");
    `uvm_info(get_type_name(), "Reg seq: Inside Body", UVM_LOW);
    if(!uvm_config_db#(m_reg_block) :: get(uvm_root::get(), "", "reg_model", reg_model))
      `uvm_fatal(get_type_name(), "reg_model is not set at top level");
    //----------------------------------------------
    reg_model.reg_block_h.chip_enable.write(status, 1'b1);
   // $display("WRITE_ADDRESS: %h | WRITE_DATA: %h",tr.addr,tr.data);
    reg_model.reg_block_h.chip_enable.read(status, read_data);
//     $display("READ_ADDRESS: %h | READ_DATA: %h",tr.addr,tr.data);
    //----------------------------------------
    reg_model.reg_block_h.chip_id.write(status, 8'h100);
    reg_model.reg_block_h.chip_id.read(status, read_data);
    
    reg_model.reg_block_h.output_port_enable.write(status, 4'ha);
    reg_model.reg_block_h.output_port_enable.read(status, read_data);
//      reg_model.reg_block_h.intr_msk_reg.write(status, 32'h5555_5555);
//     reg_model.reg_block_h.intr_msk_reg.read(status, read_data);
    
//     reg_model.reg_block_h.debug_reg.write(status, 32'hAAAA_AAAA);
//      reg_model.reg_block_h.debug_reg.read(status, read_data);
    
  endtask
endclass

//-------------------------------------------------------------------//


class bus_sequencer extends uvm_sequencer#(sequence_item);
  `uvm_component_utils(bus_sequencer)
  
  function new(string name = "bus_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
endclass

//-------------------------------------------------------------------//


class bus_driver extends uvm_driver #(sequence_item);
   `uvm_component_utils (bus_driver)
 
   sequence_item  tr;
   virtual dut_if  vif;
 
   function new (string name = "bus_driver", uvm_component parent);
      super.new (name, parent);
   endfunction
 
   virtual function void build_phase (uvm_phase phase);
      super.build_phase (phase);
     if (!uvm_config_db#(virtual dut_if)::get(this,"", "vif", vif))
         `uvm_error ("BUS DRIVER", "Did not get bus if handle")
   endfunction
 
   virtual task run_phase (uvm_phase phase);
      bit [31:0] data;
 
      vif.psel <= 0;
      vif.pen <= 0;
      vif.p_write <= 0;
      vif.paddr <= 0;
      vif.p_wdata <= 0;
      forever begin
         @(posedge vif.clk);
         seq_item_port.get_next_item (tr);
         if (tr.write)
            write (tr.addr, tr.data);
         else begin
            read (tr.addr, data);
            tr.data = data;
         end
         seq_item_port.item_done ();
      end
   endtask
 
   virtual task read (  input bit    [31:0] addr, 
                        output logic [31:0] data);
      vif.paddr <= addr;
      vif.p_write <= 0;
      vif.psel <= 1;
      @(posedge vif.clk);
      vif.pen <= 1;
      @(posedge vif.clk);
      data = vif.prdata;
      vif.psel <= 0;
      vif.pen <= 0;
     `uvm_info(get_type_name, $sformatf("raddr = %0h, rdata = %0h", tr.addr, tr.data), UVM_LOW);
   endtask
 
   virtual task write ( input bit [31:0] addr,
                        input bit [31:0] data);
      vif.paddr <= addr;
      vif.p_wdata <= data;
      vif.p_write <= 1;
      vif.psel <= 1;
      @(posedge vif.clk);
      vif.pen <= 1;
      @(posedge vif.clk);
      vif.psel <= 0;
      vif.pen <= 0;
     `uvm_info(get_type_name, $sformatf("waddr = %0h, wdata = %0h", tr.addr, tr.data), UVM_LOW);
   endtask
endclass

//-------------------------------------------------------------------//

     
class bus_monitor extends uvm_monitor;
   `uvm_component_utils (bus_monitor)
   function new (string name="bus_monitor", uvm_component parent);
      super.new (name, parent);
   endfunction
 
  uvm_analysis_port #(sequence_item)  mon_ap;
   virtual dut_if  vif;
 
   virtual function void build_phase (uvm_phase phase);
      super.build_phase (phase);
      mon_ap = new ("mon_ap", this);
//      uvm_config_db #(virtual dut_if)::get (null, "testbench.*", "dut_if", vif);
//      void'(uvm_config_db #(virtual dut_if)::get(this,"", "vif", vif));
     if (!uvm_config_db#(virtual dut_if)::get(this,"", "vif", vif))
        `uvm_error ("BUS MONITOR", "Did not get bus if handle")


   endfunction
 
   virtual task run_phase (uvm_phase phase);
      fork
         @(posedge vif.rst);
         forever begin
            @(posedge vif.clk);
           if (vif.psel & vif.pen & vif.rst) begin
               sequence_item tr = sequence_item::type_id::create ("tr");
               tr.addr = vif.paddr;
             if (vif.p_write)begin
                  tr.data = vif.p_wdata;
               $display("WRITE");
               $display("raddr = %0h, rdata = %0h", tr.addr, tr.data);
//                `uvm_info(get_type_name, $sformatf("Waddr = %0h, Wdata = %0h", tr.addr, tr.data), UVM_LOW);
             end
               else begin
                  tr.data = vif.prdata;
               tr.write = vif.p_write;
                 $display("READ");
//              `uvm_info(get_type_name, $sformatf("raddr = %0h, rdata = %0h", tr.addr, tr.data), UVM_LOW);
                 $display("raddr = %0h, rdata = %0h", tr.addr, tr.data);
               end
               mon_ap.write (tr);
//              `uvm_info(get_type_name, $sformatf("raddr = %0h, rdata = %0h", tr.addr, tr.data), UVM_LOW);
            end 
         end
        
      join_none
   endtask
endclass

     
//-------------------------------------------------------------------//

     
class bus_agent extends uvm_agent;
  `uvm_component_utils(bus_agent)
  bus_driver drv;
  bus_sequencer seqr;
  bus_monitor mon;
  
  function new(string name = "bus_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
   // if(get_is_active == UVM_ACTIVE) begin 
      drv =  bus_driver::type_id::create("drv", this);
      seqr = bus_sequencer::type_id::create("seqr", this);
//     end
    
    mon = bus_monitor::type_id::create("mon", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    //if(get_is_active == UVM_ACTIVE) begin 
      drv.seq_item_port.connect(seqr.seq_item_export);
    //end
  endfunction
endclass

   
//-------------------------------------------------------------------//

     
class adapter extends uvm_reg_adapter;
   `uvm_object_utils (adapter)
 
   function new (string name = "adapter");
      super.new (name);
   endfunction
 
   virtual function uvm_sequence_item reg2bus (const ref uvm_reg_bus_op rw);
      sequence_item tr = sequence_item::type_id::create ("tr");
      tr.write = (rw.kind == UVM_WRITE) ? 1: 0;
      tr.addr  = rw.addr;
      tr.data  = rw.data;
      `uvm_info ("adapter", $sformatf ("reg2bus addr=0x%0h data=0x%0h kind=%s", tr.addr, tr.data, rw.kind.name), UVM_DEBUG) 
      return tr; 
   endfunction
 
   virtual function void bus2reg (uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      sequence_item tr;
      if (! $cast (tr, bus_item)) begin
         `uvm_fatal ("reg2apb_adapter", "Failed to cast bus_item to tr")
      end
 
      rw.kind = tr.write ? UVM_WRITE : UVM_READ;
      rw.addr = tr.addr;
      rw.data = tr.data;
      `uvm_info ("adapter", $sformatf("bus2reg : addr=0x%0h data=0x%0h kind=%s status=%s", rw.addr, rw.data, rw.kind.name(), rw.status.name()), UVM_DEBUG)
   endfunction
endclass
     
     
//-------------------------------------------------------------------//

     
class reg_environment extends uvm_env;
  `uvm_component_utils(reg_environment)
  bus_agent agt;
  adapter adapt; // adapter handle
  uvm_reg_predictor #(sequence_item) ral_predictor; //predictor handle
  m_reg_block reg_model; // Top level register block

  function new(string name = "reg_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = bus_agent::type_id::create("agt", this);
    adapt = adapter::type_id::create("adapt");
    ral_predictor = uvm_reg_predictor #(sequence_item) :: type_id:: create("ral_predictor", this);
    reg_model = m_reg_block::type_id::create("reg_model");
    reg_model.build();
    reg_model.lock_model();
    uvm_config_db #(m_reg_block)::set (null, "*", "reg_model", reg_model);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    reg_model.default_map.set_sequencer( .sequencer(agt.seqr), .adapter(adapt) ); // Doubt .adapter(adapter) ?
    reg_model.default_map.set_base_addr('h0);
    ral_predictor.map = reg_model.default_map; //Assigning map handle
    ral_predictor.adapter = adapt; //Assigning adapter handle
    // Monitor analysis port and predictor analysis import connection
  endfunction
endclass
     
//-------------------------------------------------------------------//


class environment extends uvm_env;
  `uvm_component_utils(environment)
  bus_agent agent_h;
  reg_environment reg_env_h;

   function new(string name = "environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent_h = bus_agent::type_id::create("agent_h", this);
    reg_env_h = reg_environment::type_id::create("reg_env_h",this);
  endfunction
 function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
   // reg_env_h.agt=agent_h;
   agent_h.mon.mon_ap.connect(reg_env_h.ral_predictor.bus_in); // bus_in ????
   reg_env_h.reg_model.default_map.set_sequencer(agent_h.seqr,reg_env_h.adapt);
  endfunction
endclass
