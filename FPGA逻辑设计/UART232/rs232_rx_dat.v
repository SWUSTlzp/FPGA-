`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/08 11:23:10
// Design Name: 
// Module Name: rs232_rx_dat
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

//需要修改将dat_valid信号在数据中间位置进行采样
module rs232_rx_dat(
  input          clk_ref            ,
  input          rst_n              ,
  input          i_rs232_busy       ,
  input          i_rx_pin           ,
  input  [ 3:0]  i_ctrl_cnt         ,
  output         o_rx_start_en        
   
);
reg  [7:0]  rx_dat;
reg         rx_flag;
reg         rx_start_en;
  
reg         rx_pin_t;
reg         rx_pin_tt;
wire        rx_pin_neg;
 
reg         rs232_busy_t;
reg         rs232_busy_tt;
wire        rs232_busy_pro;

reg [ 3:0]  ctrl_cnt_t;
wire        cnt_pro;
assign o_rx_start_en = rx_start_en;
assign rs232_busy_pro = rs232_busy_t & ~rs232_busy_tt;
assign rx_pin_neg = ~rx_pin_t & rx_pin_tt;
assign dat_vaild = (ctrl_cnt_t != i_ctrl_cnt) ? 1'b1 : 1'b0;



always@(posedge clk_ref )begin
    if(i_rs232_busy == 1'b0)begin
        rx_pin_t <= i_rx_pin;
        rx_pin_tt <= rx_pin_t;
    end
end

always@(posedge clk_ref or negedge rst_n)begin
       if(!rst_n)begin
            rx_start_en <= 1'b0;
       end
       else if(rx_pin_neg == 1'b1 && i_ctrl_cnt == 'd0)
            rx_start_en <= 1'b1;
       else 
            rx_start_en <= 1'b0;
end


always@(posedge clk_ref or negedge rst_n)begin
    if(!rst_n)begin
        ctrl_cnt_t <= 'd0;
    end
    else
        ctrl_cnt_t <= i_ctrl_cnt;
end

always@(posedge clk_ref )begin
    rs232_busy_t  <= i_rs232_busy;
    rs232_busy_tt <= rs232_busy_t;  
end

always@(posedge clk_ref or negedge rst_n)begin
    if(!rst_n)begin
         rx_flag <= 1'b0;
    end
    else begin 
         if(rs232_busy_pro == 1'b1)
             rx_flag <= 1'b1;
         else if(dat_vaild == 1'b1)
             rx_flag <= 1'b1;
         else 
             rx_flag <= 1'b0;
    end   
end
always@(posedge clk_ref or negedge rst_n)begin
    if(!rst_n)begin
        rx_dat <= 'd0;
    end
    else if(rx_flag == 1'b1 && (i_ctrl_cnt >='d1 && i_ctrl_cnt <='d8))
        rx_dat <= {rx_dat[6:0], i_rx_pin};
end
endmodule
