`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/28 15:25:36
// Design Name: 
// Module Name: fifo_demo
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

/*
*
    fifo的输入与输出的位宽相同
    同步fifo
*/
module fifo_demo#  
(
    parameter   DATA_WIDTH = 16        ,
    parameter   FIFO_DEPTH = 1024          
)
(
    input                      clk      ,
    input                      wr_en    ,
    input                      rd_en    ,
    output                     wr_full  ,
    output                     rd_empty ,
    input                      rst_n    ,
    input  [DATA_WIDTH - 1:0]  fifo_in  ,
    output [DATA_WIDTH - 1:0]  fifo_out  
    
);

    reg    [FIFO_DEPTH - 1:0]  fifo_addr;
    reg    [DATA_WIDTH - 1:0]  fifo_buffer [0 :FIFO_DEPTH - 1];
    reg    [DATA_WIDTH - 1:0]  wr_pointer;
    reg    [DATA_WIDTH - 1:0]  rd_pointer;
//rd_pointer
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_pointer <= 'd0;
    end
    else if(rd_pointer == FIFO_DEPTH - 1)begin
        rd_pointer <= 'd0;
    end
    else if(rd_en == 1'b1 && rd_empty == 1'b0)begin
        rd_pointer <= rd_pointer + 1'b1;
    end
end

//wr_pointer
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_pointer <= 'd0;
    end
    else if(wr_pointer == FIFO_DEPTH - 1)begin
        wr_pointer <= 'd0;
    end
    else if(wr_en == 1'b1 && wr_full == 1'b0)begin
        wr_pointer <= wr_pointer + 1'b1;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fifo_addr <= 'd0;
    end
    else if(wr_pointer > 'd0 && wr_en && rd_en)begin
        fifo_addr <= fifo_addr;
    end
    else if(wr_en && !wr_full)begin
        fifo_addr <= fifo_addr + 1'b1;
    end
    else if(rd_en && !rd_empty)begin
        fifo_addr <= fifo_addr - 1'b1;
    end
end

integer i;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0; i<=FIFO_DEPTH -1; i=i+1)begin
            fifo_buffer[i] <= 'd0;
        end
    end
    else if(wr_en)begin 
        fifo_buffer[wr_pointer] <= fifo_in;
    end
end

assign wr_full  = (fifo_addr == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
assign rd_empty = (fifo_addr == 1'b0) ? 1'b1 : 1'b0;
assign fifo_out = fifo_buffer[rd_pointer];


endmodule
