

//2021 12 6  gmii_tx 

/*

    MAC IP（UDP）组包
    根据输入的数据长度和数据可实现打包
    
    lzp
*/


module gmii_tx(

    input                clk           ,
    input                rst_n         ,
    input                i_tx_en       ,
    //mac  
    input     [47:0]     mac_src_addr  ,//6字节 48bit
    input     [47:0]     mac_dst_addr  ,//6字节
    //IP   
    input     [31:0]     ip_src_addr   ,
    input     [31:0]     ip_dst_addr   ,
    input     [15:0]     udp_src_port  ,
    input     [15:0]     udp_dst_port  ,
    input     [ 7:0]     udp_data_in   ,
    input     [15:0]     udp_data_len  ,
    output               o_dat_vl      ,
    output               o_tx_over     ,
    output    [ 7:0]     o_gmii_tx    
);
/*
IP报文首部: IP版本 0x4 IPv4 ;首部长度;服务类型;总长度;分段标识;保留位;DF;MF;段偏移;生存周期TTL;上层协议 0x11 UDP
//报文校验和;源IP地址;目的IP地址;可选字段（0字节不需要）

IP报文数据（UDP报文）:UDP报文首部;16位源端口号;16位目的端口号;16位UDP长度;16位UDP校验和（可以直接置0）;UDP报文数据;CRC校验
*/

parameter    PREAMBLE     = 8'h55;    
parameter    SOF          = 8'hd5;
parameter    TYPE         = 16'h0800;
parameter    IP_VERSION   = 4'h4;
parameter    IP_HEDLEN    = 4'h5; // 
parameter    IP_SEV_TPYE  = 8'h00;
parameter    IP_FD_IP     = 16'h00;
parameter    IP_UNUSE     = 1'b0;
parameter    IP_DF        = 1'b0;
parameter    IP_MF        = 1'b0;
parameter    IP_OFFSET    = 13'h0;
parameter    IP_LIFE      = 8'h0;
parameter    IP_PROTOCOL  = 8'h0;


parameter    IP_HED_LEN   = 16'd20;
parameter    UDP_HED_LEN  = 16'd8;

localparam      IDLE             =  6'b00_0000,
                TX_MAC_HED       =  6'b00_0001,
                TX_IP_HED        =  6'b00_0010,
                TX_UDP_HED       =  6'b00_0100,
                TX_UDP_DATA      =  6'b00_1000,
                TX_UDP_DATA_FILL =  6'b01_0000,
                TX_CRC           =  6'b10_0000;
                
localparam      MACHED_NUM       = 22,
                MACHED_WIDTH     = 5 ,
                IPHED_NUM        = 20,
                IPHED_WIDTH      = 5 ,
                UDPHED_NUM       = 8 ,
                UDPHED_WIDTH     = 4 ,
        //      UDPDAT_NUM       =  ,
                UDPDAT_WIDTH     = 16,//UDP数据最大长度为65507
        //      UDPFILL_NUM      = ,
                UDPFILL_WIDTH    = 16,
                CRC_NUM          =  4,
                CRC_WIDTH        =  3,
                PACKET_MIN_LEN   = 46;  //包的最小长度，如果不够的话需要对包进行补充0处理
                                        //PACKET_MIN_LEN（46） -  IP_HED_LEN（20） - UDP_HED_LEN（8）  = 最小数据长度
//状态跳转
wire                               idl2mh_start ;     
wire                               mh2ih_start  ; 
wire                               ih2uh_start  ;
wire                               uh2ud_start  ;
wire                               ud2df_start  ;
wire                               ud2crc_start ;
wire                               df2crc_start ;
wire                               crc2idl_start;

reg      [ 5:0]                    state_c;
reg      [ 5:0]                    state_n;

// 将输入的信号打一拍，通过寄存器暂存，防止外部输入错误。
reg      [MACHED_WIDTH - 1:0]      mached_cnt;       //7 + 1 + 6 + 6 + 2 == 22
wire                               add_mached_cnt;
wire                               end_mached_cnt;

reg      [IPHED_WIDTH - 1:0]       iphed_cnt;
wire                               add_iphed_cnt;
wire                               end_iphed_cnt  ;

