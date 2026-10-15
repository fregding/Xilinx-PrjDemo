`timescale 1ns / 1ps

// 例题3仿真：DIV_COUNT=2时，每2个输入时钟翻转一次输出
module tb_divider;
    logic clk = 1'b0;
    logic rst;
    logic clk_div;

    always #5 clk = ~clk;

    divider #(.DIV_COUNT(2)) dut (
        .clk(clk),
        .rst(rst),
        .clk_div(clk_div)
    );

    initial begin
        rst = 1;
        repeat (2) @(posedge clk);
        #1;
        if (clk_div !== 1'b0) $fatal("分频器复位失败");

        rst = 0;
        repeat (2) @(posedge clk);
        #1;
        if (clk_div !== 1'b1) $fatal("分频器第一次翻转失败");

        repeat (2) @(posedge clk);
        #1;
        if (clk_div !== 1'b0) $fatal("分频器第二次翻转失败");

        $display("通过：分频器复位和输出翻转均正确。");
        $finish;
    end
endmodule
