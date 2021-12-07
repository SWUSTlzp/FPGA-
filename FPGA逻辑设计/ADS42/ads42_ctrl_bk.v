`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/22 10:54:01
// Design Name: 
// Module Name: pll2581_ctrl_bk
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


module ads42_ctrl_bk
(
input           sys_clk         ,
input           rst_n           ,
input           i_pll_locked    ,
                                
input[3:0]      i_ad_mode       ,  //0100 闂侇偅甯掗·鍐极鐢喚绀000婵繐绲介悥璺何熼垾宕囩//
input[2:0]      i_ad_dly        ,
input           i_cha_volt_sel  , 
input           i_chb_volt_sel  ,
input           i_ad_cal_start  ,
input           i_ad_cal_finish ,
output          o_ad_cal_over   ,
output          o_ad_inital_over,                                
                                
output[15:0]    o_dat_in        ,
output          o_opt_start     ,
output[7:0 ]    o_opt_cnt       ,
                                
input[7:0]      i_dat_out       ,
input           i_dat_vaild     ,
input           i_spi_done      ,

output          o_ad_reset      ,

output          o_over_finish   

    );


///------濠碘€冲€归悘澶嬫櫠閻愭彃顫ｉ柡宥忕節閻涙瑩寮甸崫鍕厬闁挎稑鑻崹顖炴閳ь剛鎲版担瑙勭函闁衡偓閻熸壆妲戦悗娑櫭▍鎺楀磹绾绀xf,闁哄洤鐡ㄩ弫鍏肩▔閻戞銈撮悹鍥ㄦ礋閳ь剚甯掗·鍐极閻楀煬浣割嚕韫囥儳绀夐柣鎺曟硾閹寮寸€涙ɑ鏆x16闁汇劌瀚鍌炴煢閻旈攱顐介弶鈺冨枎閵囧洨浜歌箛銉х閺夆晜绋栭、鎴﹀冀閿熺姷宕/
parameter       RST_PAR  = {2'b10,6'h08,8'h00} ; //spi_reset//                   
parameter       R06_PAR  = {2'b10,6'h06,8'h80}  ;  //DIV =1//
parameter       R07_PAR  = {2'b10,6'h07,8'h01}  ;  //sync_delay=0,閻犲鍟弳锝咁嚈閹壆绠块柣
//parameter       R08_PAR  = {2'b00,6'h08,8'h0C}  ;  //鐎规悶鍎扮紞鏂课熼垾宕囩,DIS CTRL PINS = 1//
parameter       R08_PAR  = {2'b00,6'h08,8'h14}  ;  //鐎规悶鍎扮紞鏂课熼垾宕囩,DIS CTRL PINS = 1//
wire[15:0]      R0B_PAR  = i_cha_volt_sel ? {2'b00,6'h0B,5'b10011,1'b1,1'b0,1'b0} : {2'b00,6'h0B,5'b00000,1'b1,1'b0,1'b0}  ;  //A濠⒀呭仧濞夘厽鎷呴懗顖氬幋闁挎稑濂旀禍鎺楀矗婵犲嫮鍊抽弶鐑嗗墴閻濐喗鎷呮惔婵堢Т//
wire[15:0]      R0C_PAR  = i_chb_volt_sel ? {2'b00,6'h0C,5'b10011,1'b1,2'b00} :     {2'b00,6'h0C,5'b00000,1'b1,1'b0,1'b0}  ;  //B濠⒀呭仧濞夘厽鎷呴懗顖氬幋闁挎稑濂旀禍鎺楀矗婵犲啫顒㈤柛鎴犲劋閻栵綀绠涘Δ鍕炕闁告垹鍎ら悧绋款嚕/
//parameter       R0D_PAR  = {2'b00,6'h0D,8'h6c}  ;  //闁哄拋鍣ｉ埀顒佺鐎涒晠宕欓悮瀵哥闊浂鍋婇埀顒傚枑鐎涒晠宕欏ú顏佸亾婢跺顏/
parameter       R0D_PAR  = {2'b10,6'h0D,8'h24}  ;  //闁哄拋鍣ｉ埀顒佺鐎涒晠宕欓悮瀵哥闊浂鍋婇埀顒傚枑鐎涒晠宕欏ú顏佸亾婢跺顏/
parameter       R0F_PAR  = {2'b00,6'h0F,8'h00}  ;  //AB闂侇偅宀告禍楣冩儍閸曨剛銈撮悹鍥ㄦ礃鑶╃€
//parameter       R0F_PAR  = {2'b00,6'h0F,4'b0011,4'b0011}  ;  //AB闂侇偅宀告禍楣冩儍閸曨剛銈撮悹鍥ㄦ礃鑶╃€
parameter       R10_PAR  = {2'b10,6'h10,8'h80}  ;  //闁煎浜滈悾鐐▕婢跺銈撮悹鍥ㄦ礃閺嗙喖骞戝Δ淇爄t//
parameter       R11_PAR  = {2'b10,6'h11,8'h80}  ;  //闁煎浜滈悾鐐▕婢跺銈撮悹鍥ㄦ礃閺嗙喖骞戝ù顤╥t//
parameter       R12_PAR  = {2'b10,6'h12,8'h40}  ;  //闁煎浜滈悾鐐▕婢跺銈撮悹鍥ㄦ礃閺嗙喖骞戝Δ淇爄t//
parameter       R13_PAR  = {2'b10,6'h13,8'h40}  ;  //闁煎浜滈悾鐐▕婢跺銈撮悹鍥ㄦ礃閺嗙喖骞戝ù顤╥t//
//parameter       R14_PAR  = {2'b00,6'h14,8'h00}  ;  //LVDS閺夊牊鎸搁崵顓烆嚕閸濆嫬顔婇柨娑樼搼B闂侇偅宀告禍楣冨礂閹惰姤锛斿ù锝堝劵閸
parameter       R14_PAR  = {2'b10,6'h14,8'h0c}  ;  //LVDS閺夊牊鎸搁崵顓烆嚕閸濆嫬顔婇柨娑樼搼B闂侇偅宀告禍楣冨礂閹惰姤锛斿ù锝堝劵閸
parameter       R15_PAR  = {2'b00,6'h15,8'h01}  ;  //DDR/QDR婵☆垪鈧磭纭€闂侇偄顦扮€氥劑鏁嶇€规亼t0: 1 DDR,0 QDR//
parameter       R16_PAR  = {2'b00,6'h16,2'b0,5'b00101,1'b0}  ;  //DDR闁哄啫鐖奸幐鎾绘儍閸曨偅顐介弶
parameter       R17_PAR  = {2'b10,6'h17,8'h00}  ;  //QDR婵☆垪鈧磭纭€闁汇劌鍤堥梺顐ｅ哺娴滈箖寮崼鏇熷鐎点倖鍎肩换/
parameter       R18_PAR  = {2'b10,6'h18,8'h00}  ;  //QDR婵☆垪鈧磭纭€闁汇劌鍤夐梺顐ｅ哺娴滈箖寮崼鏇熷鐎点倖鍎肩换/
parameter       R1F_PAR  = {2'b10,6'h1F,8'h00}  ;  //闊浂鍋婇埀顒傚枑鐎涒晠宕欓悜姗嗘⒕婵炴潙顑囧▓鎴︽⒓閸績鍋
//parameter       R20_PAR  = {2'b10,6'h20,8'h00}  ;  //CTRL1&2闁活潿鍔嬬紞鏂库攦閵忕姴姣夐柡宥呮穿閻
parameter       R20_PAR  = {2'b10,6'h08,8'h00}  ;  //CTRL1&2闁活潿鍔嬬紞鏂库攦閵忕姴姣夐柡宥呮穿閻
    
localparam      IDLE_STA = 11'h000      ,
                RUN_STA  = 11'h001      ,
                ERUN_STA = 11'h002      ,
                INCR_STA = 11'h004      ,
                WAIT_STA = 11'h008      ,
                CAL_STA  = 11'h010      ,
                MODE_STA = 11'h020      ,
                EMODE_STA= 11'h040      ,
                DLY_STA  = 11'h080      ,
                EDLY_STA = 11'h100      ,
                OVER_STA = 11'h200      ,
                END_STA  = 11'h400      ;
reg [10:0]      cur_sta                 ;
reg [7:0]       dly_cnt                 ;
parameter       END_CNT  =   5'd20      ;  
reg [4:0]       opt_cnt                 ;
reg             cfg_over                ;
reg             int_cfg_over            ;

reg             opt_start               ;
reg [31:0]      opt_dat                 ;

reg[23:0]       ms20_cnt                ;
reg             ms20_en                 ;
localparam      END_20MS = 24'd2000000  ;
reg             ad_reset                ;

//---cal----//

reg [15:0]      cfg_dat                 ;
reg             ad_cal_over             ;
reg[4:0]        dly_code                ;

(*noprune*) reg[127:0]      rd_dat_reg              ;

assign          o_ad_reset = ad_reset   ;

assign  o_dat_in    = opt_dat           ;
assign  o_opt_start = opt_start         ;
assign  o_opt_cnt   = 8'd16             ; 
assign  o_over_finish = cfg_over        ;

assign  o_ad_inital_over = int_cfg_over ;
assign  o_ad_cal_over    = ad_cal_over  ;

always@ *
begin
    case(i_ad_dly)
        'd0: dly_code <= 5'b00101;
        'd1: dly_code <= 5'b00111;
        'd2: dly_code <= 5'b00000;
        'd3: dly_code <= 5'b01101;
        'd4: dly_code <= 5'b01110;
        'd5: dly_code <= 5'b01011;
        'd6: dly_code <= 5'b10100;
        'd7: dly_code <= 5'b10000;
        default: dly_code <= 5'b00101;
    endcase
end
always@ *
begin
    case(opt_cnt)
        'd0:    opt_dat <= RST_PAR      ;
        'd1:    opt_dat <= R06_PAR      ;
        'd2:    opt_dat <= R07_PAR      ;
        'd3:    opt_dat <= R08_PAR      ;
        'd4:    opt_dat <= R0B_PAR      ;
        'd5:    opt_dat <= R0C_PAR      ;
        'd6:    opt_dat <= R0D_PAR      ;
        'd7:    opt_dat <= R0F_PAR      ;
        'd8:    opt_dat <= R10_PAR      ;
        'd9:    opt_dat <= R11_PAR      ;
        'd10:   opt_dat <= R12_PAR      ;
        'd11:   opt_dat <= R13_PAR      ;
        'd12:   opt_dat <= R14_PAR      ;
        'd13:   opt_dat <= R15_PAR      ;
        'd14:   opt_dat <= R16_PAR      ;
        'd15:   opt_dat <= R17_PAR      ;
        'd16:   opt_dat <= R18_PAR      ;
        'd17:   opt_dat <= R1F_PAR      ;
        'd18:   opt_dat <= R20_PAR      ;
		  'd19:   opt_dat <= R20_PAR      ;
        default:opt_dat <= cfg_dat      ;
    endcase
end

always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        rd_dat_reg <= 'b0;
    else
        begin
            if(i_dat_vaild)
                begin
                    rd_dat_reg <= {rd_dat_reg,i_dat_out};
                end
             
        end
end
//鐎点倖鍎肩换0ms//
always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            ms20_cnt    <= 'b0;
            ms20_en     <= 'b0;
            ad_reset    <= 'b0;
        end
    else
        begin
            if(i_pll_locked)
                begin
                    if(ms20_cnt == END_20MS)
                        begin
                            ms20_cnt    <= ms20_cnt;
                            ms20_en     <= 'b1;
                        end
                    else
                        begin
                            ms20_cnt    <= ms20_cnt + 1'b1;
                            ms20_en     <= 'b0;
                        end
                end
            if(ms20_cnt == 'd128)
                ad_reset  <= 'b1;
            else if(ms20_cnt == 'd256)  
                ad_reset  <= 'b0;
        end
end

always@(posedge sys_clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            dly_cnt     <= 'b0      ; 
            opt_start   <= 'b0      ; 
            opt_cnt     <= 'b0      ; 
            ad_cal_over <= 'b0      ;
            cfg_over    <= 'b0      ;
            int_cfg_over<= 'b0      ;
            cfg_dat     <= 'b0      ;
            cur_sta     <= IDLE_STA ;
        end
    else
        begin
            case(cur_sta)
                IDLE_STA:   begin
                                dly_cnt   <= 'b0;
                                if(opt_cnt < END_CNT )
                                    begin
                                        if(ms20_en)
                                            cur_sta <= RUN_STA  ;
                                    end
                                else
                                    begin
                                        int_cfg_over <= 'b1;
													// cur_sta <= END_STA;
													 cur_sta  <= CAL_STA;
                                    end
                            end
                RUN_STA:    begin
                                opt_start   <= 'b1        ;
                                cur_sta     <=  ERUN_STA  ;
                            end
                ERUN_STA:   begin
                                if(i_spi_done)
                                    begin
                                        opt_start   <= 'b0      ;
                                        cur_sta     <=  INCR_STA;
                                    end
                            end
                INCR_STA:   begin
                                opt_cnt  <= opt_cnt + 1'b1  ;
                                cur_sta  <=  WAIT_STA    ;
                            end
                WAIT_STA:    begin
                                dly_cnt <= dly_cnt + 1'b1;
                                if(dly_cnt == 'hff)
                                    begin
                                        cur_sta     <= IDLE_STA ;
                                    end
                            end
                CAL_STA:    begin
                                if(i_ad_cal_start)
                                    begin
                                        cur_sta     <=  MODE_STA    ;
                                    end
                                else if(i_ad_cal_finish)
                                    begin
                                        cur_sta     <=  END_STA    ;
                                    end
                            end
                MODE_STA:   begin
                                opt_start   <= 'b1        ;
                                //cfg_dat     <= {2'b00,6'h0F,i_ad_mode,i_ad_mode};
                                cfg_dat     <= {2'b10,6'h15,i_ad_mode,i_ad_mode};
                                cur_sta     <=  EMODE_STA  ;
                            end
                EMODE_STA:  begin
                                if(i_spi_done)
                                    begin
                                        opt_start   <= 'b0      ;
                                        cur_sta     <=  DLY_STA;
                                    end
                            end
                
                DLY_STA:   begin
                                opt_start   <= 'b1        ;
                                //cfg_dat     <= {2'b00,6'h16,2'b0,dly_code,1'b0};
                                cfg_dat     <= {2'b10,6'h08,2'b0,dly_code,1'b0};
                                cur_sta     <=  EDLY_STA  ;
                            end
                EDLY_STA:  begin
                                if(i_spi_done)
                                    begin
                                        opt_start   <= 'b0      ;
                                        cur_sta     <=  OVER_STA;
                                    end
                            end
                OVER_STA:   begin
                                if(~i_ad_cal_start)
                                    begin
                                        ad_cal_over <= 1'b0;
                                        cur_sta     <=  CAL_STA;
                                    end
                                else
                                    ad_cal_over <= 1'b1;
                            end
                END_STA:   begin
                                cfg_over <= 'b1;
                            end
                default:    begin
                                dly_cnt     <= 'b0      ; 
                                opt_start   <= 'b0      ; 
                                opt_cnt     <= 'b0      ; 
                                ad_cal_over <= 'b0      ;
                                cfg_over    <= 'b0      ;
                                int_cfg_over<= 'b0      ;
                                cfg_dat     <= 'b0      ;
                                cur_sta     <= IDLE_STA ;
                            end
            endcase
        end
        
end    
//ila_0 u_ila_ad_spi
//(
//     .clk       (sys_clk),
//     .probe0    ({'b0,rd_dat_reg,opt_cnt})
//);    
endmodule
