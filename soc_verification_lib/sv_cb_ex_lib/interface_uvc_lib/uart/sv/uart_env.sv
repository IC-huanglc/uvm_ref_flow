/*-------------------------------------------------------------------------
File name   : uart_env.sv
Title       : UART UVC env file 
Project     :
Created     :
Description : Creates and configures the UART UVC
Notes       :  
----------------------------------------------------------------------*/
//   Copyright 1999-2010 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------


`ifndef UART_ENV_SVH
`define UART_ENV_SVH

class uart_env extends uvm_env;

  // Virtual Interface variable
  virtual interface uart_if vif;

  // Environment Configuration Paramters
  uart_config cfg;         // UART configuration object
  bit checks_enable = 1;
  bit coverage_enable = 1;
   
  // Components of the environment
  uart_tx_agent Tx;
  uart_rx_agent Rx;

  // Used to update the config when it is updated during simulation
  //huanglc comment: this component uses IMP, and you should 
  //implement a function named "write" to use.
  uvm_analysis_imp#(uart_config, uart_env) dut_cfg_port_in;

  // This macro provide implementation of get_type_name() and create()
  `uvm_component_utils_begin(uart_env)
    `uvm_field_object(cfg, UVM_DEFAULT) //huanglc comment: the uart_config is an object, not a component.
    `uvm_field_int(checks_enable, UVM_DEFAULT)
    `uvm_field_int(coverage_enable, UVM_DEFAULT)
  `uvm_component_utils_end

  // Constructor - required UVM syntax
  function new( string name, uvm_component parent);
    super.new(name, parent);
    dut_cfg_port_in = new("dut_cfg_port_in", this);
  endfunction

  // Additional class methods
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task update_vif_enables();
  extern virtual function void write(uart_config cfg);
  extern virtual function void update_config(uart_config cfg);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);

endclass : uart_env

//UVM build_phase
function void uart_env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `uvm_info(get_type_name(), "entering build_phase", UVM_LOW);
  // Configure

  //huanglc comment: this is standard coding style. If not get configure from top_tb
  //then creat it by method "new()".
  //In this case, uart_env get uart_config from demo_tb.
  //And, the uvm_config_db#(uart_config)::get is omitted.
  //Attention! demo_tb set demo_config to uart_env, and demo_config is extended from uart_config.
  if ( cfg == null) begin
    `uvm_info(get_type_name(), "uart_config is null", UVM_LOW);
    if (!uvm_config_db#(uart_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info("NOCONFIG", "No uart_config, creating...", UVM_MEDIUM);
      cfg = uart_config::type_id::create("cfg", this);
      if (!cfg.randomize())
         `uvm_error("RNDFAIL", "Could not randomize uart_config using default values")
      `uvm_info(get_type_name(), {"Printing cfg:\n", cfg.sprint()}, UVM_MEDIUM);
    end
    else begin 
      `uvm_info(get_type_name(), "uart_config has got", UVM_LOW);
    end
  end
  else begin
    `uvm_info(get_type_name(), "uart_config is not null", UVM_LOW);
  end

  // Configure the sub-components
  uvm_config_object::set(this, "Tx*", "cfg", cfg);
  uvm_config_object::set(this, "Rx*", "cfg", cfg);

  // Create sub-components
  Tx = uart_tx_agent::type_id::create("Tx",this);
  Rx = uart_rx_agent::type_id::create("Rx",this);
endfunction : build_phase

//UVM connect_phase
function void uart_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  // Get the agent's virtual interface if set via config
  if(!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
    `uvm_error("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})
endfunction : connect_phase

// Function to assign the checks and coverage enable bits
task uart_env::update_vif_enables();
  // Make assignments at time 0 based on configuration
  //huanglc comment: I have not seen this coding style before.
  vif.has_checks <= checks_enable;
  vif.has_coverage <= coverage_enable;
  forever begin
    @(checks_enable or coverage_enable);
    vif.has_checks <= checks_enable;
    vif.has_coverage <= coverage_enable;
  end
endtask : update_vif_enables

// UVM run_phase
task uart_env::run_phase(uvm_phase phase);
  fork 
    update_vif_enables(); 
  join
endtask : run_phase
  
// Update the config when RGM updates?
function void uart_env::write(input uart_config cfg );
  this.cfg = cfg;
  update_config(cfg);
  `uvm_info("IMP function write", "call write method", UVM_LOW);
endfunction : write

// Update Agent config when config updates
function void uart_env::update_config(input uart_config cfg );
  Tx.update_config(cfg);
  Rx.update_config(cfg);   
endfunction : update_config

//added by huanglc
function void uart_env::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    dut_cfg_port_in.debug_provided_to();
endfunction

`endif
