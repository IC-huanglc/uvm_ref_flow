/*-------------------------------------------------------------------------
File name   : uart_tx_driver.sv
Title       : TX Driver
Project     :
Created     :
Description : Describes UART Trasmit Driver for UART UVC
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

`ifndef UART_TX_DRIVER
`define UART_TX_DRIVER

class uart_tx_driver extends uvm_driver #(uart_frame) ;

  // The virtual interface used to drive and view HDL signals.
  virtual interface uart_if vif;

  // handle to  a cfg class
  uart_config cfg;

  bit sample_clk;
  bit baud_clk;
  bit [15:0] ua_brgr;
  bit [7:0] ua_bdiv;
  int num_of_bits_sent;
  int num_frames_sent;

  // Provide implementations of virtual methods such as get_type_name and create
  `uvm_component_utils_begin(uart_tx_driver)
    `uvm_field_object(cfg, UVM_DEFAULT | UVM_REFERENCE)
    `uvm_field_int(sample_clk, UVM_DEFAULT + UVM_NOPRINT)
    `uvm_field_int(baud_clk, UVM_DEFAULT + UVM_NOPRINT)
    `uvm_field_int(ua_brgr, UVM_DEFAULT + UVM_NOPRINT)
    `uvm_field_int(ua_bdiv, UVM_DEFAULT + UVM_NOPRINT)
  `uvm_component_utils_end

  // Constructor - required UVM syntax
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  //added by huanglc at 20231125
  extern virtual task dump_sample_clk(ref bit sample_clk);

  // Additional class methods
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task reset();
  extern virtual task get_and_drive();
  extern virtual task gen_sample_rate(ref bit [15:0] ua_brgr, ref bit sample_clk);
  extern virtual task send_tx_frame(input uart_frame frame);
  extern virtual function void report_phase(uvm_phase phase);
  
endclass : uart_tx_driver

// UVM build_phase
function void uart_tx_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(cfg == null)
    begin
      if (!uvm_config_db#(uart_config)::get(this, "", "cfg", cfg))
       `uvm_error("NOCONFIG", "uart_config not set for this component")
    end
    else begin
        `uvm_info(get_type_name(),"cfg is not null", UVM_LOW);
    end
endfunction : build_phase

//UVM connect_phase
function void uart_tx_driver::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
   `uvm_error("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})

  if (uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
    `uvm_info(get_type_name(), "uart_if has got", UVM_LOW);
endfunction : connect_phase

//dump_sample_clk
task uart_tx_driver::dump_sample_clk(ref bit sample_clk);
    forever begin
        @(posedge vif.clock);
        vif.sample_clk = sample_clk;
    end
endtask

//UVM run_phase
task uart_tx_driver::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), 
        $sformatf("cfg.baud_rate_div = %0d, cfg.baud_rate_gen = %0d", cfg.baud_rate_div, cfg.baud_rate_gen), UVM_LOW)
  fork
    get_and_drive();
    gen_sample_rate(ua_brgr, sample_clk);
    dump_sample_clk(sample_clk);
  join
endtask : run_phase

// reset
task uart_tx_driver::reset();
  @(negedge vif.reset);
  `uvm_info(get_type_name(), "Reset Asserted", UVM_MEDIUM)
   vif.txd = 1;        //Transmit Data
   vif.rts_n = 0;      //Request to Send
   vif.dtr_n = 0;      //Data Terminal Ready
   vif.dcd_n = 0;      //Data Carrier Detect
   vif.baud_clk = 0;       //Baud Data
endtask : reset

//  get_and drive
task uart_tx_driver::get_and_drive();
  while (1) begin
    reset();
    fork
      @(negedge vif.reset)
        `uvm_info(get_type_name(), "Reset asserted", UVM_LOW)
    begin
      forever begin
        @(posedge vif.clock iff (vif.reset))
        /* https://www.francisz.cn/2019/07/18/sv-iff/
        @(posedge clk iff(vld));
        do_something;
    
        //this is equal to the following:
        forever begin
            @(posedge clk)
                if(vld) begin
                    do_something;
                end
        end                     
        //*/
        seq_item_port.get_next_item(req);
        send_tx_frame(req);
        seq_item_port.item_done();
      end
    end
    join_any
    disable fork;
    //If we are in the middle of a transfer, need to end the tx. Also,
    //do any reset cleanup here. The only way we got to this point is via
    //a reset.
    if(req.is_active()) this.end_tr(req);
  end
endtask : get_and_drive

