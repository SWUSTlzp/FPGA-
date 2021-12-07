`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/08 13:48:02
// Design Name: 
// Module Name: ad_top
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


module ad_top_v1 (

input           sys_clk         ,//100M
input           rst_n           ,
input           i_pll_locked    , //pll 闂佹澘绉堕悿鍡欌偓鐟版湰閸ㄦ岸濡撮崒妯峰亾-//
input           i_io_reset      ,
//---ad if to if--------//
output          o_ad_clkout     ,
output  [15:0]  o_adi_dout      ,
output          o_adi_dout_vl   ,
output  [15:0]  o_adq_dout      ,
output          o_adq_dout_vl   ,
//----ad--signals------//
input           i_ad_clk_p      ,
input           i_ad_clk_n      ,
input[7:0]      i_adi_din_p     ,
input[7:0]      i_adi_din_n     ,
input[7:0]      i_adq_din_p     ,
input[7:0]      i_adq_din_n     ,
//---spi--//
output          o_cfg_over      ,
output          o_ad_ctrl1      ,
output          o_ad_ctrl2      ,
output          o_ad_sync_p     ,
output          o_ad_sync_n     ,
output          o_ad_reset      ,
output          o_ad_cs_n       ,
output          o_ad_spi_clk    ,
output          o_ad_mosi       ,
input           i_ad_miso  
     
);
	 
wire            adclk           ;
wire[15:0]      adi_dat         ;
wire[15:0]      adq_dat         ;
reg [15:0]      adi_dat_reg     ;
reg [15:0]      adq_dat_reg     ;
wire            cal_finish      ;
reg             ad_vl           ;
wire            adclk_dly       ;
//---ff--//
wire[31:0]      ff_dout         ;
assign o_ad_clkout  = adclk	  ;
assign o_adi_dout   = ff_dout[15:0]   ;
assign o_adi_dout_vl= ad_vl     ;
assign o_adq_dout   = ff_dout[31:16]  ;
assign o_adq_dout_vl= ad_vl     ;

assign  o_cfg_over = cal_finish ;


assign  o_ad_ctrl1      = 'b0   ;
assign  o_ad_ctrl2      = 'b0   ;

gpio_differ u_gpio_differ(
		.dout     (adclk				),     //  output,  width = 1,     dout.export
		.pad_in   (i_ad_clk_p		),   //   input,  width = 1,   pad_in.export
		.pad_in_b (i_ad_clk_n		)  //   input,  width = 1, pad_in_b.export
	);


always@(posedge adclk)
begin
    ad_vl <= cal_finish ;
end
adio_bk u_chi_adio_bk
(
    .din_p              (i_adi_din_p),
    .din_n              (i_adi_din_n),
    .io_reset           (i_io_reset),
    .clkin_sys          (adclk),
    .clkin_bufr         (adclk),
    .o_dout_pin         (adi_dat)
); 
adio_bk u_chq_adio_bk
(
    .din_p              (i_adq_din_p),
    .din_n              (i_adq_din_n),
    .io_reset           (i_io_reset),
    .clkin_sys          (adclk),
    .clkin_bufr         (adclk),
    .o_dout_pin         (adq_dat)
);
ads42_ctrl_top u_ad_ctrl_top
(
    .sys_clk            (sys_clk),
    .rst_n              (rst_n),                
    .i_pll_locked       (i_pll_locked),
    .o_over_finish      (cal_finish),

    .i_ad_clk           (adclk),                                    
    .i_ad_din           (ff_dout[15:0]), 
    .i_cha_volt_sel     (1'b1			  ),
	 .i_chb_volt_sel     (1'b1			  ),
    .o_ad_reset         (o_ad_reset   ),
    .o_ad_cs_n          (o_ad_cs_n    ),
    .o_ad_spi_clk       (o_ad_spi_clk ),
    .o_ad_mosi          (o_ad_mosi    ),
    .i_ad_miso          (i_ad_miso    )
);


always@(posedge adclk )
begin
    adq_dat_reg <= adq_dat;  
    adi_dat_reg <= adi_dat;
end

rff_i32o32d1k u_rff_i32o32d1k (
		.data  ({adq_dat_reg,adi_dat_reg}),  //   input,  width = 32,  fifo_input.datain
		.wrreq (1'b1), 		//   input,  width = 1,            .wrreq
		.rdreq (1'b1), 		//   input,  width = 1,            .rdreq
		.wrclk (adclk),		 //   input,  width = 32,            .wrclk
		.rdclk (adclk),		 //   input,  width = 32,            .rdclk
		.aclr  ((i_io_reset)),  //   input,  width = 1,            .aclr
		.q     (ff_dout)      //  output,  width = 2, fifo_output.dataout
	);

endmodule
