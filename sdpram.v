`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 10:41:25 PM
// Design Name: 
// Module Name: sdpram
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


module sdpram #(parameter int W = 8, parameter int D = 1024, parameter int DW = $clog2(D), parameter string INIT_FILE = "")(input logic clk, input logic we, input logic [DW-1:0]waddr, input logic [W-1:0]wdata, input logic [DW-1:0]raddr, output logic [W-1:0]rdata);
(*ram_style="block"*) logic [W-1:0]mem[0:D-1];
logic [W-1:0] rgate;
initial begin
if(INIT_FILE != "") $readmemh(INIT_FILE, mem);
end
always_ff @(posedge clk) begin
if(we) mem[waddr]<=wdata;
rgate<=mem[raddr];
rdata<=rgate;
end
endmodule

