`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:26:36 10/27/2017 
// Design Name: 
// Module Name:    adio_bk 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module adio_bk(
input[7:0]      din_p           ,
input[7:0]      din_n           ,
input           io_reset        ,
input           clkin_sys       ,
input           clkin_bufr      ,

output [15:0]   o_dout_pin      

 );
wire[7:0]   data_in_n0      ;
wire[7:0]   data_in_n1      ;
reg [15:0]  ad_dat        ;
wire[15:0]  ad_ndc        ;

assign o_dout_pin = ad_ndc;


gpio_ddio8_ip u_gpio_ddio8_ip (
		.ck        (clkin_sys	),        //   input,  width = 1,        ck.export
		.dataout_h (data_in_n0	), //  output,  width = 8, dataout_h.fragment
		.dataout_l (data_in_n1	), //  output,  width = 8, dataout_l.fragment
		.datain    (din_p			),    //   input,  width = 8,    pad_in.export
		.pad_in_b  (din_n			),  //   input,  width = 8,  pad_in_b.export
		.aset      (io_reset		)       //   input,  width = 1,      aset.export
	);



always@(posedge clkin_bufr)
begin
        ad_dat   <= {  data_in_n0[7],data_in_n1[7],
                       data_in_n0[6],data_in_n1[6],
                       data_in_n0[5],data_in_n1[5],
                       data_in_n0[4],data_in_n1[4],
                       data_in_n0[3],data_in_n1[3],
                       data_in_n0[2],data_in_n1[2],
                       data_in_n0[1],data_in_n1[1],
                       data_in_n0[0],data_in_n1[0]}; 
end


mult_add_demo u_mult_add_demo(
    .clk        (clkin_bufr),
    .rst        (io_reset),
    .ad_din     (ad_dat  ),
    .ad_ndc     (ad_ndc  )
);









endmodule
