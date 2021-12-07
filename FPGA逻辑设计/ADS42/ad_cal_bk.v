module ad_cal_bk(

input           sys_clk             ,
input           rst_n               ,

input           i_ad_inital_over    ,                                                                       
output[3:0]     o_ad_mode           ,
output[2:0]     o_ad_dly            ,
output          o_ad_cal_start      ,
output          o_ad_cal_finish     ,
input           i_ad_cal_over       ,

input           ad_clk              ,                                    
input [15:0]    s_dout_ch0          
);

reg[3:0]        ad_mode             ;
reg[2:0]        ad_dly              ;
reg             ad_cal_start        ;
reg             ad_cal_finish       ;

reg[7:0]        dly_cnt             ;
reg             dly_vl              ;
//---数据--//
reg             comp_en             ;
reg[9:0]        comp_cnt            ;
reg             cal_result          ;
reg[15:0]       s_dout_ch0_buf      ;
//--数据比较以及跨时钟处理--//
reg             comp_en_buf         ;
reg             comp_en_ff1         ;
reg             comp_en_ff2         ;
reg[9:0]        comp_cnt_buf        ;
//---寄存数据--//
wire[3:0]       result_tap          ;
reg[2:0]        delay_tap_n0        ;
reg[2:0]        delay_tap_n1        ;

localparam      IDLE_STA  = 13'h0000,
                ITAP_STA  = 13'h0001,
                IWAIT_STA = 13'h0002,
                IDLY_STA  = 13'h0004,
                ICOMP_STA = 13'h0008,
                IRUSLT_STA= 13'h0010,
                TTAP_STA  = 13'h0020,
                TWAIT_STA = 13'h0040,
                TDLY_STA  = 13'h0080,
                TCOMP_STA = 13'h0100,
                TRUSLT_STA= 13'h0200,
                SET_STA   = 13'h0400,
                WAIT_STA  = 13'h0800,
                OVER_STA  = 13'h1000;    
reg [12:0]      cur_sta             ;



