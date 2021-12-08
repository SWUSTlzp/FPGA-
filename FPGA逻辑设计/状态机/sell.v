
// 假设饮料的价格统一为2.5rmb
module sell(
    input               half_rmb    ,
    input               one_rmb     ,
    input               rst_n       ,
    input               clk         ,
    output  [ 7:0]      o_sell_count,
    output              o_half_out  ,
    output  [ 4:0]      o_rmb_cnt

);
localparam      IDLE = 5'b00000,
                HALF = 5'b00010,
                ONE  = 5'b00100,
                TWO  = 5'b01000,
                THREE= 5'b10000;
reg     [ 7:0]      sell_count;
reg                 half_out;
reg     [ 4:0]      rmb_cnt;

reg     [ 4:0]      state_c;
reg     [ 4:0]      state_n;

reg                 half_rmb_r;
reg                 half_rmb_rr;
wire                half_rmb_p;
reg                 one_rmb_r ;
reg                 one_rmb_rr;
wire                one_rmb_p;

assign o_sell_count  = sell_count;
assign o_half_out    = half_out  ;
assign o_rmb_cnt     = rmb_cnt   ;

assign half_rmb_p  = half_rmb_r & ~half_rmb_rr;
assign one_rmb_p   = one_rmb_r & ~one_rmb_rr;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        half_rmb_r  <= 1'b0;
        half_rmb_rr <= 1'b0;
        one_rmb_r   <= 1'b0;
        one_rmb_rr  <= 1'b0;   
    end
    else begin
        half_rmb_r <= half_rmb;
        half_rmb_rr <= half_rmb_r;
        one_rmb_r  <= one_rmb;
        one_rmb_rr <= one_rmb_r;
    end
end


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
            if(half_rmb_p == 1'b1)begin
                state_n <= HALF;
            end
            else if(one_rmb_p == 1'b1)begin
                state_n <= ONE;
            end
            else begin
                state_n <= state_c;
            end
        end
        HALF:begin  //0.5
            if(half_rmb_p == 1'b1)begin
                state_n <= ONE;
            end
            else if(one_rmb_p == 1'b1)begin
                state_n <= TWO;
            end
            else begin
                state_n <= state_c;
            end
        end
        ONE:begin  //1
            if(half_rmb_p == 1'b1)begin
                state_n <= TWO;
            end
            else if(one_rmb_p == 1'b1)begin
                state_n <= THREE;    
            end
            else begin
                state_n <= state_c;
            end
        end
        TWO:begin // 1.5
            if(half_rmb_p == 1'b1)begin
                state_n <= THREE;
            end
            else if(one_rmb_p == 1'b1)begin
                state_n <= IDLE;
            end
            else begin
                state_n <= state_c;
            end
        end
        THREE:begin //2   
            if(half_rmb_p == 1'b1 || one_rmb_p == 1'b1)
                state_n <= IDLE;
        end     
    endcase
end

////sell_count
////half_out  
////rmb_cnt   
//
//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        sell_count <= 'd0;
//    end
//    else if(state_c == TWO && one_rmb_p == 1'b1)begin
//        sell_count <= sell_count + 1'b1;
//    end
//    else if(state_c == THREE && half_rmb_p == 1'b1)begin
//        sell_count <= sell_count + 1'b1;
//    end
//    else if(state_c == THREE && one_rmb_p == 1'b1)begin
//        sell_count <= sell_count + 1'b1;
//    end
//      
//end

//always @(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        sell_count <= 'd0;
//    end
//    case(state_c) 
//        IDLE:begin
//            
//        end
//        HALF:begin  //0.5
//            
//        end
//        ONE:begin  //1
//           
//        end
//        TWO:begin // 1.5
//            if(one_rmb_p == 1'b1)begin
//                sell_count <= sell_count + 1'b1;
//            end
//        end
//        THREE:begin //2   
//            if(half_rmb_p == 1'b1)begin
//                sell_count <= sell_count + 1'b1;
//            end
//        end
//        default:begin
//            sell_count <= 'd0;
//        end
//    endcase
//end


endmodule
