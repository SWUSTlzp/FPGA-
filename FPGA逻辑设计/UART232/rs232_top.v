`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/08 15:08:04
// Design Name: 
// Module Name: rs232_top
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


module rs232_top(
//tx
   input                   clk_ref          ,
   input       [ 7:0]      i_tx_dat         ,
   output                  o_tx_pin         ,
   input                   rst_n            ,
   input                   i_tx_en          ,
   output                  o_tx_over        ,//
//rx
   output                  o_rx_over        ,//
   input                   i_rx_pin     
);


rs232_rx u_rs232_rx(
       .clk_ref          (clk_ref      ),
       .rst_n            (rst_n        ),
       .o_rx_cfg_over    (o_rx_over    ), 
       .i_rx_pin         (i_rx_pin     )
);

rx232_tx u_rx232_tx(
       .clk_ref          (clk_ref       ),
       .i_tx_dat         (i_tx_dat      ), 
       .o_tx_pin         (o_tx_pin      ),
       .rst_n            (rst_n         ),
       .i_tx_start_en    (i_tx_en       ),
       .o_tx_send_over   (o_tx_over     )
);
endmodule
