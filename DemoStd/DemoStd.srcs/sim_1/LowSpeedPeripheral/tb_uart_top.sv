`timescale 1ns / 1ps

// 位级独立解码 UART TX，逐字节核对 hello world 与回显
module tb_uart_top;
    localparam int CLK_FRE   = 50;
    localparam int BAUD_RATE = 115200;
    localparam int BIT_TIME  = (CLK_FRE * 1_000_000 / BAUD_RATE) * 20; // ns
    localparam int SIM_WAIT_CYCLES = 20_000;

    logic clk = 1'b0;
    logic rst_n;
    logic uart_rx_pin;
    logic uart_tx_pin;
    logic [7:0] expected [0:13];
    logic [7:0] received;
    bit boot_done = 1'b0;

    always #10 clk = ~clk;

    uart_top #(
        .CLK_FRE        (CLK_FRE),
        .BAUD_RATE      (BAUD_RATE),
        .ONE_SECOND_CNT (SIM_WAIT_CYCLES)
    ) dut (
        .sys_clk (clk),
        .rst_n   (rst_n),
        .uart_rx (uart_rx_pin),
        .uart_tx (uart_tx_pin)
    );

    task automatic send_byte(input logic [7:0] data);
        @(negedge clk);
        uart_rx_pin = 1'b0;
        #(BIT_TIME);
        for (int i = 0; i < 8; i++) begin
            uart_rx_pin = data[i];
            #(BIT_TIME);
        end
        uart_rx_pin = 1'b1;
        #(BIT_TIME);
    endtask

    task automatic recv_byte(output logic [7:0] data);
        @(negedge uart_tx_pin);
        #(BIT_TIME / 2);
        if (uart_tx_pin !== 1'b0) $fatal(1, "起始位错误");
        for (int i = 0; i < 8; i++) begin
            #(BIT_TIME);
            data[i] = uart_tx_pin;
        end
        #(BIT_TIME);
        if (uart_tx_pin !== 1'b1) $fatal(1, "停止位错误");
    endtask

    initial begin
        expected[0]  = "h";
        expected[1]  = "e";
        expected[2]  = "l";
        expected[3]  = "l";
        expected[4]  = "o";
        expected[5]  = " ";
        expected[6]  = "w";
        expected[7]  = "o";
        expected[8]  = "r";
        expected[9]  = "l";
        expected[10] = "d";
        expected[11] = 8'h0d;
        expected[12] = 8'h0a;
        expected[13] = 8'h3c;
        rst_n       = 1'b0;
        uart_rx_pin = 1'b1;
        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        for (int i = 0; i < 14; i++) begin
            recv_byte(received);
            if (received !== expected[i])
                $fatal(1, "字符 %0d: 预期 %02h，实际 %02h", i, expected[i], received);
            $display("PASS: 字符 %0d = %02h (%c)", i, received, received);
            if (i == 12) boot_done = 1'b1;
        end
        $display("PASS: hello world\\r\\n 完整发送，回显 3c 正确");
        $finish;
    end

    initial begin
        wait (boot_done);
        // 等待最后一个停止位结束，确保 DUT 进入 WAIT
        #(BIT_TIME);
        send_byte(8'h3c);
    end

    initial begin
        #2_000_000;
        $fatal(1, "UART 顶层仿真超时");
    end
endmodule
