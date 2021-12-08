`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/08 11:22:15
// Design Name: 
// Module Name: rs232_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rs232_rx(
//ctrl
   input                   clk_ref          ,
   input                   rst_n            ,
   output                  o_rx_cfg_over    ,
//rx_dat  
   input                   i_rx_pin     
);
    
wire     [ 3:0]     ctrl_cnt;    
wire                rs232_busy;
rs232_ctrl
#(
	.CLK_REF  (100   ),      //clock frequency(Mhz)
	.BAUD_RATE(115200) //serial baud rate
)
u_rs232_ctrl
(
    .clk_ref          (clk_ref      ),
    .rst_n            (rst_n        ),
    .i_rs232_start_en (rx_start_en  ), // rs232 开始标志使能
    .o_rs232_cfg_over (o_rx_cfg_over),
    .o_ctrl_cnt       (ctrl_cnt     ),
    .o_rs232_busy     (rs232_busy   )

   
);  

rs232_rx_dat u_rs232_rx_dat(
  .clk_ref            (clk_ref      ),
  .rst_n              (rst_n        ),
  .i_rs232_busy       (rs232_busy   ),
  .i_rx_pin           (i_rx_pin     ),
  .i_ctrl_cnt         (ctrl_cnt     ),
  .o_rx_start_en      (rx_start_en  )
   
);  
endmodule
