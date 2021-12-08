`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/15 11:21:51
// Design Name: 
// Module Name: tb_iic_test
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


module tb_iic_test();


reg                         sys_clk         ;  //100M
reg                         rst_n           ;
reg              [31:0]     i_cfg_dat       ; 
reg                         i_cfg_start_en  ;
wire                        iic_sda         ;
wire                        iic_scl         ;

iic_test u_iic_test(
    .sys_clk                    (sys_clk        ),  //100M
    .rst_n                      (rst_n          ),
    .i_cfg_dat                  (i_cfg_dat      ), 
    .i_cfg_start_en             (i_cfg_start_en ),
    .iic_scl                    (iic_scl        ),
    .iic_sda                    (iic_sda        ),
    .o_rd_dat                   (       )
);

initial begin
    sys_clk         = 'd0;
    rst_n           = 1'b0;
    i_cfg_start_en  = 'd0;
    i_cfg_dat       = 32'b1010_1110_1110_0110_1010_1101_1110_0001;
    #100 
    rst_n           = 1'b1;
    #10
    i_cfg_start_en  = 'd1;
    #10
    i_cfg_start_en  = 'd0;
    #700000
    i_cfg_dat       = 32'b1010_1110_1110_0110_0000_0000_1010_0101;
    #10
    i_cfg_start_en  = 'd1;
    #10
    i_cfg_start_en  = 'd0;
    #700000
    i_cfg_dat       = 32'b1010_1110_1110_0110_1010_1101_1110_0001;
    #10
    i_cfg_start_en  = 'd1;
    #10
    i_cfg_start_en  = 'd0;
end
always #5 sys_clk = ~sys_clk;

endmodule
