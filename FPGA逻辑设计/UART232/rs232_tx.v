module rx232_tx(
    input                 clk_ref            ,
    input         [ 7:0]  i_tx_dat           , 
    output                o_tx_pin           ,
    input                 rst_n              ,
    input                 i_tx_start_en      ,
    output                o_tx_send_over   
);
wire    [ 3:0]  ctrl_cnt       ;
wire            rs232_busy     ;

rs232_tx_dat u_rs232_tx_dat(
    .clk_ref           (clk_ref         ),
    .rst_n             (rst_n           ),
    .i_rs232_busy      (rs232_busy      ),//data_valid
    .i_tx_dat          (i_tx_dat        ),
    .o_tx_pin          (o_tx_pin        ),
    .i_ctrl_cnt        (ctrl_cnt        )
   
);


rs232_ctrl 
#(
	.CLK_REF     (100   ),    
	.BAUD_RATE   (115200) 
)
u_rs232_ctrl
(
    .clk_ref           (clk_ref          ),
    .rst_n             (rst_n            ),
    .i_rs232_start_en  (i_tx_start_en    ), // rs232 开始标志使能
    .o_rs232_cfg_over  (o_tx_send_over   ),
    .o_ctrl_cnt        (ctrl_cnt         ),
    .o_rs232_busy      (rs232_busy       )

);
endmodule