reg      [UDPHED_WIDTH - 1:0]      udphed_cnt;
wire                               add_udphed_cnt;
wire                               end_udphed_cnt ;

reg      [UDPDAT_WIDTH - 1:0]      udpdat_cnt;
wire                               add_udpdat_cnt;
wire                               end_udpdat_cnt ;

reg      [UDPFILL_WIDTH - 1:0]     udpfill_cnt;
wire                               add_udpfill_cnt;
wire                               end_udpfill_cnt;

reg      [CRC_WIDTH - 1:0]         crc_cnt;
wire                               add_crc_cnt;
wire                               end_crc_cnt;

reg      [47:0]                    mac_src_addr_r; //00-FF-71-16-8D-21
reg      [47:0]                    mac_dst_addr_r; //16-AB-C5-00-23-C9
reg      [31:0]                    ip_src_addr_r ; //192.168.0.73
reg      [31:0]                    ip_dst_addr_r ; //192.168.0.1
reg      [15:0]                    udp_src_port_r; //8080
reg      [15:0]                    udp_dst_port_r; //8081


reg      [15:0]                    ip_total_len;
reg      [15:0]                    udp_total_len;
reg      [15:0]                    udp_data_len_r;
reg      [15:0]                    ip_head_checksum;
//check sum//
reg                                check_en  ;
wire     [15:0]                    check_sum ;
wire     [15:0]                    udp_checksum;
//tx_en
reg                                tx_en_r;
reg                                tx_en_rr;         
wire                               tx_en_pro;
reg      [ 7:0]                    data_out;
reg      [ 7:0]                    gmii_tx;
                                   
reg                                crc_init; 
reg                                crc_en  ;
wire     [31:0]                    crc_out ;
reg                                tx_over;
reg                                gmii_en;
reg                                dat_vl;
                                   
assign udp_checksum = 16'h0;
assign o_gmii_tx    = gmii_tx;
assign o_tx_over    = tx_over;
assign o_dat_vl     = dat_vl;
assign tx_en_pro    = ~tx_en_rr & tx_en_r;

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
            if(idl2mh_start)begin
                state_n = TX_MAC_HED;
            end
            else begin
                state_n = state_c;
            end
        end
        TX_MAC_HED:begin
            if(mh2ih_start)begin
                state_n = TX_IP_HED;
            end
            else begin
                state_n = state_c;
            end
        end
        TX_IP_HED:begin
            if(ih2uh_start)begin
                state_n = TX_UDP_HED;
            end
            else begin
                state_n = state_c;
            end
        end
        TX_UDP_HED:begin
            if(uh2ud_start)begin
                state_n = TX_UDP_DATA;
            end
            else begin
                state_n = state_c;
            end
        end
        TX_UDP_DATA:begin
            if(ud2df_start)begin
                state_n = TX_UDP_DATA_FILL;
            end
            else if(ud2crc_start)begin
                state_n = TX_CRC;
            end
            else begin
                state_n = state_c;
            end
        end
        TX_UDP_DATA_FILL:begin
            if(df2crc_start)begin
                state_n = TX_CRC;
            end
            else begin
                state_n = state_c;
            end
        end
        TX_CRC:begin
            if(crc2idl_start)begin
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

assign idl2mh_start  = state_c == IDLE             && tx_en_pro == 1'b1;
assign mh2ih_start   = state_c == TX_MAC_HED       && end_mached_cnt ;
assign ih2uh_start   = state_c == TX_IP_HED        && end_iphed_cnt  ;
assign uh2ud_start   = state_c == TX_UDP_HED       && end_udphed_cnt ;
assign ud2df_start   = state_c == TX_UDP_DATA      && end_udpdat_cnt && udp_data_len_r > 'd0 && (udp_data_len_r  < (PACKET_MIN_LEN - IP_HED_LEN - UDP_HED_LEN));
assign ud2crc_start  = state_c == TX_UDP_DATA      && end_udpdat_cnt && udp_data_len_r  >= (PACKET_MIN_LEN - IP_HED_LEN - UDP_HED_LEN) ;
assign df2crc_start  = state_c == TX_UDP_DATA_FILL && end_udpfill_cnt;
assign crc2idl_start = state_c == TX_CRC           && end_crc_cnt    ;

