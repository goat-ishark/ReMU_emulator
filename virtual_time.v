`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 16:40:10
// Design Name: 
// Module Name: virtual_time
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


module virtual_time 

#(

    parameter   TIME_SCALE_WIDTH = 32// the width for virtual time


)
(
    input  wire        clk,           // 系统时钟
    input  wire        rst_n,         // 异步复位，低电平有效
    output reg  [TIME_SCALE_WIDTH-1:0] virtual_time   // 32位虚拟时钟计数器
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            virtual_time <= 32'd0;
        else
            virtual_time <= virtual_time + 1'b1;
    end

endmodule
