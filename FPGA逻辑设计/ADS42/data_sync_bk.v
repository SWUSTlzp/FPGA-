`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/01/26 10:55:53
// Design Name: 
// Module Name: data_sync_bk
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


module data_sync_bk(
input               rst_n               , 
output              o_sync_out          ,        
                                      
input               i_ad_gclk           ,
                                      
input               i_c1_ad_clk         ,//
input[15:0]         i_c1_adi_din        ,//
input[15:0]         i_c1_adq_din        ,//
input               i_c1_ad_din_vl      ,
                           
output[15:0]        o_c1_adi_dout       ,
output[15:0]        o_c1_adq_dout       ,
output              o_dout_vl     

    );
reg[31:0]           sync_shift          ;
wire                sync_shift_in       ;
reg                 sync_out            ;


reg[15:0]           c1_adi_din          ;
reg[15:0]           c1_adq_din          ;
reg                 c1_ad_din_vl        ;
                           
//---ff1---//
reg                 ff_rden             ;
wire[31:0]          ff1_dout            ;
reg                 ff1_prog_empty      ;

reg[15:0]           c1_adi_dout         ;
reg[15:0]           c1_adq_dout         ;

reg                 dout_vl             ;
wire      [ 9:0]    wusedw              ;



assign  sync_shift_in = i_c1_ad_din_vl  ;
assign  o_sync_out    = sync_out ;

assign  o_c1_adi_dout = c1_adi_dout;
assign  o_c1_adq_dout = c1_adq_dout;

assign  o_dout_vl     = dout_vl    ;


always@(posedge i_ad_gclk or negedge rst_n)
begin
    if(!rst_n)
        begin
            sync_shift <= 'b0;
        end
    else
        begin
            sync_shift <= {sync_shift[30:0],sync_shift_in}  ;
        end
end
always@(posedge i_ad_gclk or negedge rst_n)
begin
    if(!rst_n)
        begin
            sync_out <= 'b0;
        end
    else
        begin
            if((~sync_shift[31]) && sync_shift[2])
                sync_out <= 'b1;
            else
                sync_out <= 'b0;
        end
end
always@(posedge i_ad_gclk or negedge rst_n)
begin
    if(!rst_n)
        begin
            ff1_prog_empty <= 'b0;
        end
    else begin
            if(wusedw < 'd10)
                ff1_prog_empty <= 1'b1;
			   else 
				    ff1_prog_empty <= 1'b0;
					 
    end
            
end

//---c1---//
always@( posedge i_c1_ad_clk  or negedge rst_n)
begin
    if(!rst_n)
        begin
            c1_ad_din_vl <= 'b0;
            c1_adi_din   <= 'b0;
            c1_adq_din   <= 'b0;
        end
    else
        begin
            c1_ad_din_vl <= i_c1_ad_din_vl;
            c1_adi_din   <= i_c1_adi_din;
            c1_adq_din   <= i_c1_adq_din;
        end
end
sff_i32o32d1k u_sff_i32o32d1k (
		.data    ({c1_adq_din,c1_adi_din}),    //   input,  width = 32,  fifo_input.datain
		.wrreq   (c1_ad_din_vl           ),   //   input,   width = 1,            .wrreq
		.rdreq   (ff_rden                ),   //   input,   width = 1,            .rdreq
		.wrclk   (i_c1_ad_clk            ),   //   input,   width = 1,            .wrclk
		.rdclk   (i_ad_gclk              ),   //   input,   width = 1,            .rdclk
		.aclr    (~rst_n                 ),    //   input,   width = 1,            .aclr
		.q       (ff1_dout               ),       //  output,  width = 32, fifo_output.dataout
		.wrusedw (wusedw                 ), //  output,  width = 10,            .wrusedw
		.rdfull  (),  //  output,   width = 1,            .rdfull
		.wrfull  ()   //  output,   width = 1,            .wrfull
	);



always@(posedge i_ad_gclk or negedge rst_n)
begin
    if(!rst_n)
        begin
            ff_rden <= 'b0;
        end
    else
        begin
            if(~ff1_prog_empty)
              ff_rden <= 'b1;
        end
end
always@(posedge i_ad_gclk or negedge rst_n)
begin
    if(!rst_n)
        begin
            c1_adi_dout   <= 'b0    ;
            c1_adq_dout   <= 'b0    ;
            dout_vl       <= 'b0    ;

        end
    else
        begin
            
            c1_adi_dout   <= ff1_dout[15:0]    ;
            c1_adq_dout   <= ff1_dout[31:16]   ;
            dout_vl       <= ff_rden    ;
        end
end

endmodule