task uart_tx_driver::gen_sample_rate(ref bit [15:0] ua_brgr, ref bit sample_clk);
  forever begin
    @(posedge vif.clock);
    if (!vif.reset) begin
      ua_brgr = 0;
      sample_clk = 0;
    end else begin
      if (ua_brgr == ({cfg.baud_rate_div, cfg.baud_rate_gen})) begin
        ua_brgr = 0;
        sample_clk = 1;
      end else begin
        sample_clk = 0;
        ua_brgr++;
      end
    end
  end   //forever begin
endtask : gen_sample_rate

// -------------------
// send_tx_frame
// -------------------
task uart_tx_driver::send_tx_frame(input uart_frame frame);
  bit [7:0] payload_byte;
  num_of_bits_sent = 0;

  `uvm_info(get_type_name(),
            $psprintf("Driver Sending TX Frame...\n%s", frame.sprint()),
            UVM_HIGH)
 
  repeat (frame.transmit_delay) @(posedge vif.clock);

  /*
其中使用void’的意义表示不考虑返回值。对于括号中有返回值的函数，加上void’操作符的意思就是告诉仿真器这个函数虽然有返回值，但是我不需要这个返回值。
加上这个的唯一好处是可以让仿真器闭嘴：本来函数有返回值，但是你不使用，这时仿真器会抛出警告。加上void’可以关闭警告，让仿真log更干净。
*/
  void'(this.begin_tr(frame));
   
  wait((!cfg.rts_en)||(!vif.cts_n));
  `uvm_info(get_type_name(), "Driver - Modem RTS or CTS asserted", UVM_HIGH)

  while (num_of_bits_sent <= (1 + cfg.char_len_val + cfg.parity_en + cfg.nbstop)) begin
    @(posedge vif.clock);
    #1;
    if (sample_clk) begin
      if (num_of_bits_sent == 0) begin
        // Start sending tx_frame with "start bit"
        vif.txd = frame.start_bit;
        `uvm_info(get_type_name(),
                  $psprintf("Driver Sending Frame SOP: %b", frame.start_bit),
                  UVM_HIGH)
      end
      if ((num_of_bits_sent > 0) && (num_of_bits_sent < (1 + cfg.char_len_val))) begin
        // sending "data bits" 
        payload_byte = frame.payload[num_of_bits_sent-1] ;
        vif.txd = frame.payload[num_of_bits_sent-1];
        `uvm_info(get_type_name(),
             $psprintf("Driver Sending Frame data bit number:%0d value:'b%b",
             (num_of_bits_sent-1), payload_byte), UVM_HIGH)
      end
      if ((num_of_bits_sent == (1 + cfg.char_len_val)) && (cfg.parity_en)) begin
        // sending "parity bit" if parity is enabled
        vif.txd = frame.calc_parity(cfg.char_len_val, cfg.parity_mode);
        `uvm_info(get_type_name(),
             $psprintf("Driver Sending Frame Parity bit:'b%b",
             frame.calc_parity(cfg.char_len_val, cfg.parity_mode)), UVM_HIGH)
      end
      if (num_of_bits_sent == (1 + cfg.char_len_val + cfg.parity_en)) begin
        // sending "stop/error bits"
        for (int i = 0; i < cfg.nbstop; i++) begin
          `uvm_info(get_type_name(),
               $psprintf("Driver Sending Frame Stop bit:'b%b",
               frame.stop_bits[i]), UVM_HIGH)
          wait (sample_clk);
          if (frame.error_bits[i]) begin
            vif.txd = 0;
            `uvm_info(get_type_name(),
                 $psprintf("Driver intensionally corrupting Stop bit since error_bits['b%b] is 'b%b", i, frame.error_bits[i]),
                 UVM_HIGH)
          end else
          vif.txd = frame.stop_bits[i];
          num_of_bits_sent++;
          wait (!sample_clk);
        end
      end
    num_of_bits_sent++;
    wait (!sample_clk);
    end
  end
  
  num_frames_sent++;
  `uvm_info(get_type_name(),
       $psprintf("Frame **%0d** Sent...", num_frames_sent), UVM_MEDIUM)
  wait (sample_clk);
  vif.txd = 1;

  `uvm_info(get_type_name(), "Frame complete...", UVM_MEDIUM)
  this.end_tr(frame);
   
endtask : send_tx_frame

//UVM report_phase
function void uart_tx_driver::report_phase(uvm_phase phase);
  `uvm_info(get_type_name(),
       $psprintf("UART Frames Sent:%0d", num_frames_sent),
       UVM_LOW )
endfunction : report_phase

`endif // UART_TX_DRIVER
