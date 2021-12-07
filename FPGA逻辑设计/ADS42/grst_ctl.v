module grst_ctl(

    input   sys_100M,
    output  o_grst_n
);
reg    rst_n;
reg    [23:0] cnt = 24'd0;
always@(posedge sys_100M)begin
       if(cnt == 'hFFFFFF)begin
            rst_n = 1'b1;
            cnt <= cnt;
       end
       else begin
            cnt <= cnt + 1'b1;
            rst_n = 1'b0;
       end

end
 
assign o_grst_n = rst_n;

endmodule
