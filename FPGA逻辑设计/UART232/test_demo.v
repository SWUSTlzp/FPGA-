`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/08 15:45:56
// Design Name: 
// Module Name: test_demo
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


module test_demo(
//tx
   input                   clk_ref          ,
   output                  o_tx_pin         ,
   input                   rst_n            ,
   input                   i_rx_pin         ,  
   output                  o_rx_over  
);
reg   [7:0]  tx_dat;
reg          tx_en;
rs232_top u_rs232_top(
        .clk_ref          (clk_ref  ),
        .i_tx_dat         (tx_dat   ),
        .o_tx_pin         (o_tx_pin ),
        .rst_n            (rst_n    ),
        .i_tx_en          (tx_en    ),
        .o_tx_over        (o_tx_over),//
        .o_rx_over        (o_rx_over),//
        .i_rx_pin         (i_rx_pin )
);

//reg      [ 3:0]     cnt;
//wire                add_cnt;
//wire                end_cnt;
//always @(posedge clk or negedge rst_n)begin
//        if(!rst_n)begin
//            cnt <= 'd0;
//    end
//    else if(add_cnt)begin
//        if(end_cnt)
//            cnt <= 'd0;
//    else
//            cnt <= cnt + 1'b1;
//end
//end
//
//assign add_cnt = 1'b1;       
//assign end_cnt = add_cnt && cnt == 2000 - 1;
//
//always@(posedge clk_ref or negedge rst_n)begin
//       if(!rst_n)begin
//            tx_dat <= 'd0;
//            tx_en  <= 1'b0;
//       end
//       else begin
//            if(end_cnt == 1'b1)begin              
//                tx_dat <= tx_dat + 1'b1;
//                tx_en  <= 1'b1;
//            end
//            else begin
//                tx_dat <= tx_dat;
//                tx_en  <= 1'b0;
//            end               
//       end
//end
//
endmodule