/////mac头计数
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        mached_cnt <= 'd0;
    end
    else if(add_mached_cnt)begin
        if(end_mached_cnt)
            mached_cnt <= 'd0;
        else
            mached_cnt <= mached_cnt + 1'b1;
    end
end

assign add_mached_cnt = state_c == TX_MAC_HED;       
assign end_mached_cnt = add_mached_cnt && mached_cnt== MACHED_NUM - 1;

/////IP头计数
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
            iphed_cnt <= 'd0;
    end
    else if(add_iphed_cnt)begin
        if(end_iphed_cnt)
            iphed_cnt <= 'd0;
        else
            iphed_cnt <= iphed_cnt + 1'b1;
    end
end

assign add_iphed_cnt = state_c == TX_IP_HED;       
assign end_iphed_cnt = add_iphed_cnt && iphed_cnt== IPHED_NUM - 1;

/////UDP头计数
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        udphed_cnt <= 'd0;
    end
    else if(add_udphed_cnt)begin
        if(end_udphed_cnt)
            udphed_cnt <= 'd0;
        else
            udphed_cnt <= udphed_cnt + 1'b1;
    end
end

assign add_udphed_cnt = state_c == TX_UDP_HED;       
assign end_udphed_cnt = add_udphed_cnt && udphed_cnt== UDPHED_NUM - 1;

/////UDP数据计数
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        udpdat_cnt <= 'd0;
    end
    else if(add_udpdat_cnt)begin
        if(end_udpdat_cnt)
            udpdat_cnt <= 'd0;
        else
            udpdat_cnt <= udpdat_cnt + 1'b1;
    end
end

assign add_udpdat_cnt = state_c == TX_UDP_DATA;       
assign end_udpdat_cnt = add_udpdat_cnt && udpdat_cnt== udp_data_len_r - 1;

/////填充数据计数，填充至最小的包长度
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        udpfill_cnt <= 'd0;
    end
    else if(add_udpfill_cnt)begin
        if(end_udpfill_cnt)
            udpfill_cnt <= 'd0;
        else
            udpfill_cnt <= udpfill_cnt + 1'b1;
    end
end

assign add_udpfill_cnt = state_c == TX_UDP_DATA_FILL;       
assign end_udpfill_cnt = add_udpfill_cnt && udpfill_cnt== PACKET_MIN_LEN - udp_data_len_r - 1;

/////CRC计数
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        crc_cnt <= 'd0;
    end
    else if(add_crc_cnt)begin
        if(end_crc_cnt)
            crc_cnt <= 'd0;
        else
            crc_cnt <= crc_cnt + 1'b1;
    end
end

assign add_crc_cnt = state_c == TX_CRC;       
assign end_crc_cnt = add_crc_cnt && crc_cnt == CRC_NUM - 1;


