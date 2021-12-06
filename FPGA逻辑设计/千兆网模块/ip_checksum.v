
module ip_checksum#(

    parameter    IP_VERSION   = 4'h4    ,
    parameter    IP_HEDLEN    = 4'h5    , // 
    parameter    IP_SEV_TPYE  = 8'h00   ,
    parameter    IP_FD_IP     = 16'h00  ,
    parameter    IP_UNUSE     = 1'b0    ,
    parameter    IP_DF        = 1'b0    ,
    parameter    IP_MF        = 1'b0    ,
    parameter    IP_OFFSET    = 13'h0   ,
    parameter    IP_LIFE      = 8'h0    ,
    parameter    IP_PROTOCOL  = 8'h0    
)
(

    input               clk,
    input               rst_n,
    input               check_en,
    output   [15:0]     o_check_sum,
    input    [31:0]     ip_src_addr,
    input    [31:0]     ip_dst_addr
);


//sum
reg     [31:0]          sum;
reg     [16:0]          acc_sum_low; //17位包含进位
reg     [15:0]          check_sum;

assign o_check_sum = check_sum;

//通过check_en 进行校验和的计算
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        sum <= 'd0;
    end 
    else if(check_en)begin
        sum <= {IP_VERSION, IP_HEDLEN, IP_SEV_TPYE} + 
                IP_FD_IP + {IP_UNUSE, IP_DF, IP_MF, IP_OFFSET} +
                {IP_LIFE ,IP_PROTOCOL} + ip_src_addr[31:16] + ip_src_addr[15:0] + 
                ip_dst_addr[31:16] + ip_dst_addr[15:0];
    end
end

//acc_sum_low
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        acc_sum_low <= 'd0;
    end
    else begin
        acc_sum_low <= sum[31:16] + sum[15:0];
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        check_sum <= 'd0;
    end
    else begin
        check_sum <= ~(acc_sum_low[15:0] + acc_sum_low[16]);
    end
end

endmodule
