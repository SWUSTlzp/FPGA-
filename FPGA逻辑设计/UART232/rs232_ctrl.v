
//每次传输8个字节

module rs232_ctrl
#(
	parameter CLK_REF = 100,      //clock frequency(Mhz)
	parameter BAUD_RATE = 115200 //serial baud rate
)
(

    input                   clk_ref          ,
    input                   rst_n            ,
    input                   i_rs232_start_en , // rs232 开始标志使能
    output                  o_rs232_cfg_over ,
    output       [3:0]      o_ctrl_cnt       ,
    output                  o_rs232_busy

   
);
parameter          IDLE  = 4'b0000;
parameter          START = 4'b0001;
parameter          RUN   = 4'b0010;
parameter          STOP  = 4'b0100;
parameter  rs232_clk_num = CLK_REF * 1000000 / BAUD_RATE;


reg        [ 3:0]       ctrl_cnt;  // 0-9

reg     [ 3:0]     state_c;
reg     [ 3:0]     state_n;

///////  state wire
wire         idle2start_start; 
wire         start2run_start ; 
wire         run2stop_start  ; 
wire         stop2idle_start ; 
///////
reg          rs232_dat_end   ; 
reg          rs232_run_en    ; 
reg          rs232_cfg_over ;
reg          rs232_busy      ;
//////输入使能上升沿
reg                 rs232_start_en_t;
reg                 rs232_start_en_tt;
wire                rs232_start_en_pro;


reg     [ 9:0]      clk_cnt;
wire                add_clk_cnt;
wire                end_clk_cnt;

assign       o_ctrl_cnt  = ctrl_cnt;
assign       o_rs232_cfg_over = rs232_cfg_over; 
assign       o_rs232_busy    = rs232_busy;



always@(posedge clk_ref)begin
    rs232_start_en_t <= i_rs232_start_en;
    rs232_start_en_tt<= rs232_start_en_t;
end

assign rs232_start_en_pro = (!rs232_start_en_tt) & rs232_start_en_t;


 


always @(posedge clk_ref or negedge rst_n)begin
        if(!rst_n)begin
            clk_cnt <= 'd0;
    end
    else if(add_clk_cnt)begin
        if(end_clk_cnt)
            clk_cnt <= 'd0;
    else
            clk_cnt <= clk_cnt + 1'b1;
end
end

assign add_clk_cnt = rs232_busy == 1'b1;       
assign end_clk_cnt = add_clk_cnt && clk_cnt== rs232_clk_num - 1;

 

always@(posedge clk_ref or negedge rst_n)begin
    if(!rst_n)begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

always@(*)begin
    case(state_c)
        //空闲
        IDLE:begin
            if(idle2start_start)begin
                state_n = START;
            end
            else begin
                state_n = state_c;
            end
        end
        //起始位
        START:begin
            if(start2run_start)begin
                state_n = RUN;
            end
            else begin
                state_n = state_c;
            end
        end
        //数据位
        RUN:begin
            if(run2stop_start)begin
                state_n = STOP;
            end
            else begin
                state_n = state_c;
            end
        end
        //停止位
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

assign idle2start_start  = state_c    ==   IDLE    && rs232_start_en_pro ;
assign start2run_start   = state_c    ==   START   && rs232_run_en     ;
assign run2stop_start    = state_c    ==   RUN     && rs232_dat_end  ;
assign stop2idle_start   = state_c    ==   STOP    && rs232_cfg_over;

always  @(posedge clk_ref or negedge rst_n)begin
    if(!rst_n)begin
        ctrl_cnt        <=  'd0;    
        rs232_run_en    <= 1'b0; 
        rs232_busy      <= 1'b0;
        rs232_cfg_over  <= 1'b0;
        rs232_dat_end   <= 1'b0;
    end
    else if(state_c == IDLE)begin
        if(i_rs232_start_en == 1'b1)begin
            rs232_busy <= 1'b1;
        end
        rs232_cfg_over <= 1'b0;        
    end
    else if(state_c == START)begin
        if(end_clk_cnt == 1'b1)begin
            rs232_run_en <= 1'b1;
            ctrl_cnt  <= ctrl_cnt + 1'b1; 
        end
    end
    else if(state_c == RUN) begin
        if(end_clk_cnt == 1'b1 && ctrl_cnt == 'd8)begin
            rs232_dat_end <= 1'b1;
            ctrl_cnt  <= ctrl_cnt + 1'b1;    
        end
        else if(end_clk_cnt == 1'b1)begin
            ctrl_cnt  <= ctrl_cnt + 1'b1; 
        end
        rs232_run_en <= 1'b0;
    end
    else if(state_c == STOP)begin
        if(end_clk_cnt == 1'b1)begin
            ctrl_cnt  <= 'd0;           
            rs232_cfg_over <= 1'b1;
            rs232_busy <= 1'b0;
        end
        rs232_dat_end   <= 1'b0;
    end
    else begin
        ctrl_cnt        <=  'd0;
        rs232_run_en    <= 1'b0;
        rs232_cfg_over  <= 1'b0;
        rs232_dat_end   <= 1'b0;
    end
end





endmodule
