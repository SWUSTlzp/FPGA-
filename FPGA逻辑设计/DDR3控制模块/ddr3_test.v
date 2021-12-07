module ddr3_test#
(

        parameter   ADDR_WIDTH   =  27 ,
        parameter   DATA_WIDTH   =  512
)
(
    input                           rst_n               ,  //上电复位// 
    input                           i_clkin_100mhz      , 
    output                          o_ddr_clk           , //usr_clk
    //----------------ddr3_c0---------//
    // input
    input                           oct_rzqin           ,
    // Inouts
    inout [63:0]                    ddr3_dq             ,
    inout [7:0]                     ddr3_dqs_n          ,
    inout [7:0]                     ddr3_dqs_p          ,  
    // Outputs                                          
    output [15:0]                   ddr3_addr           ,
    output [2:0]                    ddr3_ba             ,
    output                          ddr3_ras_n          ,
    output                          ddr3_cas_n          ,
    output                          ddr3_we_n           ,
    output                          ddr3_reset_n        ,
    output [1:0]                    ddr3_ck_p           ,//ddr3 width 0
    output [1:0]                    ddr3_ck_n           ,//ddr3 width 0
    output [1:0]                    ddr3_cke            ,//ddr3 width 0
    output [1:0]                    ddr3_cs_n           ,//ddr3 width 0
    output [7:0]                    ddr3_dm             ,
    output [1:0]                    ddr3_odt             //ddr3 width 0

);

wire              ddr_clk             ;
wire              app_rst_n           ;
wire              int_done            ;
wire              app_busy            ;
wire              wr_ireq             ;
wire    [15:0]    wr_len              ;
wire    [26:0]    wr_addr             ;
wire    [511:0]   wr_dat              ;
wire              rd_ireq             ;
wire    [15:0]    rd_len              ;
wire    [26:0]    rd_addr             ;
wire              app_rd_en           ;
wire    [26:0]    app_addr            ;
wire              app_rdy             ;
wire              app_rd_data_valid   ;
wire              app_wdf_wren        ;
wire    [511:0]   app_wdf_data        ;
wire    [511:0]   app_rd_data         ;     
wire    [ 6:0]    app_burstcount      ;
wire    [63:0]    app_byteenable      ;

assign  o_ddr_clk       = ddr_clk     ;

ddr3_dat_gen u_ddr3_dat_gen
(
//wr_addr/rd_addr:改变地址的起始
    .rst_n                      (rst_n            ),
    .ddr_clk                    (ddr_clk          ),
    .i_int_done                 (int_done         ),
    .o_wr_ireq                  (wr_ireq          ),
    .o_wr_len                   (wr_len           ),//fixed
    .o_wr_addr                  (wr_addr          ),
    .o_wr_dat                   (wr_dat           ),
    .o_rd_ireq                  (rd_ireq          ),
    .o_rd_len                   (rd_len           ),//fixed
    .o_rd_addr                  (rd_addr          ),
    .i_wr_den                   (wr_den           ),
    .app_rdy                    (app_rdy          ),
    .app_rd_data                (app_rd_data      ),
    .app_burstcount             (app_burstcount   ),
    .app_byteenable             (app_byteenable   ),
    .app_rd_data_valid          (app_rd_data_valid)
);

