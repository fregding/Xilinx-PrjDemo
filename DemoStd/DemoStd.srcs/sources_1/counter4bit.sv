`timescale 1ns / 1ps

// 例题2：带使能和同步复位的4位计数器
module counter4bit (
    input  logic       clk,       // 时钟
    input  logic       rst,       // 同步复位，高电平有效
    input  logic       en,        // 计数使能
    output logic [3:0] count      // 当前计数值
);
    // 4位计数器加到15后自然回到0
    always_ff @(posedge clk) begin
        if (rst)
            count <= 4'h0;
        else if (en)
            count <= count + 4'h1;
    end
endmodule
