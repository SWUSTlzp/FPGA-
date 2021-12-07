

module mult_add_demo (
input clk,
input rst,
input [15:0] ad_din,
output [15:0] ad_ndc


);
localparam WIDTH_RESULT =32;
localparam DATA_WIDTH =16;
wire  [31:0] result;
wire  [15:0] K;
wire  [15:0] dc;

wire  [15:0] neg_result = -result[(WIDTH_RESULT - 1) -: DATA_WIDTH];  //V1的负数
//wire signed [31:0] ACOUT;
assign dc = result[31:16];
assign ad_ndc = ad_din - dc;
assign K = 16'h0085;

mult_add_ip u0 (
		.accum_sload (1'b1                  ), // accum_sload.accum_sload
        .result      (result                ),//output
		.dataa_0     (neg_result            ),//input //
		.datab_0     (ad_din                ),//input // a,b  V2 - V1
		.clock0      (clk                   ),//
		.datac_0     (K                     ),//input        (V2 - V1)*K
		.chainin     (result                ),//input
		.sclr0       (rst                   ), //
        .ena0        (1'b1                  ),     //    ena0.ena0
        .negate      (1'b0                  )       //      negate.negate
	);


endmodule 