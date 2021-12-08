`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/07 09:31:01
// Design Name: 
// Module Name: tb_rs232
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


module tb_rs232();

reg                 clk_ref          ;
reg         [ 7:0]  i_tx_dat         ;
wire                o_tx_pin         ;
reg                 rst_n            ;
reg                 i_tx_start_en    ; // rs232 开始标志使能 
wire                o_tx_send_over   ;
    
rx232_tx u_rx232_tx(
    .clk_ref           (clk_ref         ),
    .i_tx_dat          (i_tx_dat        ),
    .o_tx_pin          (o_tx_pin        ),
    .rst_n             (rst_n           ),
    .i_tx_start_en     (i_tx_start_en   ),// rs232 开始标志使能
    .o_tx_send_over    (o_tx_send_over  )
);
initial begin
    clk_ref = 1'b0;
    rst_n   = 1'b0;
    i_tx_start_en = 1'b0;
    i_tx_dat = 'd0;
    #10
    rst_n   = 1'b1;
    #20
    i_tx_start_en = 1'b1;
    i_tx_dat = 8'b1010_1010;
    #20
    i_tx_start_en = 1'b0;
    #300000
    i_tx_start_en = 1'b1;
    i_tx_dat = 8'b1011_1000;
    #20
    i_tx_start_en = 1'b0;
    repeat(100)begin
        #300000
        i_tx_start_en = 1'b1;
        i_tx_dat = 8'b0011_1011;
        #20
        i_tx_start_en = 1'b0;
    end
end

always #10 clk_ref = ~clk_ref;

endmodule
