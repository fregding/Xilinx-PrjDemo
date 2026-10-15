`timescale 1ns / 1ps

// 例题1仿真：验证复位、写入和保持功能
module tb_register_enable;
    logic clk = 1'b0;
    logic rst;
    logic en;
    logic [7:0] data_in;
    logic [7:0] data_out;

    always #5 clk = ~clk;

    register_enable dut (.*);

    initial begin
        rst = 1; en = 0; data_in = 8'h00;
        repeat (2) @(posedge clk);
        #1;
        if (data_out !== 8'h00) $fatal("寄存器复位失败");

        rst = 0; en = 1; data_in = 8'hA5;
        @(posedge clk); #1;
        if (data_out !== 8'hA5) $fatal("寄存器写入失败");

        en = 0; data_in = 8'h5A;
        @(posedge clk); #1;
        if (data_out !== 8'hA5) $fatal("寄存器保持失败");

        $display("通过：寄存器复位、写入和保持均正确。");
        $finish;
    end
endmodule
