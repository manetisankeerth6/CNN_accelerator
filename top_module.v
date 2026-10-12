`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2026 08:58:05 AM
// Design Name: 
// Module Name: top_module
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


module top_module#(parameter int shift=3, parameter string conv_weight="conv_weights.mem", parameter string fc_weight="fc_weights.mem", parameter string bias_file="biases.mem")(input logic clk,input logic rst, input logic start, input logic imagwe,input logic [7:0]imagwdata,input logic [9:0]imagwaddr,output logic done, output logic [3:0]pred, output logic signed [23:0]best_score);
localparam int image_pix=784; localparam int feat=3136; localparam int last_conv=840;
typedef enum logic [2:0]{S_IDLE, S_LOADIMG, S_CONV, S_FC, S_DONE}state_t;
state_t state;
logic [17:0]conv_w[0:3];
logic signed [15:0]bias[0:13];
initial begin
$readmemh(conv_weight, conv_w);
$readmemh(bias_file, bias);
end
logic [11:0] issuecnt;
logic [11:0] wrcnt;
logic [1:0] x,y;
logic [11:0] feat_base;
logic [1:0] ch;
logic issue_busy;
logic lb_clr_r;
logic [9:0] imagraddr;
logic [7:0] imagrdata;
assign imagraddr=(issuecnt<image_pix)? issuecnt[9:0]:10'd0;
sdpram#(.W(8), .D(image_pix)) imag_ram(clk, imagwe, imagwaddr, imagwdata, imagraddr, imagrdata);
logic conv_v;
logic [7:0] conv_pix;
logic [7:0] featrdata;
logic [19:0] fc_rdata;
sdpram#(.W(8), .D(feat)) feat_ram(clk, conv_v, feat_base+wrcnt, conv_pix, issuecnt, featrdata);
sdpram#(.W(20), .D(feat), .INIT_FILE(fc_weight)) fc_rom(clk, 1'b0, 12'd0, 20'd0, issuecnt, fc_rdata);
logic pixv;
logic [7:0] pixin;
logic winv;
logic [71:0]win;
logic lb_clr;
assign pixv=x[1]&&(state==S_CONV);
assign lb_clr=lb_clr_r||(state==S_LOADIMG);
assign pixin=(y[1])?8'd0:imagrdata;
line_buffer#(.W(28), .H(28)) lb(clk, rst, lb_clr, pixv, pixin, winv, win);
conv_block#(shift) conv(clk, rst, winv, win, conv_w[ch], bias[ch], conv_v, conv_pix);
logic signed [23:0]acc[0:9];
function automatic logic signed [9:0] fcwed(input logic [7:0]pix, input logic [1:0]w);
case(w)
2'b01: fcwed=$signed({2'b00,pix});
2'b11: fcwed=-$signed({2'b00,pix});
default: fcwed=$signed(10'd0);
endcase
endfunction
logic [3:0] best_acc;
logic signed [23:0] best_val;
always_comb begin
best_acc=4'd0;
best_val=acc[0];
for(integer c=1;c<10;c++)
if(acc[c]>best_val)begin 
best_acc=4'(c);
best_val=acc[c];
end
end
always_ff @(posedge clk)begin
if(rst)begin
state<=S_IDLE;
done<=1'b0; issuecnt<='0; pred<= '0; best_score<= '0; wrcnt<='0; ch<='0; issue_busy<=1'b0; lb_clr_r<=1'b0; x<=2'b00; y<=2'b00; feat_base<='0;
for(integer c=0;c<10;c++) acc[c]<='0;
end
else begin
lb_clr_r<=1'b0;
x<=({x[0], issue_busy});
y<=({y[0],(issuecnt>=image_pix)});
case(state)
S_IDLE: begin
if(start) begin
done<=1'b0;
state<=S_LOADIMG;
end
end
S_LOADIMG: begin
ch<=2'd0;
feat_base<=12'd0;
issuecnt<=12'd0;
wrcnt<=12'd0;
issue_busy<=1'b1;
state<=S_CONV;
end
S_CONV:begin
if(issue_busy)begin
if(issuecnt==last_conv) issue_busy<=1'b0;
else issuecnt<=issuecnt+12'd1;
end
if(conv_v)begin
wrcnt<=wrcnt+1;
if(wrcnt==image_pix-1)begin
wrcnt<=12'd0;
issuecnt<=12'd0;
issue_busy<=1'b1;
if(ch==2'd3)begin
for(integer c=0;c<10;c++)acc[c]<=bias[4+c];
state<=S_FC;
end
else begin
ch<=ch+2'd1;
feat_base<=feat_base+12'd784;
lb_clr_r<=1'b1;
end
end
end
end
S_FC:begin
if(issue_busy)begin
if(issuecnt==feat-1)issue_busy<=1'd0;
else issuecnt<=issuecnt+12'd1;
end
if(x[1])begin
for(integer c=0;c<10;c++)acc[c]<=acc[c]+fcwed(featrdata,fc_rdata[2*c+:2]);
wrcnt<=wrcnt+12'd1;
if(wrcnt==feat-1) state<=S_DONE;
end
end
S_DONE: begin
pred<=best_acc;
best_score<=best_val;
done<=1'b1;
state<=S_IDLE;
end
default: state<=S_IDLE;
endcase
end
end
endmodule
