`timescale 1ns / 1ps

// TX 连 RX 自回环，检查 8N1 数据传输
module tb_uart_tx_rx;
    localparam int CLK_FRE   = 50;
    localparam int BAUD_RATE = 115200;
    localparam int BIT_TIME  = (CLK_FRE * 1_000_000 / BAUD_RATE) * 20;

    logic clk = 1'b0;
    logic rst_n;
    logic [7:0] tx_data;
    logic       tx_data_valid;
    logic       tx_data_ready;
    logic       tx_pin;
    logic [7:0] rx_data;
    logic       rx_data_valid;
    logic       rx_data_ready;
    logic [7:0] test_vec [0:3];

    always #10 clk = ~clk;

    uart_tx #(.CLK_FRE(CLK_FRE), .BAUD_RATE(BAUD_RATE)) dut_tx (
        .clk(clk), .rst_n(rst_n), .tx_data(tx_data),
        .tx_data_valid(tx_data_valid), .tx_pin(tx_pin), .tx_data_ready(tx_data_ready)
    );

    uart_rx #(.CLK_FRE(CLK_FRE), .BAUD_RATE(BAUD_RATE)) dut_rx (
        .clk(clk), .rst_n(rst_n), .rx_pin(tx_pin),
        .rx_data_ready(rx_data_ready), .rx_data_valid(rx_data_valid), .rx_data(rx_data)
    );

    initial begin
        // 交替位及全零/全一向量覆盖常见数据位组合
        test_vec[0] = 8'h55;
        test_vec[1] = 8'hAA;
        test_vec[2] = 8'h00;
        test_vec[3] = 8'hFF;
        rst_n         = 1'b0;
        tx_data       = '0;
        tx_data_valid = 1'b0;
        rx_data_ready = 1'b1;
        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        for (int i = 0; i < 4; i++) begin
            wait (tx_data_ready);
            @(negedge clk);
            tx_data       = test_vec[i];
            tx_data_valid = 1'b1;
            @(negedge clk);
            tx_data_valid = 1'b0;
            // 等待接收端报告完整字节后比较回环结果
            wait (rx_data_valid);
            if (rx_data !== test_vec[i])
                $fatal(1, "TX/RX %0d: 预期 %02h，实际 %02h", i, test_vec[i], rx_data);
            $display("PASS: TX/RX %0d = %02h", i, rx_data);
            #(BIT_TIME);
        end
        $display("PASS: UART TX/RX 回环");
        $finish;
    end

    initial begin
        #5_000_000;
        $fatal(1, "TX/RX 仿真超时");
    end
endmodule
