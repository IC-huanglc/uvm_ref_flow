//This is dummy DUT. 

module dut_dummy( input clock, input reset, uart_if uart_if0);

//the following is added by huanglc
  wire clk;
  wire rst;

  wire txd;    // Transmit Data
  wire rxd;    // Receive Data
  
  wire intrpt;  // Interrupt

  wire ri_n;    // ring indicator
  wire cts_n;   // clear to send
  wire dsr_n;   // data set ready
  wire rts_n;   // request to send
  wire dtr_n;   // data terminal ready
  wire dcd_n;   // data carrier detect

  wire baud_clk;  // Baud Rate Clock
  
  //added by haunglc at 20231125
  wire sample_clk;
//////////////////////////////////////
  assign txd = uart_if.txd;     // Transmit Data
  assign rxd = uart_if.rxd;     // Receive Data
  
  assign intrpt = uart_if.intrpt;   // Interrupt

  assign ri_n = uart_if.ri_n;     // ring indicator
  assign cts_n = uart_if.cts_n;    // clear to send
  assign dsr_n = uart_if.dsr_n;    // data set ready
  assign rts_n = uart_if.rts_n;    // request to send
  assign dtr_n = uart_if.dtr_n;    // data terminal ready
  assign dcd_n = uart_if.dcd_n;    // data carrier detect

  assign baud_clk = uart_if.baud_clk;   // Baud Rate Clock

  assign sample_clk = uart_if.sample_clk;



endmodule

 