assign  o_ad_mode       = ad_mode       ;
assign  o_ad_dly        = ad_dly        ;
assign  o_ad_cal_start  = ad_cal_start  ;
assign  o_ad_cal_finish = ad_cal_finish ;
assign  result_tap  = delay_tap_n0 + delay_tap_n1;
//---延迟一会--//
always@(posedge sys_clk  or negedge rst_n)
begin
    if(!rst_n)
        dly_cnt <= 'd0;
    else
        begin
            if(dly_vl)
                begin
                    if(dly_cnt == 'hff)
                        dly_cnt <= dly_cnt;
                    else
                        dly_cnt <= dly_cnt + 1'd1;
                end
            else
                dly_cnt <= 'd0;
        end
end
//--------数据比较，以及跨时钟处理--//
always@(posedge ad_clk  or negedge rst_n)
begin
     if(!rst_n)
        begin
            comp_en_buf <= 1'b0;
            comp_en_ff1 <= 1'b0;
            comp_en_ff2 <= 1'b0;
        end
     else
        begin
            comp_en_ff1 <= comp_en;
            comp_en_ff2 <= comp_en_ff1;
            if((~comp_en_ff2)&&comp_en_ff1)  // posedge
                comp_en_buf <= 1'b1;
            else if(comp_en_ff2&&(~comp_en_ff1)) //negedge
                comp_en_buf <= 1'b0;
        end
end
always@(posedge ad_clk  or negedge rst_n)
begin
     if(!rst_n)
        comp_cnt <= 'd0;
     else
        begin
             if(comp_en_buf)
                begin
                    if(comp_cnt == 'd1023)
                        comp_cnt <= 'd1023;
                    else
                        comp_cnt <= comp_cnt + 1'b1;
                end
             else
                comp_cnt <= 'd0;  
        end
end
always@(posedge ad_clk)
begin
    s_dout_ch0_buf <= s_dout_ch0;
end
always@(posedge ad_clk  or negedge rst_n)
begin
     if(!rst_n)
        cal_result <= 'd0;
     else
        begin
            if(dly_vl)
                cal_result <= 'd0;
            else if(comp_en_buf)
                begin
                    if(s_dout_ch0 != (s_dout_ch0_buf + 1'b1) )  //代表有错
                        begin
                            cal_result <= 'd1;
                        end
                end
                
        end
end
//-----//
always@(posedge sys_clk  or negedge rst_n)
begin
     if(!rst_n)
        begin
            comp_cnt_buf <= 'b0;
        end
     else
        begin
            comp_cnt_buf <= comp_cnt;
        end
end

//----主状态--//
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            ad_mode         <= 'b0;  // 00,正常工作，01睡眠模式，10，POWER DOWN ,11 测试模式//   
            ad_dly          <= 'b0;  //0~7 ,31~143度延迟--//
            ad_cal_start    <= 'b0;
            ad_cal_finish   <= 'b0;
            dly_vl          <= 'b0;
            comp_en         <= 'b0;
            delay_tap_n0    <= 'b0;
            delay_tap_n1    <= 'b0;
            cur_sta         <= IDLE_STA ;
        end
    else
        begin
            case(cur_sta)
                IDLE_STA:   begin
                                if(i_ad_inital_over)
                                    begin
                                        cur_sta <= ITAP_STA;
                                    end
                            end
                ITAP_STA:  begin
                                ad_mode         <= 'b0100;
                                ad_dly          <= 'b0;
                                ad_cal_start    <= 'b1;
                                cur_sta         <= IWAIT_STA;
                            end
                IWAIT_STA:  begin
                                if(i_ad_cal_over)
                                   cur_sta         <= IDLY_STA; 
                            end
                IDLY_STA:   begin
                                if(dly_cnt == 'hff)
                                    begin
                                        dly_vl  <= 'd0;
                                        cur_sta <= ICOMP_STA;
                                    end
                                 else 
                                    dly_vl <= 1'b1;
                            end
                ICOMP_STA:  begin
                                if(comp_cnt_buf == 'd1023)
                                    begin
                                         comp_en         <= 1'b0;
                                         cur_sta         <= IRUSLT_STA;
                                    end
                                else
                                    comp_en         <= 1'b1;
                            end
                IRUSLT_STA: begin
                                ad_cal_start    <= 'b0;
                                if(cal_result)  //有错//
                                    begin
                                        if(~i_ad_cal_over)
                                            begin
                                                ad_dly          <= ad_dly + 1'b1;
                                                ad_cal_start    <= 'b1;
                                                cur_sta         <= IWAIT_STA;
                                            end
                                    end
                                else
                                    begin
                                        if(~i_ad_cal_over)
                                            begin
                                                delay_tap_n0    <= ad_dly       ;
                                                ad_dly          <= ad_dly + 1'b1;
                                                cur_sta         <= TTAP_STA;
                                            end
                                    end
                            end
                TTAP_STA:   begin
                                ad_cal_start    <= 'b1;
                                cur_sta         <= TWAIT_STA;
                            end
                TWAIT_STA:  begin
                                if(i_ad_cal_over)
                                   cur_sta         <= TDLY_STA; 
                            end
                TDLY_STA:   begin
                                if(dly_cnt == 'hff)
                                    begin
                                        dly_vl  <= 'd0;
                                        cur_sta <= TCOMP_STA;
                                    end
                                 else 
                                    dly_vl <= 1'b1;
                            end
                TCOMP_STA:  begin
                                if(comp_cnt_buf == 'd1023)
                                    begin
                                         comp_en         <= 1'b0;
                                         cur_sta         <= TRUSLT_STA;
                                    end
                                else
                                    comp_en         <= 1'b1;
                            end
                TRUSLT_STA: begin
                                ad_cal_start    <= 'b0;
                                if(cal_result || ad_dly == 'd7)  //有错，或者达到尽头//
                                    begin
                                        if(~i_ad_cal_over)
                                            begin
                                                delay_tap_n1    <= ad_dly       ;
                                                cur_sta         <= SET_STA      ;
                                            end
                                    end
                                else
                                    begin
                                        if(~i_ad_cal_over)
                                            begin
                                                ad_dly          <= ad_dly + 1'b1;
                                                ad_cal_start    <= 'b1;
                                                cur_sta         <= TWAIT_STA;
                                            end
                                    end
                            end
                SET_STA:    begin
                                ad_mode         <= 'b0000;
                                ad_dly          <= result_tap[3:1];
                                ad_cal_start    <= 'b1;
                                cur_sta         <= WAIT_STA;
                            end
                WAIT_STA:   begin
                                if(i_ad_cal_over)
                                    begin
                                        ad_cal_start    <= 'b0;
                                        cur_sta         <= OVER_STA; 
                                    end
                            end 
                OVER_STA:   begin
                                if(~i_ad_cal_over)
                                    ad_cal_finish   <= 'b1;
                            end
                default:    begin
                                ad_mode         <= 'b0;  // 00,正常工作，01睡眠模式，10，POWER DOWN ,11 测试模式//   
                                ad_dly          <= 'b0;  //0~7 ,31~143度延迟--//
                                ad_cal_start    <= 'b0;
                                ad_cal_finish   <= 'b0;
                                dly_vl          <= 'b0;
                                comp_en         <= 'b0;
                                delay_tap_n0    <= 'b0;
                                delay_tap_n1    <= 'b0;
                                cur_sta         <= IDLE_STA ;
                            end
            endcase
        end
end
endmodule
