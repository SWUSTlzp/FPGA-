`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:40:42 10/25/2017 
// Design Name: 
// Module Name:    ddr3_user_app_module 
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
module ddr3_user_app_v1_module #
(
       parameter ADDR_WIDTH     = 27,
       parameter DATA_WIDTH     = 512
 )
(
 
    
    ddr_clk                 ,
    rst_n                   ,
    //USER APP//
    i_wr_ireq               ,
    i_wr_len                ,
    i_wr_addr               ,
    o_wr_den                ,
    i_wr_dat                ,
    
    i_rd_ireq               ,
    i_rd_len                ,
    i_rd_addr               ,
    o_app_busy              ,
    //user interface//
    app_rst                 , // ACTIVE HIGH//
    init_calib_complete     ,
    app_addr                ,
//    app_cmd                 ,
//    app_en                  ,
    app_rdy                 ,
//    app_rd_data             ,
//    app_rd_data_end         ,
    app_rd_data_valid       ,
    app_wdf_wren            ,
    app_wdf_data            ,
//    app_wdf_end             ,
//    app_wdf_mask            ,
//    app_wdf_rdy             ,
    app_rd_en               
    /*app_sr_req              ,
    app_sr_active           ,
    app_ref_req             ,
    app_ref_ack             ,
    app_zq_req              ,
    app_zq_ack  */          
    );
input                           ddr_clk                 ;
input                           rst_n                   ;
//USER APP//
input                           i_wr_ireq               ;
input   [15:0]                  i_wr_len                ; //数据位宽的个数
input   [ADDR_WIDTH-1:0]        i_wr_addr               ;
output                          o_wr_den                ;
input   [DATA_WIDTH-1:0]        i_wr_dat                ;
input                           i_rd_ireq               ;
input   [15:0]                  i_rd_len                ;//数据位宽的个数
input   [ADDR_WIDTH-1:0]        i_rd_addr               ;
output                          o_app_busy              ;
//user interface//              
input                           app_rst                 ;
input                           init_calib_complete     ;
output [ADDR_WIDTH-1:0]         app_addr                ;
//output [2:0]                    app_cmd                 ;
//output                          app_en                  ;
input                           app_rdy                 ;
//input [128-1:0]                 app_rd_data             ;
//input                           app_rd_data_end         ;
input                           app_rd_data_valid       ;
output                          app_wdf_wren            ;
output [DATA_WIDTH-1:0]         app_wdf_data            ;
//output                          app_wdf_end             ;
//output [DATA_WIDTH/8-1:0]       app_wdf_mask            ;
//input                           app_wdf_rdy             ;//write data fifo ready
output                          app_rd_en               ;
/*
output                          app_sr_req              ;
input                           app_sr_active           ;
output                          app_ref_req             ;
input                           app_ref_ack             ;
output                          app_zq_req              ;
input                           app_zq_ack              ;
*/                                
wire clk        = ddr_clk;
wire sys_rst    = rst_n;
localparam                      IDLE_STA    = 8'h00     ,
                                WSTART_STA  = 8'h01     ,
                                WREG_STA    = 8'h02     ,
                                WOPT_STA    = 8'h04     ,
                                RSTART_STA  = 8'h08     ,
                                RREG_STA    = 8'h10     ,
                                ROPT_STA    = 8'h20     ,
                                WRD_STA     = 8'h40     ,
                                END_STA     = 8'h80     ;  
reg [7:0]                       cur_sta                 ;                                     
//写请求//
reg                             wr_ireq_ff1             ;
reg                             wr_ireq_ff2             ;
reg                             wr_vaild                ;
reg                             wr_clr                  ;
reg [13:0]                      wr_len                  ;
wire [16:0]                     wr_lenth                ;
reg [ADDR_WIDTH-1:0]            wr_addr                 ;
reg                             wr_inprocess            ;
//读请求//
reg                             rd_ireq_ff1             ;
reg                             rd_ireq_ff2             ;
reg                             rd_vaild                ;
reg                             rd_clr                  ;
reg [13:0]                      rd_len                  ;
wire [16:0]                     rd_lenth                ;
reg [ADDR_WIDTH-1:0]            rd_addr                 ;
reg                             rd_inprocess            ;
reg [13:0]                      rd_cnt                  ;
reg [13:0]                      opt_cnt                 ;
reg [13:0]                      recv_cnt                ;
reg                             app_busy                ;
reg                             rd_en                   ;


// 控制读写请求，根据读写请求进行修改 
/*
// 写操作：
       写请求使能与写数据保持相同
   一、当收到写请求后，wr_vaild拉高，上升沿
   二、初始化写地址，wr_vaild拉低
   三、拉低初始化标志
   四、进入写操作，并计数写数据个数，地址值保持不变，计数写个数，写完后写操作标志拉低。
*/
/*
// 读操作：
        读请求需要在app_rdy信号下发出，读请求一个周期与读地址保持不变
   一、当收到读请求后，rd_vaild拉高，上升沿 
   二、初始化读地址，rd_vaild拉低，
   三、拉低初始化标志
   四、进入写操作，等待读有效输入后进行计数。
*/


assign          app_addr        = wr_inprocess ? wr_addr : rd_addr      ;
//assign          app_cmd         = wr_inprocess ? WR_OPT : RD_OPT        ;
//assign          app_en          = (wr_inprocess & app_rdy & app_wdf_rdy)  |  (rd_inprocess & app_rdy )   ;
assign          app_rd_en       = rd_en;
assign          app_wdf_wren    = wr_inprocess & app_rdy                ;
assign          app_wdf_data    = i_wr_dat                              ;   
assign          o_wr_den        = wr_inprocess & app_rdy                ; //从DDR3外请求数据写入,在准备的时候
//assign          app_wdf_end     = wr_inprocess & app_rdy                ; 
//assign          app_wdf_mask    = 'd0                                   ;
assign          o_app_busy      = app_busy                              ;


/*
    读部分进行修改
    读操作：    读请求、读地址同时发出
*/

always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            wr_ireq_ff1 <= 1'b0;
            wr_ireq_ff2 <= 1'b0;
            wr_vaild    <= 1'b0;
        end
    else
        begin
            wr_ireq_ff1 <= i_wr_ireq;
            wr_ireq_ff2 <= wr_ireq_ff1;
            if((~wr_ireq_ff2) && wr_ireq_ff1 ) //上升
                wr_vaild    <= 1'b1;
            else if(wr_clr)
                wr_vaild    <= 1'b0;
                   
        end
end  
//统计写读取入个数//
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            opt_cnt <= 'd0;
        end
    else
        begin
            if(wr_inprocess)            
                begin
//                    if(app_rdy && app_wdf_rdy)
                    if(app_rdy )
                        opt_cnt <= opt_cnt + 1'b1;
                    else
                        opt_cnt <= opt_cnt;
                end
            else if(rd_inprocess)
//
                begin
                    if(app_rd_data_valid)
                        opt_cnt <= opt_cnt + 1'b1;
                    else
                        opt_cnt <= opt_cnt;
                end
            else
                opt_cnt <= 'd0;
          
        end
end
assign wr_lenth = i_wr_len +  1'b1;//i_wr_len = 512
assign rd_lenth = i_rd_len +  1'b1;
//寄存突发长度个数//
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            wr_len      <= 14'h3fff;//16,383
        end
    else
        begin
            if(wr_clr)
                begin
                    if(wr_lenth[16:3] == 'b0)
                        wr_len  <= 14'b0;
                    else    
                        wr_len      <= wr_lenth[16:3] - 1'b1; //512向右移3位，长度为64
                end
        end
end 
//写地址//
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            wr_addr     <= 'd0;
        end
    else
        begin
            if(wr_clr)
                wr_addr     <= i_wr_addr;
        //    else if(wr_inprocess)
        //        begin
//      //             if(app_rdy && app_wdf_rdy)
        //            if(app_rdy)
        //                wr_addr     <= wr_addr + 4'd8;
        //            else
        //                wr_addr     <= wr_addr;
        //        end
        end
end
//寄存写请求信息//
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            rd_ireq_ff1 <= 1'b0;
            rd_ireq_ff2 <= 1'b0;
            rd_vaild    <= 1'b0;
        end
    else
        begin
            rd_ireq_ff1 <= i_rd_ireq;
            rd_ireq_ff2 <= rd_ireq_ff1;
            if((~rd_ireq_ff2) && rd_ireq_ff1 ) //读请求来了之后
                rd_vaild    <= 1'b1;
            else if(rd_clr)
                rd_vaild    <= 1'b0;
        end
end
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            rd_en <= 1'b0;
        end
    else
        begin
            if(rd_clr == 1'b1 ) //读请求来了之后
                rd_en    <= 1'b1;
            else if(app_rdy == 1'b1)
                rd_en    <= 1'b0;
        end
end
//读取突发个数//
//64
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            rd_len      <= 14'h3fff;
        end
    else
        begin
            if(rd_clr )
                begin
                    if(rd_lenth[16:3] == 'b0)
                        rd_len  <= 14'b0;
                    else    
                        rd_len      <= rd_lenth[16:3] - 1'b1; //63
                end
        end
end

always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            rd_addr     <= 'd0;
        end
    else
        begin
            if(rd_clr == 1'b1)
                rd_addr     <= i_rd_addr; //起始地址
        end
end
//寄存读取个数//
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            rd_cnt      <= 'b0;
        end
    else
        begin
            if(rd_clr )
                begin
                    if(rd_lenth[16:3] == 'b0)
                        rd_cnt  <= 'd1;
                    else    
                        rd_cnt      <= rd_lenth[16:3]; //64
                end
        end
end
// 统计读取个数//
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            recv_cnt <= 'd0;
        end
    else
        begin
            if(cur_sta == ROPT_STA || cur_sta == WRD_STA)
                begin
                    if(app_rd_data_valid)
                        recv_cnt <= recv_cnt + 1'b1;
                end
            else
                recv_cnt <= 'd0;
        end
end

/////
always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            cur_sta <= IDLE_STA;
        end
    else
        begin
            case(cur_sta)
                IDLE_STA:   begin
                                if( init_calib_complete &&(~app_rst))//初始化结束后
                                    begin
                                        if(wr_vaild)                 //写请求有效
                                            cur_sta <= WSTART_STA;
                                        else if(rd_vaild) 
                                            cur_sta <= RSTART_STA;
                                        else    
                                            cur_sta <= IDLE_STA;
                                    end
                                else
                                    cur_sta <= IDLE_STA;
                            end
                WSTART_STA: begin                         //写状态开始，并且寄存突发长度和写地址
                                cur_sta <= WREG_STA;      
                            end
                WREG_STA:   begin                         //一个时钟周期拉低wr_clr
                                cur_sta <= WOPT_STA;      
                            end
                WOPT_STA:   begin                         //写进程开始
//                                if((opt_cnt == wr_len) && (app_rdy && app_wdf_rdy))//计数64个时钟周期
                                if((opt_cnt == wr_len) && app_rdy )//计数64个时钟周期
                                    cur_sta <= END_STA;
                            end
                RSTART_STA: begin
                                   cur_sta <= RREG_STA;
                            end
                RREG_STA:   begin
                                cur_sta <= ROPT_STA;
                            end
                ROPT_STA:   begin
                                if((opt_cnt == rd_len))    
                                   cur_sta <=  WRD_STA;
                            end
                WRD_STA:   begin
                          //      if(recv_cnt == rd_cnt)  //rd_cnt == 64
                                    cur_sta <= END_STA;
                            end
                END_STA:    begin
                                 cur_sta <= IDLE_STA;
                            end
                default:    begin
                                cur_sta <= IDLE_STA;
                            end
            endcase
        end
end

always@(posedge clk or negedge sys_rst)
begin
    if(!sys_rst)
        begin
            wr_inprocess    <= 1'b0;
            wr_clr          <= 1'b0;
            rd_inprocess    <= 1'b0;
            rd_clr          <= 1'b0;
            app_busy        <= 1'b0;
        end
    else
        begin
            case(cur_sta)
                IDLE_STA:   begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b0;
                            end
                WSTART_STA: begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b1;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b1;
                            end
                WREG_STA:   begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b1;
                            end
                WOPT_STA:   begin
                                wr_inprocess    <= 1'b1;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b1;
//                                if((opt_cnt == wr_len) &&(app_rdy && app_wdf_rdy))
                                if((opt_cnt == wr_len) && app_rdy)
                                    wr_inprocess    <= 1'b0;
                            end
                RSTART_STA: begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b1;
                                app_busy        <= 1'b1;
                            end
                RREG_STA:   begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b1;
                            end
                ROPT_STA:   begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b1;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b1;
                                if(opt_cnt == rd_len)
                                    rd_inprocess    <= 1'b0;
                            end
                WRD_STA:   begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0; 
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b1;
                            end
                END_STA:    begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b1;
                            end
                default:    begin
                                wr_inprocess    <= 1'b0;
                                wr_clr          <= 1'b0;
                                rd_inprocess    <= 1'b0;
                                rd_clr          <= 1'b0;
                                app_busy        <= 1'b0;
                            end
            endcase
        end
end

endmodule
