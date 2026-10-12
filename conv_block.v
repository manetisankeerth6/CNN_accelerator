`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2026 10:35:47 PM
// Design Name: 
// Module Name: conv_block
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module conv_block#(parameter int shift=3)(input logic clk, input logic rst, input logic winv, input logic [71:0]win, input logic [17:0]w, input logic signed[15:0]bias, output logic outv,output logic [7:0]pixout);
function automatic logic signed [12:0]wed(input logic [7:0]p, input logic[1:0]w);
case(w)
2'b01:wed= $signed({5'b00000,p});
2'b11:wed= -$signed({5'b00000,p});
default:wed= 13'b0000000000000;
endcase
endfunction
logic signed[12:0] dotc, dotq;
logic signed[17:0] biased, scaled;
logic v1;
assign biased=dotq+bias;
assign scaled=biased>>>shift;
always_comb begin
dotc=13'sd0;
for(integer c=0;c<9;c++)
dotc=dotc+wed(win[8*c+:8],w[2*c+:2]);
end
always_ff @(posedge clk)begin
dotq<=dotc;
v1<=winv;
if(scaled<0) pixout<=8'd0;
else if(scaled>255) pixout<=8'd255;
else pixout<=scaled[7:0];
outv<=v1;
if(rst)begin
v1<=1'd0;
outv<=1'd0;
end
end
endmodule