always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data_out <= 'd0;
    end
    else begin
        if(state_c == TX_MAC_HED)begin
            case(mached_cnt)
                0,1,2,3,4,5,6: data_out <= PREAMBLE;
                7:             data_out <= SOF;
                8:             data_out <= mac_src_addr_r[47:40];
                9:             data_out <= mac_src_addr_r[39:32];
                10:            data_out <= mac_src_addr_r[31:24];
                11:            data_out <= mac_src_addr_r[23:16];
                12:            data_out <= mac_src_addr_r[15: 8];
                13:            data_out <= mac_src_addr_r[ 7: 0];
                14:            data_out <= mac_dst_addr_r[47:40];
                15:            data_out <= mac_dst_addr_r[39:32];
                16:            data_out <= mac_dst_addr_r[31:24];
                17:            data_out <= mac_dst_addr_r[23:16];
                18:            data_out <= mac_dst_addr_r[15: 8];
                19:            data_out <= mac_dst_addr_r[ 7: 0];     
                20:            data_out <= TYPE          [15: 8];
                21:            data_out <= TYPE          [ 7: 0];
                default :begin
                    data_out <= 'd0;
                end
            endcase 
        end
        else if(state_c == TX_IP_HED)begin      //5*32/8 =20
            case(iphed_cnt)
                0:             data_out <= {IP_VERSION, IP_HEDLEN}                  ;     
                1:             data_out <= IP_SEV_TPYE                              ;
                2:             data_out <= ip_total_len[15:8]                       ;
                3:             data_out <= ip_total_len[ 7:0]                       ;
                4:             data_out <= IP_FD_IP[15:8]                           ;
                5:             data_out <= IP_FD_IP[ 7:0]                           ; 
                6:             data_out <= {IP_UNUSE, IP_DF, IP_MF, IP_OFFSET[12:8]};    
                7:             data_out <= IP_OFFSET[7:0]                           ; 
                8:             data_out <= IP_LIFE                                  ;
                9:             data_out <= IP_PROTOCOL                              ;
                10:            data_out <= check_sum[15:8]                          ;
                11:            data_out <= check_sum[ 7:0]                          ;
                12:            data_out <= ip_src_addr_r[31:24]                     ;
                13:            data_out <= ip_src_addr_r[23:16]                     ;
                14:            data_out <= ip_src_addr_r[15: 8]                     ;
                15:            data_out <= ip_src_addr_r[ 7: 0]                     ;
                16:            data_out <= ip_dst_addr_r[31:24]                     ;
                17:            data_out <= ip_dst_addr_r[23:16]                     ;
                18:            data_out <= ip_dst_addr_r[15: 8]                     ;
                19:            data_out <= ip_dst_addr_r[ 7: 0]                     ;
                default:begin
                    data_out <= 'd0;
                end
            endcase
        end
        else if(state_c == TX_UDP_HED) begin
        //16bit src_port + 16bit dst_port + 16bit udp_total_len + 16bit udp_checksum  
            case(udphed_cnt)
                0:             data_out <= udp_src_port_r[15:8];
                1:             data_out <= udp_src_port_r[ 7:0]; 
                2:             data_out <= udp_dst_port_r[15:8];
                3:             data_out <= udp_dst_port_r[ 7:0];
                4:             data_out <= udp_total_len[15:8];
                5:             data_out <= udp_total_len[7:0];
                6:             data_out <= udp_checksum[15:8];
                7:             data_out <= udp_checksum[ 7:0];
                default:begin
                    data_out <= 'd0;
                end
            endcase
        end
        else if(state_c == TX_UDP_DATA)begin
            data_out <= udp_data_in;
        end
        else if(state_c == TX_UDP_DATA_FILL)begin
            data_out <= 8'h00;
        end
        else if(state_c == TX_CRC)begin
        case(crc_cnt)
            0:  data_out <= crc_out[ 7: 0];
            1:  data_out <= crc_out[15: 8];
            2:  data_out <= crc_out[23:16];
            3:  data_out <= crc_out[31:24];
            default:begin
                data_out <= 'd0;
            end
        endcase
    end 
    end
end
//tx_en_pro  
always@(posedge clk )begin
    if(!rst_n)begin
        tx_en_r <= 1'b0;
        tx_en_rr <= 1'b0;
    end
    else begin
        tx_en_r <= i_tx_en;
        tx_en_rr <= tx_en_r;
    end
end

