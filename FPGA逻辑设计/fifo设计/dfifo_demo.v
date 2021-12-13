`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/29 14:17:52
// Design Name: 
// Module Name: dfifo_demo
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


module dfifo_demo#  
(
    parameter   DATA_WIDTH = 16           ,
    parameter   FIFO_WIDTH = 9            ,
    parameter   FIFO_DEPTH = 1024
)
(
    input                               wr_clk     ,
    input                               rd_clk     ,
    input                               wr_en      ,
    input                               rd_en      ,
    output   reg                        wr_full    ,
    output   reg                        rd_empty   ,
    input                               rst_n      ,
    input           [DATA_WIDTH - 1:0]  fifo_in    ,
    output   reg    [DATA_WIDTH - 1:0]  fifo_out  
    
);
    reg    [DATA_WIDTH - 1:0]  fifo_buffer [0 :FIFO_DEPTH - 1];
    
    reg    [FIFO_WIDTH    :0]   wr_pointer;//读写指针
    reg    [FIFO_WIDTH    :0]   rd_pointer;
    wire   [FIFO_WIDTH - 1:0]   wr_addr; //读写地址
    wire   [FIFO_WIDTH - 1:0]   rd_addr;
    wire   [FIFO_WIDTH    :0]   wr_gray;
    reg    [FIFO_WIDTH    :0]   wr_gray_r;
    reg    [FIFO_WIDTH    :0]   wr_gray_rr;
    wire   [FIFO_WIDTH    :0]   rd_gray;
    reg    [FIFO_WIDTH    :0]   rd_gray_r;
    reg    [FIFO_WIDTH    :0]   rd_gray_rr;
//    wire   [FIFO_WIDTH    :0]   fifo_depth;
    
    //assign   fifo_depth = {(FIFO_WIDTH){1'b1}}+1'b1;
//    assign   fifo_depth = 'd1024;
    assign   wr_gray = (wr_pointer >> 1)^wr_pointer;
    assign   rd_gray = (rd_pointer >> 1)^rd_pointer;
    assign   o_wr_full = wr_full;
    assign   o_rd_empty = rd_empty;

// wr_clk   --- rd_gray
always@(posedge wr_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_gray_r <= 'd0;
        rd_gray_rr <= 'd0;
    end
    else begin
        rd_gray_r <= rd_gray; 
        rd_gray_rr <= rd_gray_r;
    end
end
// rd_clk   --- wr_gray
always@(posedge rd_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_gray_r <= 'd0;
        wr_gray_rr <= 'd0;
    end
    else begin
        wr_gray_r <= wr_gray; 
        wr_gray_rr <= wr_gray_r;
    end
end


assign wr_addr = wr_pointer[FIFO_WIDTH - 1:0];
assign rd_addr = rd_pointer[FIFO_WIDTH - 1:0];
//rd_pointer
always@(posedge rd_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_pointer <= 'd0;
    end
    else if(rd_en == 1'b1 && rd_empty == 1'b0)begin
        rd_pointer <= rd_pointer + 1'b1;
    end
    else begin
        rd_pointer <= rd_pointer;
    end
end
always@(posedge rd_clk or negedge rst_n)begin
    if(!rst_n)begin
        fifo_out <= 'd0;
    end
    else if(rd_en == 1'b1 && rd_empty == 1'b0)begin
        fifo_out <= fifo_buffer[rd_addr];
    end
end

//wr_pointer
always@(posedge wr_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_pointer <= 'd0;
    end
    else if(wr_en == 1'b1 && wr_full == 1'b0)begin
        wr_pointer <= wr_pointer + 1'b1;
    end
    else begin
        wr_pointer <= wr_pointer;
    end
end

integer i;

always@(posedge wr_clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0; i<=FIFO_DEPTH -1; i=i+1)begin
            fifo_buffer[i] <= 'd0;
        end
    end
    else if(wr_en == 1'b1 && wr_full == 1'b0)begin 
        fifo_buffer[wr_addr] <= fifo_in;
    end
end


//wr_full 写超过读一轮，并且写等于读指针，说明写满
always@(posedge wr_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_full <= 'd0;
    end
    else if(rd_gray_rr == {~wr_gray[FIFO_WIDTH],~wr_gray[FIFO_WIDTH - 1], wr_gray[FIFO_WIDTH - 2 : 0]}) begin
        wr_full <= 1'b1;
    end
    else begin
        wr_full <= 1'b0;
    end
end

//assign full = (wr_addr_p_gray=={~rd_addr_p_gray1[awidth-:2],rd_addr_p_gray1[awidth-2:0]})?1:0;
//rd_empty   读指针等于写指针，
/*
当写地址指针与读地址指针低八位完全相等，而读地址追上了写地址，则表示读空了。（二进制与格雷码情况下）
但是将二进制转换成格雷码后判断满的标志则为，格雷码状态下高两位相反，其余相同
*/
always@(posedge rd_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_empty <= 'd0;
    end
    else if(wr_gray_rr == rd_gray) begin //写比读快，
        rd_empty <= 1'b1;
    end
    else 
        rd_empty <= 1'b0;
end



endmodule
