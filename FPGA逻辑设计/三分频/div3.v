

`timescale 1 ns/ 1 ps
module div3(
    input           clk     ,
    input           rst_n   ,
    output reg      div_clk

);
/*

    1、上升沿，下降沿计数。

*/
///reg     [ 1:0]      cnt_pro;
///reg     [ 1:0]      cnt_neg;
///reg                 div_3_o1;
///reg                 div_3_o2;
///
///
///
///always@(posedge clk or negedge rst_n)begin
///    if(!rst_n)begin
///         cnt_pro <= 'd0;
///    end
///    else begin 
///         if(cnt_pro == 'd2)
///             cnt_pro <= 'd0;
///         else
///             cnt_pro <= cnt_pro + 1'b1;
///    end
///
///end
///
///always@(negedge clk or negedge rst_n)begin
///    if(!rst_n)begin
///         cnt_neg <= 'd0;
///    end
///    else begin 
///         if(cnt_neg == 'd2)
///             cnt_neg <= 'd0;
///         else
///             cnt_neg <= cnt_neg + 1'b1;
///    end
///end
///
///always@(posedge clk or negedge rst_n)begin
///    if(!rst_n)begin
///        div_3_o1 <= 1'b0;
///    end
///    else if(cnt_pro == 'd1)
///        div_3_o1 <= 1'b1;
///    else 
///        div_3_o1 <= 1'b0;
///end
///
///always@(negedge clk or negedge rst_n)begin
///    if(!rst_n)begin
///        div_3_o2 <= 1'b0;
///    end
///    else if(cnt_pro == 'd1)
///        div_3_o2 <= 1'b1;
///    else 
///        div_3_o2 <= 1'b0;
///end
///
///
///assign  div_clk = div_3_o1 | div_3_o2;


/*

    2、状态机
    三分频，一个检测上升沿，一个检测下降沿，发送序列010 010
*/

reg    [ 1:0]    step_a;
reg    [ 1:0]    step_b;
reg              clka;
reg              clkb;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        step_a <= 2'b00;
        clka   <= 1'b0;
    end
    else begin
        case(step_a)
            2'b00:begin     
                clka   <= 1'b0;
                step_a <= 2'b01;
            end
            2'b01:begin     
                clka   <= 1'b1;
                step_a <= 2'b10;
            end
            2'b10:begin     
                clka   <= 1'b0;
                step_a <= 2'b00;
            end
            default:begin
                clka   <= 1'b0;
                step_a <= 2'b00;
            end
        endcase
    end
end

always@(negedge clk or negedge rst_n)begin
    if(!rst_n)begin
        step_b <= 2'b00;
        clkb   <= 1'b0;
    end
    else begin
        case(step_b)
            2'b00:begin     
                clkb   <= 1'b0;
                step_b <= 2'b01;
            end
            2'b01:begin     
                clkb   <= 1'b1;
                step_b <= 2'b10;
            end
            2'b10:begin   
                clkb   <= 1'b0;            
                step_b <= 2'b00;
            end
            default:begin
                clkb   <= 1'b0;
                step_b <= 2'b00;
            end
        endcase
    end
end

assign  div_clk = clka | clkb;

/*
    状态机
    占空比1:2 
*/

//parameter[1:0]  S0=2'd0,
//
//               S1=2'd1,
//
//               S2=2'd2;
//
//reg[1:0] state,next_state;
//
//always @ (posedge clk or negedge rst_n)
//
//    begin
//
//     if(!rst_n)
//
//           state<=S0;
//
//      else    
//
//          state<=next_state;
//
//    end
//
//always @ (state)
//
//    begin
//
//    //default values
//
//     next_state=S0;
//
//    case (state)
//
//    S0:
//
//        begin
//
//           next_state=S1;
//
//          div_clk=0;
//
//        end
//
//   S1:
//
//        begin
//
//          next_state=S2;
//
//          div_clk=0;
//
//       end
//
//   S2:
//
//        begin
//
//          next_state=S0;
//
//          div_clk=1;
//
//       end
//
//   endcase
//
//   end



endmodule