always@(posedge clk)begin
    if(!rst_n)begin
        mac_src_addr_r <= 'd0;
        mac_dst_addr_r <= 'd0;
        ip_src_addr_r  <= 'd0;  
        ip_dst_addr_r  <= 'd0;  
        udp_src_port_r <= 'd0;  
        udp_dst_port_r <= 'd0; 
    end
    else if(tx_en_pro == 1'b1)begin
        mac_src_addr_r <= mac_src_addr;
        mac_dst_addr_r <= mac_dst_addr;
        ip_src_addr_r  <= ip_src_addr;   
        ip_dst_addr_r  <= ip_dst_addr;   
        udp_src_port_r <= udp_src_port; 
        udp_dst_port_r <= udp_dst_port;
    end
end

always@(posedge clk)begin
    if(!rst_n)begin
        udp_data_len_r <= 'd0;
    end
    else begin
        udp_data_len_r <= udp_data_len;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        check_en <= 1'b0; 
    end
    else if(state_c == TX_MAC_HED && end_mached_cnt)begin
        check_en <= 1'b1;        
    end 
    else begin
        check_en <= 1'b0;
    end
end

//ip_total_len = 20字节ip头，8字节udp头，udp数据最小长度46; IP总长度不能超过65536
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        ip_total_len <= 'd0;
    end
    else if(tx_en_pro == 1'b1)begin   
        ip_total_len <= IP_HED_LEN + UDP_HED_LEN + udp_data_len_r;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        udp_total_len <= 'd0; 
    end
    else if(tx_en_pro == 1'b1)begin
        udp_total_len <= UDP_HED_LEN + udp_data_len_r;
    end
end
///////////GMII TIMING////////////////

//gmii_tx
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gmii_tx <= 'd0;
    end
    else if(gmii_en == 1'b1)begin
        gmii_tx <= data_out;
    end
    else begin
        gmii_tx <= 'd0;
    end 
end

//gmii_en
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gmii_en <= 1'b0; 
    end
    else if(add_mached_cnt == 1'b1)begin
        gmii_en <= 1'b1;
    end
    else if(tx_over == 1'b1)begin
        gmii_en <= 1'b0;
    end
end

//tx_over ---- 做了一个脉冲，也可以通过输入信号对其置0
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_over <= 1'b0; 
    end 
    else if(end_crc_cnt == 1'b1)begin
        tx_over <= 1'b1;
    end
    else begin
        tx_over <= 1'b0;
    end
end

////////////crc timing///////////////
//crc_init
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        crc_init <= 1'b0;
    end
    else if(add_mached_cnt)begin
        crc_init <= 1'b1;
    end
    else begin
        crc_init <= 1'b0;
    end
end

//crc_en  
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        crc_en <= 1'b0; 
    end
    else if(state_c == TX_IP_HED || state_c == TX_UDP_HED || state_c == TX_UDP_DATA || state_c == TX_UDP_DATA_FILL)begin
        crc_en <= 1'b1;
    end      
    else begin
        crc_en <= 1'b0;
    end
end
//data vaild UDP数据发送时置高
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        dat_vl <= 1'b0; 
    end
    else if(end_udphed_cnt == 1'b1)begin
        dat_vl <= 1'b1;
    end
    else if((udp_data_len_r  < (PACKET_MIN_LEN - IP_HED_LEN - UDP_HED_LEN)) && end_udpfill_cnt == 1'b1)begin
        dat_vl <= 1'b0;
    end
    else if((udp_data_len_r  >= (PACKET_MIN_LEN - IP_HED_LEN - UDP_HED_LEN)) && end_udpdat_cnt == 1'b1)begin
        dat_vl <= 1'b0;
    end
end

ip_checksum #(

    .IP_VERSION     (IP_VERSION ),
    .IP_HEDLEN      (IP_HEDLEN  ), // 
    .IP_SEV_TPYE    (IP_SEV_TPYE),
    .IP_FD_IP       (IP_FD_IP   ),
    .IP_UNUSE       (IP_UNUSE   ),
    .IP_DF          (IP_DF      ),
    .IP_MF          (IP_MF      ),
    .IP_OFFSET      (IP_OFFSET  ),
    .IP_LIFE        (IP_LIFE    ),
    .IP_PROTOCOL    (IP_PROTOCOL)
)   
u_ip_checksum
(
    .clk            (clk        ),
    .rst_n          (rst_n      ),
    .check_en       (check_en   ),
    .o_check_sum    (check_sum  ),
    .ip_src_addr    (ip_src_addr),
    .ip_dst_addr    (ip_dst_addr)

);

CRC32_D8 u_crc(
    .clk            (clk        ),
    .rst_n          (rst_n      ),
    .data_in        (data_out   ), //对IP包进行CRC校验
    .crc_init       (crc_init   ),
    .crc_en         (crc_en     ),
    .crc_out        (crc_out    )
 
);


endmodule
