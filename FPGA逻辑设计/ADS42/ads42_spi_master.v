`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:56:34 05/08/2017 
// Design Name: 
// Module Name:    spi_master 
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
// ***************************************说明*******************************//
//************************该模块为上降沿采数，下升沿变数**********************//
//************************该模块为时钟平时为低**********************//
//////////////////////////////////////////////////////////////////////////////////
module ads42_spi_master #  //下降沿沿变数，上升沿采数//
(
    parameter   DATA_WITH   = 16        ,
    parameter   RDATA_WITH  = 8         ,
    parameter   MID_CNT     = 49        , //中间值
    parameter   END_CNT     = 99         //最大255
)
(
    sys_clk                 ,  //100mhz
    rst_n                   ,
    i_dat_in                ,
    i_opt_start             ,
    i_opt_cnt               ,
    o_dat_out               ,
    o_dat_vaild             ,
    o_spi_done              ,
    //spi_interface//
    o_cs_n                  ,
    o_spi_clk               ,
    o_mosi                  ,
    i_miso                  
);
input           sys_clk         ;
input           rst_n           ;
input[DATA_WITH-1:0] i_dat_in   ;
input           i_opt_start     ;
input[7:0 ]     i_opt_cnt       ;
output[RDATA_WITH-1:0]o_dat_out  ;
output          o_dat_vaild     ;
output          o_spi_done      ;
                    
output          o_cs_n          ;
output          o_spi_clk       ;
output          o_mosi          ;
input           i_miso          ;


//
reg[7:0]    clk_cnt             ;
wire[7:0 ]  cs_cnt = i_opt_cnt  ;
reg[7:0 ]   opt_cnt             ;

reg         opt_start_ff1       ;
reg         opt_start_ff2       ;
wire        opt_start           ;

reg[DATA_WITH-1:0]  treg_dat    ;
reg[RDATA_WITH-1:0] rreg_dat    ;
reg                 dat_vaild   ;

reg                 rd_flag     ;

reg                 cs_n        ;
reg                 cs_n_ff_d1  ;
reg                 cs_n_ff     ;
reg                 spi_clk     ;
reg                 mosi        ;
reg                 spi_done    ;
assign  o_dat_out   =  rreg_dat     ;
assign  o_dat_vaild =  dat_vaild    ;
assign  o_spi_done  =  spi_done     ;
assign  o_cs_n      =  cs_n         ;
assign  o_spi_clk   =  spi_clk      ;
assign  o_mosi      =  mosi         ;

                                     
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            opt_start_ff1 <= 1'b0;
            opt_start_ff2 <= 1'b0;
        end
     else
        begin
            opt_start_ff1   <= i_opt_start;
            opt_start_ff2   <= opt_start_ff1;
        end
end

assign  opt_start = (~opt_start_ff2 && opt_start_ff1);
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            cs_n <= 1'b1;
        end
    else
        begin
            if(opt_start)
                cs_n <= 1'b0;
            else if(opt_cnt == cs_cnt && clk_cnt == (MID_CNT -1))
                cs_n <= 1'b1;
        end
end
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            cs_n_ff <= 1'b1;
        end
    else
        begin
            if(opt_start)
                cs_n_ff <= 1'b0;
            else if(opt_cnt == cs_cnt && clk_cnt == (MID_CNT -1))
                cs_n_ff <= 1'b1;
        end
end

always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            opt_cnt <= 'd0;
        end
    else
        begin
            if(cs_n_ff == 1'b0 && clk_cnt == END_CNT)
                opt_cnt <= opt_cnt + 1'b1;
            else if(cs_n_ff == 1'b1 )
                opt_cnt <= 'd0;
        end
end
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            clk_cnt <= 'd0;
        end
    else
        begin
            if(cs_n_ff == 1'b0)
                begin
                    if(clk_cnt == END_CNT)
                       clk_cnt <= 'd0;
                    else
                        clk_cnt  <= clk_cnt  + 1'b1; 
                end
            else
                clk_cnt <= 'd0; 
        end
end

always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            spi_clk <= 1'b0;
        end
    else
        begin
            if(cs_n_ff == 1'b0)
                begin
                    if(clk_cnt == MID_CNT)
                       spi_clk <= 1'b0;
                    else if(clk_cnt == END_CNT)
                       spi_clk <= 1'b1; 
                end
            else
                spi_clk <= 1'b0;
        end
end

//trans data//
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
             mosi           <= 1'b0;
             treg_dat       <= 'd0;
             rd_flag        <= 'b0;
        end
    else
        begin
            if(opt_start)
                begin
                    treg_dat       <= i_dat_in;
                    mosi           <= 1'b0; 
                    rd_flag        <= i_dat_in[DATA_WITH-1];
                end
             else if(cs_n_ff == 1'b0)
                begin
                    if(clk_cnt == MID_CNT)
                        begin
                            if(opt_cnt < cs_cnt)
                                begin
                                    treg_dat <= {treg_dat[DATA_WITH-2:0],1'b0};
                                    mosi      <= treg_dat[DATA_WITH-1];
                                end
                        end
                end
             else if(cs_n_ff == 1'b1)
                begin
                    treg_dat       <= treg_dat;
                    mosi           <= 1'b0; 
                end
        end
end

//rx_data//
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
             rreg_dat       <= 'd0;
        end
     else
        begin
            if(cs_n_ff == 1'b0 && opt_cnt > 8'd8)
            //if(cs_n_ff == 1'b0)
                begin
                    if(clk_cnt == END_CNT)
                      rreg_dat <= {rreg_dat[8-2:0],i_miso} ;
                end
        end
end

always@(posedge sys_clk)
begin
    if(!rst_n)
        begin
            cs_n_ff_d1 <= 1'b1;
        end
    else
        begin
            cs_n_ff_d1 <= cs_n_ff;
        end
end
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            spi_done    <= 1'b0;
            dat_vaild   <= 1'b0;
        end
    else
        begin
            if(~cs_n_ff_d1 && cs_n_ff )
                begin
                    spi_done <= 1'b1;
                    if(rd_flag)  //读标志//
                    dat_vaild   <= 1'b1;
                end
            else
                begin
                    spi_done    <= 1'b0;
                    dat_vaild   <= 1'b0;
                end
        end
end
    
endmodule
