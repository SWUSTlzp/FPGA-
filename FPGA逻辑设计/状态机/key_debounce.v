
//按键消抖

module key_debounce( 
    
    input         clk     , //100M 
    input         rst_n   ,
    input         i_key   ,
    output  reg   o_key
    
);
///通过延时的方式，机械抖动一般在5-10ms。
//设计采用10ms 0.01

//1、误触        2、抖动
localparam          IDLE   =  4'b0000,
                    S1     =  4'b0010,
                    S2     =  4'b0100,
                    S3     =  4'b1000;
                    
                    
wire                idl2s1_start;
wire                s12s2_start ;
wire                s22s3_start ;
wire                s32idl_start;

reg                 key_r;
reg                 key_rr;
wire                key_pro;
wire                key_neg;

reg      [ 3:0]     state_c;
reg      [ 3:0]     state_n;

reg      [19:0]     cnt;
wire                add_cnt;
wire                end_cnt;

always@(posedge clk or negedge rst_n)begin
    key_r    <= i_key;
    key_rr   <= key_r;
end
//assign  key_pro = ~key_rr & key_r;
//assign  key_neg = ~key_r & key_rr;
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
            cnt <= 'd0;
    end
    else if(add_cnt)begin
        if(end_cnt)
            cnt <= 'd0;
    else
            cnt <= cnt + 1'b1;
end
end

assign add_cnt = (state_c==S1 || state_c == S3);       
assign end_cnt = add_cnt && cnt== 1000000 - 1;

always@(posedge clk or negedge rst_n)begin
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
            if(idl2s1_start)begin
                state_n = S1;
            end
            else begin
                state_n = state_c;
            end
        end
        S1:begin
            if(s12idl_start)begin
                state_n = IDLE;
            end
            else if(s12s2_start)begin
                state_n = S2;
            end
            else begin
                state_n = state_c;
            end
        end
        S2:begin
            if(s22s3_start)begin
                state_n = S3;
            end
            else begin
                state_n = state_c;
            end
        end
        S3:begin
            if(s32idl_start)begin
                state_n = IDLE;
            end
            else if(s32s2_start)begin
                state_n = S2;
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

assign idl2s1_start  = state_c==IDLE && key_rr == 1'b0;
assign s12idl_start  = state_c==IDLE && key_rr == 1'b1 && end_cnt == 1'b0;
assign s12s2_start = state_c  ==S1   && end_cnt == 1'b1;
assign s22s3_start  = state_c ==S2  && key_rr == 1'b1;
assign s32s2_start  = state_c ==S3 && key_rr == 1'b0 && end_cnt == 1'b0;
assign s32idl_start  = state_c == S3 && end_cnt == 1'b1;

always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        o_key <= 1'b1;      
    end
    else if(idl2s1_start)begin
        o_key <= 1'b0;
    end
    else if(s32idl_start)begin
        o_key <= 1'b1;
    end
end

endmodule
