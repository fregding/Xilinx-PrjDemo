`timescale 1ns / 1ps

// 8选1多路选择器的自检仿真
module tb_mux8to1;
    logic [7:0] data_in;  // 输入的8路数据
    logic [2:0] sel;      // 当前选择的输入编号
    logic       data_out; // DUT输出
    integer     i;

    // 实例化待测模块（DUT）
    mux8to1 dut (
        .data_in(data_in),
        .sel(sel),
        .data_out(data_out)
    );

    initial begin
        // 第一组输入：依次检查 sel=0 到 sel=7
        data_in = 8'b1010_0101;
        for (i = 0; i < 8; i = i + 1) begin
            sel = i[2:0]; // 设置选择编号
            #10;           // 等待组合逻辑稳定
            // 用对应输入位作为期望值，比较DUT输出
            if (data_out !== data_in[i]) begin
                $fatal(1, "Mismatch: sel=%0d, expected=%b, got=%b", i, data_in[i], data_out);
            end
        end

        // 使用互补数据再检查一次，覆盖输出为0和1的情况
        data_in = 8'b0101_1010;
        for (i = 0; i < 8; i = i + 1) begin
            sel = i[2:0];
            #10;
            if (data_out !== data_in[i]) begin
                $fatal(1, "Mismatch: sel=%0d, expected=%b, got=%b", i, data_in[i], data_out);
            end
        end

        $display("PASS: all 8 select values verified for both data patterns.");
        $finish;
    end
endmodule
