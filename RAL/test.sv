`include "environment.sv"

class base_test extends uvm_test;
  environment env_h;
  `uvm_component_utils(base_test)
  
  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_h = environment::type_id::create("env_h", this);
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    test_imp();
    phase.drop_objection(this);
    `uvm_info(get_type_name, "End of testcase", UVM_LOW);
  endtask
  
  virtual task test_imp();
    base_seq bseq = base_seq::type_id::create("bseq");
        
    repeat(10) begin 
      #5; bseq.start(env_h.agent_h.seqr);
    end
  endtask
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass

//-------------------------------------------------------------------//


class reg_test extends base_test;
  `uvm_component_utils(reg_test)
  sequence_item tr;
  function new(string name = "reg_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //sequence_item tr = sequence_item::type_id::create ("tr");
  endfunction
  
    task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    test_imp();
    phase.drop_objection(this);
//        $display("WRITE_ADDRESS: %h | WRITE_DATA: %h",tr.addr,tr.data);
//        $display("READ_ADDRESS: %h | READ_DATA: %h",tr.addr,tr.data);
    `uvm_info(get_type_name, "End of testcase", UVM_LOW);
  endtask
  
  task test_imp();
    reg_seq rseq = reg_seq::type_id::create("rseq");
    rseq.start(env_h.agent_h.seqr);
  endtask
endclass

//-------------------------------------------------------------------//
