`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/19 14:09:38
// Design Name: 
// Module Name: ads42_ctrl_top
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


module ads42_ctrl_top(
input                       sys_clk         ,
input                       rst_n           ,
input                       i_pll_locked    ,
output                      o_over_finish   ,
input                       i_cha_volt_sel  , 
input                       i_chb_volt_sel  ,

input                       i_ad_clk        ,                                    
input [15:0]                i_ad_din        , 


output                      o_ad_reset      ,
output                      o_ad_cs_n       ,
output                      o_ad_spi_clk    ,
output                      o_ad_mosi       ,
input                       i_ad_miso       
    );
    
    
wire[15:0]                  dat_in          ;
wire                        opt_start       ;
wire[7:0 ]                  opt_cnt         ;
                                
wire[7:0]                   dat_out         ;
wire                        dat_vaild       ;
wire                        spi_done        ;

//--cal--//
wire[3:0]                   ad_mode         ;  //0100 闁帒顤冮弫甯礉0000濮濓絽鐖跺Ο鈥崇础//
wire[2:0]                   ad_dly          ;
wire                        ad_cal_start    ;
wire                        ad_cal_finish   ;
wire                        ad_cal_over     ;
wire                        ad_inital_over  ;    
                     
ad_cal_bk  u_ad_cal_bk
(
    .sys_clk                (sys_clk),
    .rst_n                  (rst_n),
    
    .i_ad_inital_over       (ad_inital_over),                                                                                                                                           
    .o_ad_mode              (ad_mode),
    .o_ad_dly               (ad_dly),
    .o_ad_cal_start         (ad_cal_start),
    .o_ad_cal_finish        (ad_cal_finish),
    .i_ad_cal_over          (ad_cal_over),

    .ad_clk                 (i_ad_clk),                                    
    .s_dout_ch0             (i_ad_din)
); 

ads42_ctrl_bk  u_ads42_ctrl_bk
(
    .sys_clk                (sys_clk     ),
    .rst_n                  (rst_n       ),
    .i_pll_locked           (i_pll_locked),
    
   // .i_ad_mode              (ad_mode        ),  //0100 闁帒顤冮弫甯礉0000濮濓絽鐖跺Ο鈥崇础//
    .i_ad_mode              ('b0011        ),  //0100 闁帒顤冮弫甯礉0000濮濓絽鐖跺Ο鈥崇础//
    //.i_ad_dly               (ad_dly         ),
    .i_ad_dly               ('d7      ),
	 .i_ad_cal_start         (ad_cal_start   ),
    
    .i_cha_volt_sel         (i_cha_volt_sel),
    .i_chb_volt_sel         (i_chb_volt_sel),
    //.i_ad_cal_finish        (ad_cal_finish  ),
    .i_ad_cal_finish        (1'b1  ),
    .o_ad_cal_over          (ad_cal_over    ),
    .o_ad_inital_over       (ad_inital_over ),                         
                                
    .o_dat_in               (dat_in     ),
    .o_opt_start            (opt_start  ),
    .o_opt_cnt              (opt_cnt    ),
                           
    .i_dat_out              (dat_out    ),
    .i_dat_vaild            (dat_vaild  ),
    .i_spi_done             (spi_done   ),
    .o_ad_reset             (o_ad_reset   ),
                           
    .o_over_finish          (o_over_finish)
    );
    
ads42_spi_master #  //娑撳妾峰▽鎸庨儴閸欐ɑ鏆熼敍灞肩瑐閸楀洦閮ㄩ柌鍥ㄦ殶//
(
    .DATA_WITH              (16)        ,
    .RDATA_WITH             (8 )        ,
    .MID_CNT                (9 )        , //娑擃參妫块崐    
	 .END_CNT                (19 )        //閺堚偓婢5
)
    u_ads42_spi_master
(
    .sys_clk                (sys_clk),  //100mhz
    .rst_n                  (rst_n),
    .i_dat_in               (dat_in   ),
    .i_opt_start            (opt_start),
    .i_opt_cnt              (opt_cnt  ),
    .o_dat_out              (dat_out  ),
    .o_dat_vaild            (dat_vaild),
    .o_spi_done             (spi_done ),
    //spi_interface//     
    .o_cs_n                 (o_ad_cs_n    ),
    .o_spi_clk              (o_ad_spi_clk ),
    .o_mosi                 (o_ad_mosi    ),
    .i_miso                 (i_ad_miso    )   
);
endmodule
