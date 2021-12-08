
//传输数据控制 tx

module rs232_tx_dat(
  input                 clk_ref            ,
  input                 rst_n              ,
  input                 i_rs232_busy       ,
  input         [ 7:0]  i_tx_dat           ,
  output  wire          o_tx_pin           ,
  input         [ 3:0]  i_ctrl_cnt         
   
);

reg         tx_pin;
assign      o_tx_pin   =  tx_pin;

reg      [ 7:0]     tx_dat;

reg         rs232_busy_t;
reg         rs232_busy_tt;
wire        rs232_busy_pro;
always@(posedge clk_ref )begin
       rs232_busy_t  <= i_rs232_busy;
       rs232_busy_tt <= rs232_busy_t;
      
end
assign rs232_busy_pro = rs232_busy_t & ~rs232_busy_tt;

always@(posedge clk_ref or negedge rst_n)begin
       if(!rst_n)begin
            tx_dat <= 'd0;
       end
       else if(rs232_busy_pro == 1'b1)
            tx_dat <= i_tx_dat;
end

always@(*)begin
    if(i_rs232_busy == 1'b1)begin
       case(i_ctrl_cnt) 
       //start
           'd0: tx_pin <=  1'b0;
       //data_low4    
           'd1: tx_pin <=  tx_dat[0];
           'd2: tx_pin <=  tx_dat[1];
           'd3: tx_pin <=  tx_dat[2];
           'd4: tx_pin <=  tx_dat[3];
       //data_high4    
           'd5: tx_pin <=  tx_dat[4];
           'd6: tx_pin <=  tx_dat[5];
           'd7: tx_pin <=  tx_dat[6];
           'd8: tx_pin <=  tx_dat[7];
       //stop    
           'd9: tx_pin <=  1'b1;
           default: tx_pin <= 1'b1;
       endcase
    end
    else 
        tx_pin <= 1'b1;  
end

endmodule
