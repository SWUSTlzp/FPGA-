module ddr3_dat_gen(

    input                   rst_n            ,
    input                   ddr_clk          ,
    input                   i_int_done       ,//ddr_clk
    output  wire            o_wr_ireq        ,
    output  wire [15:0]     o_wr_len         ,
    output  wire [26:0]     o_wr_addr        ,
    output  wire [511:0]    o_wr_dat         ,
    output  wire            o_rd_ireq        ,
    output  wire [15:0]     o_rd_len         ,
    output  wire [26:0]     o_rd_addr        ,
    input                   i_wr_den         ,
    input                   app_rdy          ,
    input        [511:0]    app_rd_data      ,
    output  wire [ 6:0]     app_burstcount   ,
    output  wire [63:0]     app_byteenable   ,
    input                   app_rd_data_valid
    
);

wire                idl2wai_start  ;
wire                wai2wrrq_start ;
wire                wrrq2wrin_start;
wire                wrin2rdrq_start;
wire                rdrq2rdin_start;
wire                rdin2wai_start ;
reg      [ 4:0]     state_c        ;
reg      [ 4:0]     state_n        ;
/////////////////////////
reg      [ 6:0]     wr_cnt         ;
reg      [ 6:0]     rd_cnt         ;
reg                 rd_req         ;
reg                 wr_req         ;
reg      [26:0]     rd_addr        ;
reg      [26:0]     wr_addr        ;
reg                 rd_req_r       ;
reg                 wr_flag        ;
reg      [511:0]    wr_dat         ;
reg      [511:0]    rd_data        ;

reg                 app_rd_data_valid_r  ;
reg                 app_rd_data_valid_rr ;
reg                 app_rd_data_valid_neg;


assign  app_byteenable = {64{1'b1}};
assign  app_burstcount = 'd64;
assign  o_wr_ireq = wr_req;
assign  o_wr_len  = 'd512;
assign  o_wr_addr = wr_addr;
assign  o_wr_dat  = wr_dat;
assign  o_rd_ireq = rd_req;
assign  o_rd_len  = 'd512;
assign  o_rd_addr = rd_addr;


    parameter     IDLE   = 5'h0     ;
    parameter     WAIT   = 5'h1     ;
    parameter     WR_REQ = 5'h2     ;
    parameter     WR_IN  = 5'h4     ;
    parameter     RD_REQ = 5'h8     ;
    parameter     RD_IN  = 5'h10    ;

//always@(posedge ddr_clk or negedge rst_n)begin
//    if(!rst_n)begin
//         app_rd_data_valid_r    <= 'd0;
//         app_rd_data_valid_rr   <= 'd0;
//         app_rd_data_valid_neg  <= 'd0;
//    end
//    else begin
//        app_rd_data_valid_r <= app_rd_data_valid;
//        app_rd_data_valid_rr<= app_rd_data_valid_r;
//        if((~app_rd_data_valid_r)&&app_rd_data_valid_rr)begin
//            app_rd_data_valid_neg <= 1'b1;
//        end
//        else begin
//            app_rd_data_valid_neg <= 1'b0;
//        end
//    end
//end
//

// int_done || rd_flag -- wr_flag 
always@(posedge ddr_clk or negedge rst_n)begin
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
            if(idl2wai_start)begin
                state_n = WAIT;
            end
            else begin
                state_n = state_c;
            end
        end
        WAIT:begin
            if(wai2wrrq_start)begin
                state_n = WR_REQ;
            end
            else if(wai2rdrq_start)begin
                state_n = RD_REQ;
            end
            else begin
                state_n = state_c;
            end
        end
        WR_REQ:begin
            if(wrrq2wrin_start)begin
                state_n = WR_IN;
            end
            else begin
                state_n = state_c;
            end
        end
        WR_IN:begin
            if(wrin2rdrq_start)begin
                state_n = IDLE;
            end
            else begin
                state_n = state_c;
            end
        end
        RD_REQ:begin
            if(rdrq2rdin_start)begin
                state_n = RD_IN;
            end
            else begin
                state_n = state_c;
            end
        end
        RD_IN:begin
            if(rdin2wai_start)begin
                state_n = WAIT;
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

assign idl2wai_start    = state_c == IDLE   && i_int_done;
assign wai2wrrq_start   = state_c == WAIT   && (wr_dat <= {25{1'b1}});
assign wai2rdrq_start   = state_c == WAIT   && (rd_addr<= {25{1'b1}});
assign wrrq2wrin_start  = state_c == WR_REQ && i_wr_den == 1'b1;
assign wrin2rdrq_start  = state_c == WR_IN  && wr_cnt == 'd63;
assign rdrq2rdin_start  = state_c == RD_REQ && app_rd_data_valid == 1'b1;
assign rdin2wai_start   = state_c == RD_IN  && rd_cnt == 'd63;

////wr_flag
//always  @(posedge ddr_clk or negedge rst_n)begin
//    if(!rst_n)begin
//        wr_flag <= 1'b0;      
//    end
////    else if(state_c == WR_IN && process_cnt == 'd63)begin
//    else if(wr_inpro_pro)begin
//        wr_flag <= 1'b1;
//    end
////    else if(state_c == RD_IN && process_cnt == 'd63)begin
//    else if(wr_inpro_neg == 1'b1)begin
//        wr_flag <= 1'b0;
//    end
//    else if(rd_inpro_pro)begin
//        wr_flag <= 1'b0;
//    end
//end
//
//wr_req 
always  @(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_req <= 1'b0;     
    end
    else if(state_c == WR_REQ)begin
        wr_req <= 1'b1;
    end
    else begin
        wr_req <= 1'b0;
    end
end
//rd_req
always  @(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_req <= 1'b0;      
    end
    else if(state_c == RD_REQ)begin
        rd_req <= 1'b1;
    end
    else begin
        rd_req <= 1'b0;
    end
end
always@(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_cnt <= 'd0;
    end
    else if(wr_cnt == 'd63)
        wr_cnt <= 'd0;
    else if(i_wr_den == 1'b1 && app_rdy)begin
        wr_cnt <= wr_cnt + 1'b1;  
    end
    

end
always@(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_cnt <= 'd0;
    end
    else if(rd_cnt == 'd63)begin
        rd_cnt <= 'd0;  
    end
    else if(app_rd_data_valid)begin
        rd_cnt <= rd_cnt + 1'b1;
    end
end
//wr_addr
always  @(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_addr <= 'd0;      
    end
//    else if(state_c == WR_IN && process_cnt == 'd63)begin
    else if(wr_cnt == 'd63)begin
        wr_addr <= wr_addr + 27'd64;
    end
end
//rd_addr
always  @(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_addr <= 'd0;      
    end
//    else if(state_c == RD_IN && process_cnt == 'd63)begin
    else if(rd_cnt == 'd63)begin
        rd_addr <= rd_addr + 27'd64;
    end
end
//wr_dat
always  @(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_dat <= 'd0;      
    end
    else if(i_wr_den && app_rdy)begin
        wr_dat <= wr_dat + 1'b1;
    end
end
always@(posedge ddr_clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_data <= 'd0;
    end
    else if(state_c == RD_IN && app_rdy)begin
        rd_data <= app_rd_data;
    end
    
end




endmodule
