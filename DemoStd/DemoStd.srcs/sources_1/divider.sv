`timescale 1ns / 1ps

// 例题3：可设置分频计数阈值的时钟分频器
module divider #(
    parameter int DIV_COUNT = 4  // 计数达到该值时翻转输出
) (
    input  logic clk,             // 输入时钟
    input  logic rst,             // 同步复位，高电平有效
    output logic clk_div          // 分频后的方波
);
    localparam int COUNT_WIDTH = (DIV_COUNT <= 1) ? 1 : $clog2(DIV_COUNT);
    logic [COUNT_WIDTH-1:0] count;

    // 每经过DIV_COUNT个输入时钟周期，输出翻转一次
    always_ff @(posedge clk) begin
        if (rst) begin
            count   <= '0;
            clk_div <= 1'b0;
        end else if (count == DIV_COUNT - 1) begin
            count   <= '0;
            clk_div <= ~clk_div;
        end else begin
            count <= count + 1'b1;
        end
    end
endmodule
