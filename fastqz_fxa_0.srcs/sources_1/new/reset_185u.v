`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2019 06:46:21 PM
// Design Name: 
// Module Name: reset_185u
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


module reset185u(
    input wire clk,
    output reg rst, rst_n
);
    reg [15:0] cnt;
    always@(posedge clk) begin
        if(cnt < 16'h4844) begin
            cnt <= cnt + 1'b1;
        end
    end
    always@(posedge clk) begin
        if(cnt < 16'h4844) begin
            rst <= 1'b1;
            rst_n <= 1'b0;
        end
        else begin
            rst <= 1'b0;
            rst_n <= 1'b1;
        end
    end
    
endmodule
