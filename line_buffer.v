`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 11:10:54 PM
// Design Name: 
// Module Name: line_buffer
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


module line_buffer #(parameter int W=28,parameter int H=28)(input logic clk, input logic rst, input logic clr, input logic pixv, input logic [7:0]pixin, output logic winv, output logic [71:0]win);
localparam int L=2*W+1;
(*ram_style="distributed"*) logic [7:0]line0[0:W-1];
(*ram_style="distributed"*) logic [7:0]line1[0:W-1];
(*ram_style="distributed"*) logic [7:0]line2[0:W-1];
(*ram_style="distributed"*) logic [7:0]line3[0:W-1];
initial begin
for(integer i=0;i<W;i++)begin
line0[i]=8'd0;line1[i]=8'd0;line2[i]=8'd0;line3[i]=8'd0;
end
end
logic [7:0]win_r[0:2][0:2];
logic [5:0]col;
logic[1:0]wl;
logic[6:0]trsh;
logic [5:0] cx,cy,cxq,cyq;
logic [7:0]rd[0:3];
assign rd[0]=line0[col];
assign rd[1]=line1[col];
assign rd[2]=line2[col];
assign rd[3]=line3[col];
logic [7:0] top, mid, bot;
assign top=rd[wl+2'd1];
assign mid=rd[wl+2'd2];
assign bot=rd[wl+2'd3];
always_ff@(posedge clk)begin
if(pixv)begin
case(wl)
2'd0: line0[col]<=pixin;
2'd1: line1[col]<=pixin;
2'd2: line2[col]<=pixin;
default: line3[col]<=pixin;
endcase
end
end
always_ff @(posedge clk) begin
if(clr||rst)begin
col<=6'd0;wl<=2'd0;cx<=6'd0;cy<=6'd0;cxq<=6'd0;cyq<=6'd0;winv<=1'd0;trsh<=7'd0;
for(integer r=0;r<3;r++)
for(integer c=0;c<3;c++)
win_r[r][c]<=8'd0;
end
else begin
winv<=1'd0;
if(pixv)begin
if(col==W-1)begin
col<=6'd0;
wl<=wl+2'd1;
end
else begin
col<=col+6'd1;
end
for(integer r=0;r<3;r++)begin
win_r[r][0]<=win_r[r][1];
win_r[r][1]<=win_r[r][2];
end
win_r[0][2]<=top;
win_r[1][2]<=mid;
win_r[2][2]<=bot;
if(trsh==L)begin
winv<=1'd1;
cxq<=cx;
cyq<=cy;
if(cx==W-1)begin
cx<=6'd0;
cy<=(cy==H-1)?6'd0:cy+6'd1;
end
else begin
cx<=cx+6'd1;
end
end
else begin
trsh<=trsh+7'd1;
end
end
end
end
always_comb begin
for(integer r=0;r<3;r++)
for(integer c=0;c<3;c++)begin
if((r==0&&cyq==6'd0)||(r==2&&cyq==H-1)||(c==0&&cxq==6'd0)||(c==2&&cxq==W-1))
win[8*(3*r+c)+:8]=8'd0;
else
win[8*(3*r+c)+:8]=win_r[r][c];
end
end
endmodule