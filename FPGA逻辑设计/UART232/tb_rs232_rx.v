`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/08 14:50:42
// Design Name: 
// Module Name: tb_rs232_rx
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


module tb_rs232_rx();


reg     clk_ref;
reg     rst_n;
wire    o_rx_cfg_over;
reg     i_rx_pin;
rs232_rx u_rs232_rx(
//ctrl
   .clk_ref          (clk_ref      ),
   .rst_n            (rst_n        ),
   .o_rx_cfg_over    (o_rx_cfg_over),
//rx_dat             
   .i_rx_pin         (i_rx_pin      )
);

initial begin
    i_rx_pin = 1'b1;
    rst_n = 1'b0;
    clk_ref = 1'b0;
    #100
    rst_n = 1'b1;
    
    #17300
    i_rx_pin = 1'b0;
    
    #17000
    i_rx_pin = 1'b1;

    #17500
    i_rx_pin = 1'b0;
end

always #5 clk_ref = ~clk_ref;

endmodule
