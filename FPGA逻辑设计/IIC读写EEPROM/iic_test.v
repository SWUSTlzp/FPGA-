`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/15 09:24:16
// Design Name: 
// Module Name: iic_test
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


module iic_test(
    input                       sys_clk         ,  //100M
    input                       rst_n           ,
    input            [31:0]     i_cfg_dat       , 
    input                       i_cfg_start_en  ,
    output                      iic_scl         ,
    inout                       iic_sda         ,
    output           [ 7:0]     o_rd_dat 
);
parameter           IDLE     = 13'b0_0000_0000_0000;//
parameter           START    = 13'b0_0000_0000_0001;//1
parameter           WR_DEV   = 13'b0_0000_0000_0010;//2
parameter           DEV_ACK  = 13'b0_0000_0000_0100;//4
parameter           ADDR     = 13'b0_0000_0000_1000;//8
parameter           ADDR_ACK = 13'b0_0000_0001_0000;//16
parameter           WR_DAT   = 13'b0_0000_0010_0000;//32
parameter           DAT_ACK  = 13'b0_0000_0100_0000;//64
parameter           STOP     = 13'b0_0000_1000_0000;//128                    
parameter           RD_STA   = 13'b0_0001_0000_0000;//256
parameter           RD_DEV   = 13'b0_0010_0000_0000;//512
parameter           RD_ACK   = 13'b0_0100_0000_0000;//1024
parameter           RD_DAT   = 13'b0_1000_0000_0000;//2048
parameter           RD_NACK  = 13'b1_0000_0000_0000;//4096    


reg      [12:0]     state_c;
reg      [12:0]     state_n;

wire                idle2start_start   ;
wire                start2wrdev_start  ;
wire                wrdev2devack_start ;
wire                devack2addr_start  ;
wire                addr2addrack_start ;
wire                addrack2wrdat_start;
wire                wrdat2datack_start ;
wire                datack2stop_start  ;
wire                stop2idle_start    ;
wire                rdsta2rddev_start  ;
wire                rddev2rdack_start  ;
wire                rdack2rddat_start  ;
wire                rddat2rdnack_start ;
wire                rdnack2stop_start  ;

///////////////////////cnt/////////////////////
/*写数据计数器0-8                */
reg      [ 3:0]     cnt_wrdat       ;     
wire                add_cnt_wrdat   ;
wire                end_cnt_wrdat   ;
/*当sda拉低后开始工作，表示div4的一个时钟周期 400khz*/
reg      [ 7:0]     cntscl4         ;//250
wire                add_cntscl4     ;
wire                end_cntscl4     ;
/*计数div4时钟的个数，根据配置的个数 4*29*/
reg      [ 7:0]     cnt_div         ;//4*29 = 116 | 4*39 = 156
wire                add_cnt_div     ;
wire                end_cnt_div     ;
/*计数sda，用于产生标志信号，以及实现sda在scl高电平不变化*/
reg      [ 2:0]     cntsda          ;//4
wire                add_cntsda      ;
wire                end_cntsda      ;
/*计数器scl，通过div4，用于产生scl的时钟，一个scl周期中有四个div周期 100Khz*/
reg      [ 1:0]     cntscl          ;//2
wire                add_cntscl      ;
wire                end_cntscl      ;
/*计数器cntcfg，用于产生配置个数的计数*/
reg      [ 5:0]     cntcfg          ;//29 | 39
wire                add_cntcfg      ;
wire                end_cntcfg      ;

reg                 scl             ;
reg                 sda             ;
reg                 cfg_start_en_t  ;
reg                 cfg_start_en_tt ;
reg                 busy            ;
reg                 start_scl_en    ;
wire                start_scl_en_pro;
reg                 start_scl_en_tt ;
reg                 start_scl_en_t  ;

reg      [ 7:0]     wr_dat_reg      ;
reg                 sda_wr_run      ;
reg                 scl_stop        ;
reg      [31:0]     cfg_dat_t       ;
reg                 flag_wr_rd      ;

reg      [ 7:0]     rd_dat          ;
reg                 sda_highz       ;
reg                 rdsda_en        ;
reg                 rdscl_en        ;

assign o_rd_dat = rd_dat;

always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

always@(*)begin

    case(state_c)
        IDLE:begin
            if(idle2start_start)begin
                state_n = START;
            end           
            else begin
                state_n = state_c;
            end
        end
        START:begin
            if(start2wrdev_start)begin
                state_n = WR_DEV;
            end
            else begin
                state_n = state_c;
            end
        end
        WR_DEV:begin
            if(wrdev2devack_start)begin
                state_n = DEV_ACK;
            end
            else begin
                state_n = state_c;
            end
        end
        DEV_ACK:begin
            if(devack2addr_start)begin
                state_n = ADDR;
            end
            else begin
                state_n = state_c;
            end
        end
        ADDR:begin
            if(addr2addrack_start)begin
                state_n = ADDR_ACK;
            end
            else begin
                state_n = state_c;
            end
        end
        ADDR_ACK:begin
            if(addrack2wrdat_start)begin
                state_n = WR_DAT;
            end
            else if(addrack2rdsta_start)begin
                state_n = RD_STA;
            end
            else begin
                state_n = state_c;
            end
        end
        WR_DAT:begin
            if(wrdat2datack_start)begin
                state_n = DAT_ACK;
            end
            else begin
                state_n = state_c;
            end
        end
        DAT_ACK:begin
            if(datack2stop_start)begin
                state_n = STOP;
            end
            else begin
                state_n = state_c;
            end
        end
        RD_STA:begin
            if(rdsta2rddev_start)begin
                state_n = RD_DEV;
            end
            else begin
                state_n = state_c;
            end
        end
        RD_DEV:begin
            if(rddev2rdack_start)begin
                state_n = RD_ACK;
            end
            else begin
                state_n = state_c;
            end
        end
        RD_ACK:begin
            if(rdack2rddat_start)begin
                state_n = RD_DAT;
            end
            else begin
                state_n = state_c;
            end
        end
        RD_DAT:begin
            if(rddat2rdnack_start)begin
                state_n = RD_NACK;
            end
            else begin
                state_n = state_c;
            end
        end
        RD_NACK:begin
            if(rdnack2stop_start)begin
                state_n = STOP;
            end
            else begin 
                state_n = state_c;
            end
        end
        STOP:begin
            if(stop2idle_start)begin
                state_n = IDLE;
            end
            else begin
                state_n = state_c;
            end
        end
        default:begin
            state_n = IDLE;
        end
    endcase
end

assign idle2start_start    = state_c == IDLE     && i_cfg_start_en;
assign start2wrdev_start   = state_c == START    && cntcfg == 'd0  && end_cntsda;
assign wrdev2devack_start  = state_c == WR_DEV   && cntcfg == 'd8  && end_cntsda;
assign devack2addr_start   = state_c == DEV_ACK  && cntcfg == 'd9  && end_cntsda;
assign addr2addrack_start  = state_c == ADDR     && cntcfg == 'd17 && end_cntsda;
assign addrack2wrdat_start = state_c == ADDR_ACK && cntcfg == 'd18 && end_cntsda && flag_wr_rd == 1'b0;
assign wrdat2datack_start  = state_c == WR_DAT   && cntcfg == 'd26 && end_cntsda && flag_wr_rd == 1'b0;
assign datack2stop_start   = state_c == DAT_ACK  && cntcfg == 'd27 && end_cntsda && flag_wr_rd == 1'b0; 
assign addrack2rdsta_start = state_c == ADDR_ACK && cntcfg == 'd18 && end_cntsda && flag_wr_rd == 1'b1;
assign rdsta2rddev_start   = state_c == RD_STA   && cntcfg == 'd19 && end_cntsda;
assign rddev2rdack_start   = state_c == RD_DEV   && cntcfg == 'd27 && end_cntsda;
assign rdack2rddat_start   = state_c == RD_ACK   && cntcfg == 'd28 && end_cntsda;
assign rddat2rdnack_start  = state_c == RD_DAT   && cntcfg == 'd36 && end_cntsda;
assign rdnack2stop_start   = state_c == RD_NACK  && cntcfg == 'd37 && end_cntsda;
assign stop2idle_start     = state_c == STOP     && (cntcfg == 'd28 || cntcfg == 'd38) && end_cntsda;

//sda_wr_run
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        sda_wr_run <= 1'b0;
    end
    else if(state_c == WR_DEV)begin
        sda_wr_run <= 1'b1;
    end
    else if(state_c == ADDR)begin
        sda_wr_run <= 1'b1;
    end
    else if(state_c == WR_DAT)begin
        sda_wr_run <= 1'b1;
    end
    else if(state_c == RD_DEV)begin
        sda_wr_run <= 1'b1;
    end
    else if(state_c == RD_DAT)begin
        sda_wr_run <= 1'b1;
    end
    else begin 
        sda_wr_run <= 1'b0;
    end
end
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        sda_highz <= 1'b0;
    end  
    else if(state_c == DEV_ACK)begin
        sda_highz <= 1'b1;
    end
    else if(state_c == ADDR_ACK)begin
        sda_highz <= 1'b1;
    end
    else if(state_c == DAT_ACK)begin
        sda_highz <= 1'b1;
    end
    else if(state_c == RD_ACK)begin
        sda_highz <= 1'b1;
    end
    else if(state_c == RD_DAT)begin
        sda_highz <= 1'b1; 
    end
    else begin
        sda_highz <= 1'b0;
    end
end

/*
    control start state,
    读状态的起始位
*/
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        rdsda_en <= 1'b0;
    end
    else begin
        if(state_c == RD_STA)begin
            if(end_cntscl == 1'b1)begin
                rdsda_en <= 1'b1;
            end
        end
        else begin
            rdsda_en <= 1'b0;
        end
    end
end
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        rdscl_en <= 1'b0;
    end
    else begin
        if(state_c == RD_STA)begin
            if(rdsda_en == 1'b1 && end_cntscl == 1'b1)begin
                rdscl_en <= 1'b1;
            end
        end
        else begin
            rdscl_en <= 1'b0;
        end
    end     
end

//i_cfg_dat device/0 : [31:24];  reg_addr : [23:16]; device/1 : [15:8]; data : [ 7:0];
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_dat_reg <= 'd0;
    end
    else if(state_c == WR_DEV)begin
        wr_dat_reg <= cfg_dat_t[31:24];
    end
    else if(state_c == ADDR)begin
        wr_dat_reg <= cfg_dat_t[23:16];
    end
    else if(state_c == WR_DAT)begin
        wr_dat_reg <= cfg_dat_t[ 7:0];
    end
    else if(state_c == RD_DEV)begin
        wr_dat_reg <= cfg_dat_t[15:8];
    end
    else begin
        wr_dat_reg <= 'd0;
    end
end
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        scl_stop <= 1'b0;
    end
    else if(end_cntscl4 && cntcfg == 'd28 && flag_wr_rd == 1'b0)
        scl_stop <= 1'b1;
    else if(end_cntscl4 && cntcfg == 'd38)
        scl_stop <= 1'b1;
    else if(busy == 1'b0)
        scl_stop <= 1'b0;       
end


always@(posedge sys_clk )begin
    cfg_dat_t <= i_cfg_dat;
end
//flag_wr_rd 0: write 1: read
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        flag_wr_rd <= 1'b0;
    end
    else begin
        if(cfg_dat_t[8] == 1'b0)begin
            flag_wr_rd <= 1'b0;
        end
        else begin
            flag_wr_rd <= 1'b1;
        end
    end        
end

always @(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_wrdat <= 'd0;
    end
    else if(add_cnt_wrdat)begin
        if(end_cnt_wrdat)
            cnt_wrdat <= 'd0;
    else
        cnt_wrdat <= cnt_wrdat + 1'b1;
    end
end

assign add_cnt_wrdat = sda_wr_run && end_cntsda == 1'b1;       
assign end_cnt_wrdat = add_cnt_wrdat && cnt_wrdat== 8 - 1;

always@(posedge sys_clk)begin
    cfg_start_en_t <= i_cfg_start_en;
    cfg_start_en_tt <= cfg_start_en_t;
end

//busy
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        busy <= 1'b0;
    end
    else begin
        if(end_cntcfg ==  1'b1)
            busy <= 1'b0;
        else if(cfg_start_en_tt == 1'b1)
            busy <= 1'b1;
    end
end

always @(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        cntscl4 <= 'd0;
    end
    else if(add_cntscl4)begin
        if(end_cntscl4)
            cntscl4 <= 'd0;
        else
            cntscl4 <= cntscl4 + 1'b1;
    end
end

assign add_cntscl4 = busy == 1'b1;       
assign end_cntscl4 = add_cntscl4 && cntscl4== 250 - 1;//

always @(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_div <= 'd0;
    end
    else if(add_cnt_div)begin
        if(end_cnt_div)
            cnt_div <= 'd0;
        else
            cnt_div <= cnt_div + 1'b1;
   end
end
assign add_cnt_div = end_cntscl4;       
assign end_cnt_div = add_cnt_div && (cnt_div == (flag_wr_rd ? 155 : 115));

always @(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        cntsda <= 'd0;
    end
    else if(add_cntsda)begin
        if(end_cntsda)
            cntsda <= 'd0;
        else
            cntsda <= cntsda + 1'b1;
    end
end

assign add_cntsda = end_cntscl4;       
assign end_cntsda = add_cntsda && cntsda == 4 - 1;

always @(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        cntcfg <= 'd0;
    end
    else if(add_cntcfg)begin
        if(end_cntcfg)
           cntcfg <= 'd0;
        else
           cntcfg <= cntcfg + 1'b1;
    end
end

assign add_cntcfg = end_cntsda;       
assign end_cntcfg = add_cntcfg && (cntcfg == (flag_wr_rd ? 38 : 28));

always @(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        cntscl <= 'd0;
    end
    else if(add_cntscl)begin
        if(end_cntscl)
            cntscl <= 'd0;
        else 
            cntscl <= cntscl + 1'b1;
    end
    else if(busy == 1'b0)
        cntscl <= 'd0;
end

assign add_cntscl = start_scl_en == 1'b1 && end_cntscl4 == 1'b1;       
assign end_cntscl = add_cntscl && cntscl== 2 - 1;

always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        start_scl_en <= 1'b0;
    end
    else if(busy == 1'b0)
        start_scl_en <= 1'b0;
    else if(cnt_div >= 'd3)
        start_scl_en <= 1'b1;
end

always@(posedge sys_clk)begin
    start_scl_en_t <= start_scl_en;
    start_scl_en_tt<= start_scl_en_t;      
end
assign start_scl_en_pro = start_scl_en_t & ~start_scl_en_tt;


always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        scl <= 1'b1;
    end
    else if(start_scl_en_pro == 1'b1)
        scl <= 1'b0;
    else if(state_c == RD_STA && rdscl_en == 1'b0)//起始位
        scl <= 1'b1;                              //起始位
    else if(rdscl_en == 1'b1)                     //起始位
        scl <= 1'b0;
    else if(scl_stop == 1'b1)
        scl <= 1'b1;
    else if(end_cntscl == 1'b1)
        scl <= ~scl;
end
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        sda <= 1'b1;
    end
    else if(cfg_start_en_tt == 1'b1)
        sda <= 1'b0;
    else if(end_cntcfg == 'd18 && end_cntsda && flag_wr_rd == 1'b1)
        sda <= 1'b1;
    else if(rdsda_en == 1'b1)
        sda <= 1'b0;
    else if(busy == 1'b0) //stop
        sda <= 1'b1;
    else if(cntcfg == 'd28 || cntcfg == 'd38 || cntcfg == 'd37) //start,stop and NACK
        sda <= 1'b0;
    else if(sda_wr_run == 1'b1)begin
        sda <= wr_dat_reg[7-cnt_wrdat];
    end
end

always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_dat <= 'd0;
    end 
    else begin
        if(state_c == RD_DAT)begin
            if(end_cntsda == 1'b1)
                rd_dat <= {rd_dat[6:0] ,iic_sda};
        end
    end
end

assign  iic_sda = sda_highz ? 1'bz : sda;
assign  iic_scl = scl;
endmodule
