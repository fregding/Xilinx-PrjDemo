`timescale 1ns / 1ps

// 3-8译码器自检仿真：遍历全部8种输入组合
module tb_decoder3to8;
    logic [2:0] in;
    logic [7:0] out;
    integer     i;

    // 实例化待测译码器（DUT）
    decoder3to8 dut (
        .in(in),
        .out(out)
    );

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            in = i[2:0];
            #10; // 等待组合逻辑稳定
            if (out !== (8'b0000_0001 << i)) begin
                $fatal(1, "译码错误：in=%0d，期望=%b，实际=%b", i, (8'b0000_0001 << i), out);
            end
        end

        $display("通过：3-8译码器的全部输入组合均正确。");
        $finish;
    end
endmodule
