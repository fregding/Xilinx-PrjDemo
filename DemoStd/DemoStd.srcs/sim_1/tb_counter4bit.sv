`timescale 1ns / 1ps

// 例题2仿真：验证复位、计数和保持功能
module tb_counter4bit;
    logic clk = 1'b0;
    logic rst;
    logic en;
    logic [3:0] count;

    always #5 clk = ~clk;

    counter4bit dut (.*);

    initial begin
        rst = 1; en = 0;
        repeat (2) @(posedge clk);
        #1;
        if (count !== 4'h0) $fatal("计数器复位失败");

        rst = 0; en = 1;
        repeat (16) @(posedge clk);
        #1;
        if (count !== 4'h0) $fatal("计数器回绕失败");

        en = 0;
        @(posedge clk); #1;
        if (count !== 4'h0) $fatal("计数器保持失败");

        $display("通过：计数器复位、计数、回绕和保持均正确。");
        $finish;
    end
endmodule
