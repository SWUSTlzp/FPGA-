module top (
        input                     sys_100M           ,
//       output        [15:0]      o_c1_adi_dout      ,
//       output        [15:0]      o_c1_adq_dout      ,
        input                     i_ad_clk_p         ,
        input                     i_ad_clk_n         ,
        input         [7:0]       i_adi_din_p        ,
        input         [7:0]       i_adi_din_n        ,
        input         [7:0]       i_adq_din_p        ,
        input         [7:0]       i_adq_din_n        ,
        output                    o_ad_ctrl1         ,
        output                    o_ad_ctrl2         ,
        output                    o_ad_sync          ,
                                                     
        output                    o_ad_reset         ,
        output                    o_ad_sen           ,
        output                    o_ad_spi_clk       ,
        output                    o_ad_mosi          ,
        input                     i_ad_miso          
);

wire            pll_locked  ;
wire            io_reset    ;
wire            grst_n      ;
wire            ad_sync     ;
wire            pll_100mhz  ;
wire            pll_200mhz  ;    
(*noprune*) wire            ad_clkout   ;         
(*noprune*) wire   [15:0]   adi_dout    ;
(*noprune*) wire            adi_dout_v  ;
(*noprune*) wire   [15:0]   adq_dout    ;
(*noprune*) wire            adq_dout_v  ;
wire [15:0]      o_c1_adi_dout ;                
wire [15:0]      o_c1_adq_dout ;                
assign          o_ad_sync = ad_sync;
assign          io_reset  = ~pll_locked;

reg [7:0]   adi_din_p;
reg [7:0]   adi_din_n;
reg [7:0]   adq_din_p;
reg [7:0]   adq_din_n;

ad_top_v1 u_ad_top_v1(
			.sys_clk        (pll_100mhz  ),
			.rst_n          (grst_n      ),
			.i_pll_locked   (pll_locked  ), 
			.i_io_reset     (io_reset    ),
            //ADC CLK
			.o_ad_clkout    (ad_clkout   ),//
            //ADC dataout
			.o_adi_dout     (adi_dout    ),//
			.o_adi_dout_vl  (adi_dout_v  ),//
			.o_adq_dout     (adq_dout    ),//
			.o_adq_dout_vl  (adq_dout_v  ),//
            //ADC clkin
			.i_ad_clk_p     (i_ad_clk_p  ),//
			.i_ad_clk_n     (i_ad_clk_n  ),//
            //ADC datain
			.i_adi_din_p    (i_adi_din_p ),//
			.i_adi_din_n    (i_adi_din_n ),//
			.i_adq_din_p    (i_adq_din_p ),//
			.i_adq_din_n    (i_adq_din_n ),//
            //flag
			.o_cfg_over     (o_cfg_over  ),//
            //ADC signals
			.o_ad_ctrl1     (o_ad_ctrl1  ),//
			.o_ad_ctrl2     (o_ad_ctrl2  ),//
			.o_ad_sync_p    (  ),//
			.o_ad_sync_n    (  ),//
            //ADC SPI
			.o_ad_reset     (o_ad_reset  ),//
			.o_ad_cs_n      (o_ad_sen    ),//
			.o_ad_spi_clk   (o_ad_spi_clk),//
			.o_ad_mosi      (o_ad_mosi   ),//
			.i_ad_miso      (i_ad_miso   )//
     
);


iopll_ip u_iopll_ip (
	.rst                    (~grst_n     ),      //   input,  width = 1,   reset.reset
	.refclk                 (sys_100M    ),   //   input,  width = 1,  refclk.clk
	.locked                 (pll_locked  ),   //  output,  width = 1,  locked.export
	.outclk_0               (pll_100mhz  ), //  output,  width = 1, outclk0.clk
	.outclk_1               (pll_200mhz  )  //  output,  width = 1, outclk1.clk
);

grst_ctl u_grst_ctl(

    .sys_100M               (sys_100M    ),
    .o_grst_n               (grst_n      )
);  



data_sync_bk u_data_sync_bk
(
    .rst_n              (adi_dout_v    ), //pll 闂傚倸鍊烽悞锕€顭垮Ο鑲╃煋闁割偅娲橀崑顏堟煕閳╁啰鎲块柛瀣崌閹兘鎮ч崼鐔稿闂備焦鎮堕崝宥呯暆閸涘﹣绻嗛柟缁㈠枛绾惧吋淇婇姘Щ濞),
    .o_sync_out         (ad_sync       ),   
    .i_ad_gclk          (ad_clkout     ),
    .i_c1_ad_clk        (ad_clkout     ),
    .i_c1_adi_din       (adi_dout      ),
    .i_c1_adq_din       (adq_dout      ),
    .i_c1_ad_din_vl     (adi_dout_v    ),
    .o_c1_adi_dout      (o_c1_adi_dout ),
    .o_c1_adq_dout      (o_c1_adq_dout ),
    .o_dout_vl          (o_ad_dout_vl  )
);





endmodule 