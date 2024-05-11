`include "environment.sv"

//****************BASE TEST**********************//
class base_test extends uvm_test;
  environment env_h;
  `uvm_component_utils(base_test)

//--------------------------------------------------------------------------------------------
// Construct: new
//  Initializes class object
//
// Parameters:
//  name - base_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
//--------------------------------------------------------------------------------------------
// Function: build_phase
// Description:
// Creates environment
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_h = environment::type_id::create("env_h", this);
  endfunction

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts base_seq
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    test_imp();

    phase.drop_objection(this);
    `uvm_info(get_type_name, "End of testcase", UVM_LOW);
  endtask

  virtual task test_imp();
    base_seq bseq = base_seq::type_id::create("bseq");

    repeat (10) begin
      #5;
      bseq.start(env_h.agent_h.seqr);
    end
  endtask

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass

//****************REGISTER TEST*********************//


class reg_test extends base_test;
  `uvm_component_utils(reg_test)
  sequence_item tr;

//--------------------------------------------------------------------------------------------
// Construct: new
//  Initializes class object
//
// Parameters:
//  name - base_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
  function new(string name = "reg_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Description:
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts reg_seq
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    test_imp();
    phase.drop_objection(this);
    `uvm_info(get_type_name, "End of testcase", UVM_LOW);
  endtask

  task test_imp();
    reg_seq rseq = reg_seq::type_id::create("rseq");
    rseq.start(env_h.agent_h.seqr);
  endtask
endclass

//****************RESET_TEST*********************//
class reset_test extends base_test;
  `uvm_component_utils(reset_test)
  sequence_item tr;

//--------------------------------------------------------------------------------------------
// Construct: new
//  Initializes class object
//
// Parameters:
//  name - base_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
  function new(string name = "reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Description:
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts reg_seq
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    test_imp();
    phase.drop_objection(this);
    `uvm_info(get_type_name, "End of testcase", UVM_LOW);
  endtask

  task test_imp();
    reset_seq re_seq = reset_seq::type_id::create("re_seq");
    re_seq.start(env_h.agent_h.seqr);
  endtask
endclass


//****************MAIN TEST**********************//
class main_test extends uvm_test;
  environment   env_h;
  sequence_item tr;

  `uvm_component_utils(main_test)

//--------------------------------------------------------------------------------------------
// Construct: new
//  Initializes class object
//
// Parameters:
//  name - base_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
  function new(string name = "main_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Description:
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_h = environment::type_id::create("env", this);
  endfunction

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts reg_seq
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    test();
    #1000;
    phase.drop_objection(this);
    `uvm_info(get_type_name, "End of testcase", UVM_LOW);
  endtask

  virtual task test();
  //both main(packet) and register(config) sequences are created and executed
    main_seq mseq = main_seq::type_id::create("mseq");
    reg_seq  rseq = reg_seq::type_id::create("rseq");

    repeat (1) begin
      rseq.start(env_h.agent_h.seqr);
      mseq.start(env_h.wa_h.write_seqr);
    end
  endtask

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass

