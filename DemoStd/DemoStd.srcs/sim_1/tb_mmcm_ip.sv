`timescale 1ns / 1ps

// MMCM IP 仿真验证
// IP 配置：输入100 MHz，clk_out1为100 MHz，clk_out2为50 MHz、相位45度
module tb_mmcm_ip;
    logic clk_in1 = 1'b0;
    logic reset;
    wire  clk_out1;
    wire  clk_out2;
    wire  locked;

    time clk_out1_last;
    time clk_out2_last;
    time clk_out1_period;
    time clk_out2_period;

    // 产生100 MHz输入时钟，周期为10 ns
    always #5 clk_in1 = ~clk_in1;

    // 实例化 Vivado Clocking Wizard 生成的 MMCM IP
    mmcm_ip dut (
        .clk_out1(clk_out1),
        .clk_out2(clk_out2),
        .reset(reset),
        .locked(locked),
        .clk_in1(clk_in1)
    );

    // 检查clk_out1周期是否约为10 ns
    always @(posedge clk_out1) begin
        if (locked && (clk_out1_last != 0)) begin
            clk_out1_period = $time - clk_out1_last;
            if (clk_out1_period != 10)
                $fatal(1, "MMCM clk_out1周期错误：实际=%0t，期望=10 ns", clk_out1_period);
        end
        if (locked)
            clk_out1_last = $time;
    end

    // 检查clk_out2周期是否约为20 ns，即50 MHz
    always @(posedge clk_out2) begin
        if (locked && (clk_out2_last != 0)) begin
            clk_out2_period = $time - clk_out2_last;
            if (clk_out2_period != 20)
                $fatal(1, "MMCM clk_out2周期错误：实际=%0t，期望=20 ns", clk_out2_period);
        end
        if (locked)
            clk_out2_last = $time;
    end

    initial begin
        reset = 1'b1;
        #100;
        reset = 1'b0;

        // 等待MMCM完成锁定，最长等待1 us
        fork
            begin
                wait (locked === 1'b1);
                $display("MMCM已锁定：time=%0t ns", $time);
            end
            begin
                #1000;
                $fatal(1, "MMCM在1 us内没有锁定");
            end
        join_any
        disable fork;

        // 等待多个输出边沿，完成周期检查
        repeat (8) @(posedge clk_out2);
        $display("MMCM仿真通过：clk_out1约100 MHz，clk_out2约50 MHz。");
        $finish;
    end
endmodule