ddr3_user_app_v1_module #
(
    .ADDR_WIDTH                 (ADDR_WIDTH),
    .DATA_WIDTH                 (DATA_WIDTH)
)
u_ddr3_n0_app_module
(
    .ddr_clk                    (ddr_clk                ),
    .rst_n                      (rst_n                  ),
//USER APP//                                            
    .i_wr_ireq                  (wr_ireq                ),
    .i_wr_len                   (wr_len                 ), //数据位宽的个数
    .i_wr_addr                  (wr_addr                ),
    .o_wr_den                   (wr_den                 ),
    .i_wr_dat                   (wr_dat                 ),
    .i_rd_ireq                  (rd_ireq                ),
    .i_rd_len                   (rd_len                 ),//数据位宽的个数
    .i_rd_addr                  (rd_addr                ),
    .o_app_busy                 (app_busy               ),
//user interface//                                      
    .app_rst                    (~app_rst_n             ),
    .init_calib_complete        (int_done               ),
    .app_addr                   (app_addr               ),
//    .app_cmd                    (app_cmd                 ),
//    .app_en                     (app_en                  ),
    .app_rdy                    (app_rdy                ),
    .app_rd_data_valid          (app_rd_data_valid      ),
    .app_wdf_wren               (app_wdf_wren           ),
    .app_wdf_data               (app_wdf_data           ),
//    .app_wdf_end                (app_wdf_end            ),  
//    .app_wdf_mask               (app_wdf_mask           ), // disable
//    .app_wdf_rdy                (app_wdf_rdy            ),
    .app_rd_en                  (app_rd_en              )
);   
//
//=== DDR3-core ===//  
ddr3_ip u_ddr3_core(
	.global_reset_n             (rst_n                  ),      //   input,    width = 1,   global_reset_n.reset_n
	.pll_ref_clk                (i_clkin_100mhz         ),         //   input,    width = 1,      pll_ref_clk.clk
	.oct_rzqin                  (oct_rzqin              ),           //   input,    width = 1,              oct.oct_rzqin
	.mem_ck                     (ddr3_ck_p              ),              //  output,    width = 2,              mem.mem_ck
	.mem_ck_n                   (ddr3_ck_n              ),            //  output,    width = 2,                 .mem_ck_n
	.mem_a                      (ddr3_addr              ),               //  output,   width = 16,                 .mem_a
	.mem_ba                     (ddr3_ba                ),              //  output,    width = 3,                 .mem_ba
	.mem_cke                    (ddr3_cke               ),             //  output,    width = 2,                 .mem_cke
	.mem_cs_n                   (ddr3_cs_n              ),            //  output,    width = 2,                 .mem_cs_n
	.mem_odt                    (ddr3_odt               ),             //  output,    width = 2,                 .mem_odt
	.mem_reset_n                (ddr3_reset_n           ),         //  output,    width = 1,                 .mem_reset_n
	.mem_we_n                   (ddr3_we_n              ),            //  output,    width = 1,                 .mem_we_n
	.mem_ras_n                  (ddr3_ras_n             ),           //  output,    width = 1,                 .mem_ras_n
	.mem_cas_n                  (ddr3_cas_n             ),           //  output,    width = 1,                 .mem_cas_n
	.mem_dqs                    (ddr3_dqs_p             ),             //   inout,    width = 8,                 .mem_dqs
	.mem_dqs_n                  (ddr3_dqs_n             ),           //   inout,    width = 8,                 .mem_dqs_n
	.mem_dq                     (ddr3_dq                ),              //   inout,   width = 64,                 .mem_dq
	.mem_dm                     (ddr3_dm                ),              //  output,    width = 8,                 .mem_dm
	.local_cal_success          (int_done               ),   //  output,    width = 1,           status.local_cal_success
	.local_cal_fail             (),                          //  output,    width = 1,                 .local_cal_fail
//initial_over                  
	.emif_usr_reset_n           (app_rst_n              ),    //  output,    width = 1, emif_usr_reset_n.reset_n
	.emif_usr_clk               (ddr_clk                ),        //  output,    width = 1,     emif_usr_clk.clk            
//user_interface                
    .amm_ready_0                (app_rdy                ),         //  output,    width = 1,       ctrl_amm_0.waitrequest_n	                            
    .amm_read_0                 (app_rd_en              ),          //   input,    width = 1,                 .read
	.amm_write_0                (app_wdf_wren           ),         //   input,    width = 1,                 .write	                            
    .amm_address_0              (app_addr               ),       //   input,   width = 27,                 .address
    .amm_readdata_0             (app_rd_data            ),      //  output,  width = 512,                 .readdata
	.amm_writedata_0            (app_wdf_data           ),     //   input,  width = 512,                 .writedata
	.amm_burstcount_0           (app_burstcount         ),    //   input,    width = 7,                 .burstcount
	.amm_byteenable_0           (app_byteenable         ),    //   input,   width = 64,                 .byteenable
    .amm_readdatavalid_0        (app_rd_data_valid      )  //  output,    width = 1,                 .readdatavalid
	);


endmodule
