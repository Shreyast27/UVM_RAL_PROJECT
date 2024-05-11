//******************CHIP ENABLE REGISTER****************//

// Register definition for the register called "chip_enable"
class chip_enable_reg extends uvm_reg;
  rand uvm_reg_field enable;  // 0: Chip Disable, no output  
                              // 1: Chip Enabled, normal working mode

  `uvm_object_utils(chip_enable_reg)

  function new(string name = "chip_enable_reg");
    super.new(name, 1, build_coverage(UVM_NO_COVERAGE));
  endfunction : new

  // Build all register field objects
  virtual function void build();
    this.enable = uvm_reg_field::type_id::create("enable",, this.get_full_name());

    // configure(parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible); 
    this.enable.configure(this, 1, 0, "RW", 0, 1'h1, 1, 1, 0);  // is_rand = 0 or is_rand = 1: doubt
  endfunction
endclass

//***************CHIP ID REGISTER*******************//
// Register definition for the register called "chip_id"
class chip_id_reg extends uvm_reg;
  uvm_reg_field chip_id;  // Time for which it blinks
  // volatile - doubt
  // is_rand - doubt
  `uvm_object_utils(chip_id_reg)

  function new(string name = "chip_id_reg");
    super.new(name, 8, build_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    this.chip_id = uvm_reg_field::type_id::create("chip_id",, this.get_full_name());

    // configure(parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible); 
    this.chip_id.configure(this, 8, 0, "RO", 0, 8'hAA, 1, 1, 0);
  endfunction
endclass

//****************OUTPUT PORT ENABLE REGISTER***************//
// Register definition for the register called "Output_Port_enable_reg"
class Output_Port_enable_reg extends uvm_reg;
  rand uvm_reg_field Output_Port_enable;  // Enables the port enable [Doubt]
  `uvm_object_utils(Output_Port_enable_reg)

  function new(string name = "Output_Port_enable_reg");
    super.new(name, 4, build_coverage(UVM_NO_COVERAGE));
  endfunction : new

  // Build all register field objects
  virtual function void build();
    this.Output_Port_enable =
        uvm_reg_field::type_id::create("Output_Port_enable",, this.get_full_name());

    // configure(parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible); 
    this.Output_Port_enable.configure(this, 4, 0, "RW", 0, 1'h1, 1, 1, 0); 
  endfunction
endclass

//******************REGISTER BLOCK*************************//
class reg_block extends uvm_reg_block;
  `uvm_object_utils(reg_block)

  rand chip_enable_reg chip_enable; //rand since RW type register
  chip_id_reg chip_id; //RO type register
  rand Output_Port_enable_reg output_port_enable; //RW type register

  function new(string name = "reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 1);

    chip_enable = chip_enable_reg::type_id::create("chip_enable");
    chip_enable.configure(this, null);
    chip_enable.build();

    chip_id = chip_id_reg::type_id::create("chip_id");
    chip_id.configure(this, null);
    chip_id.build();

    output_port_enable = Output_Port_enable_reg::type_id::create("output_port_enable");
    output_port_enable.configure(this, null);
    output_port_enable.build();

    this.default_map.add_reg(chip_enable, 0, "RW");
    this.default_map.add_reg(chip_id, 4, "RO");
    this.default_map.add_reg(output_port_enable, 8, "RW");
  endfunction
endclass


//**************TOP LEVEL REGISTER BLOCK*****************//
class m_reg_block extends uvm_reg_block;
  rand reg_block reg_block_h;
  `uvm_object_utils(m_reg_block)

  function new(string name = "m_reg_block");
    super.new(name);
  endfunction

  virtual function void build();
    this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 1);
    this.reg_block_h = reg_block::type_id::create("reg_block_h");
    this.reg_block_h.configure(this, "*");
    this.reg_block_h.build();
    this.default_map.add_submap(this.reg_block_h.default_map, 0);
  endfunction
endclass



