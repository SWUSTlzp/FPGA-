



///state 3

module state3(
    input           clk,
    input           rst_n,
    
    input           A,
    input           B,
    
    output          o_a,
    output          o_b


);


localparam         IDLE = 5'b00000,
                   S1   = 5'b00010,
                   S2   = 5'b00100,
                   S3   = 5'b01000,
                   S4   = 5'b10000;

reg     [ 4:0]     state_n;
reg     [ 4:0]     state_c;


always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

always @(*)begin
    case(state_c)
    IDLE:begin       
            state_n <= S1;
    end
    S1:begin
        if(A & B)begin
            state_n <= S2;
        end
        else begin
            state_n <= state_c;
        end
    end
    S2:begin
        if(A)begin
            state_n <= S3;
        end
        else begin
            state_n <= state_c;
        end
    end
    S3:begin
        if(!A & B)begin
            state_n <= IDLE;
        end
        else if(A & !B)begin
            state_n <= S4;
        end
        else begin
            state_n <= state_c;
        end
    end
    S4:begin
        
    end
    default :begin
        state_n <= IDLE;
    end
    endcase

end

assign  o_a = (state_c == S1) | (state_c == S2);
assign  o_b = (state_c == S2);

reg     [ 4:0]    cur_sta;
reg     [ 4:0]    nex_sta;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cur_sta <= IDLE;
    end
    case(cur_sta)
    IDLE:begin       
            cur_sta <= S1;
    end
    S1:begin
        if(A & B)begin
            cur_sta <= S2;
        end
        else begin
            cur_sta <= S1;
        end
    end
    S2:begin
        if(A)begin
            cur_sta <= S3;
        end
        else begin
            cur_sta <= S2;
        end
    end
    S3:begin
        if(!A & B)begin
            cur_sta <= IDLE;
        end
        else if(A & !B)begin
            cur_sta <= S4;
        end
        else begin
            cur_sta <= S3;
        end
    end
    S4:begin
        cur_sta <= S4;
    end
    default :begin
        state_n <= IDLE;
    end
    endcase

end

assign  o_a = (cur_sta == S1) | (cur_sta == S2);
assign  o_b = (cur_sta == S2);


endmodule