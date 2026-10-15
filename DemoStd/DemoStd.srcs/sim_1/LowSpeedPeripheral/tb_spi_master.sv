`timescale 1ns / 1ps

// 独立从机行为模型：只观察SPI引脚，不读取DUT内部状态。
module spi_master_checker #(
    parameter int CLK_DIV = 5
)(
    output logic finished = 1'b0,
    output logic clk = 1'b0,
    output logic rst_n = 1'b0,
    output logic start = 1'b0,
    output logic [7:0] tx_data = '0,
    output wire [7:0] rx_data,
    output wire busy, done, sclk, cs_n, mosi, miso,
    output logic [7:0] slave_rx = '0
);
    logic [7:0] slave_tx = '0;
    logic [7:0] slave_shift = '0;
    int rise_count = 0;
    int fall_count = 0;
    int pass_count = 0;
    time last_edge;
    time last_sample;
    time cs_start;
    logic loopback = 1'b0;

    always #10 clk = ~clk; // 50 MHz
    assign miso = cs_n ? 1'b0 : (loopback ? mosi : slave_shift[7]);

    spi_master #(.CLK_DIV(CLK_DIV)) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .rx_data(rx_data), .busy(busy), .done(done),
        .spi_sclk(sclk), .spi_cs_n(cs_n), .spi_mosi(mosi), .spi_miso(miso)
    );

    always @(negedge cs_n) begin
        if (rst_n) begin
            slave_shift = slave_tx;
            slave_rx = '0;
            rise_count = 0;
            fall_count = 0;
            last_edge = $time;
            cs_start = $time;
        end
    end

    always @(posedge sclk) begin
        if (rst_n) begin
            if (cs_n !== 1'b0 || busy !== 1'b1)
                $fatal(1, "分频%0d：时钟上升沿的片选或busy错误", CLK_DIV);
            if (($time - last_edge) != CLK_DIV * 20)
                $fatal(1, "分频%0d：SCLK半周期错误", CLK_DIV);
            last_edge = $time;
            last_sample = $time;
            slave_rx = {slave_rx[6:0], mosi};
            rise_count++;
            if (rise_count > 8)
                $fatal(1, "分频%0d：超过8个采样沿", CLK_DIV);
        end
    end

    always @(negedge sclk) begin
        if (rst_n && !cs_n) begin
            if (($time - last_edge) != CLK_DIV * 20)
                $fatal(1, "分频%0d：SCLK半周期错误", CLK_DIV);
            last_edge = $time;
            slave_shift = {slave_shift[6:0], 1'b0};
            fall_count++;
        end
    end

    always @(mosi) begin
        if (rst_n && !cs_n && rise_count > 0) begin
            if (sclk !== 1'b0 || $time == last_sample)
                $fatal(1, "分频%0d：MOSI在采样沿或高电平期间变化", CLK_DIV);
        end
    end

    task automatic transfer(input logic [7:0] send_byte,
                            input logic [7:0] reply_byte,
                            input bit use_loopback,
                            input bit inject_busy_start);
        @(negedge clk);
        tx_data = send_byte;
        slave_tx = reply_byte;
        loopback = use_loopback;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        tx_data = ~send_byte; // 验证请求接受后发送数据已锁存
        if (busy !== 1'b1 || cs_n !== 1'b0)
            $fatal(1, "分频%0d：请求未被接受", CLK_DIV);
        if (inject_busy_start) begin
            repeat (2) @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
        wait (done === 1'b1);
        @(negedge clk);
        if (rx_data !== (use_loopback ? send_byte : reply_byte))
            $fatal(1, "分频%0d：接收错误，预期%02h，实际%02h",
                   CLK_DIV, use_loopback ? send_byte : reply_byte, rx_data);
        if (slave_rx !== send_byte)
            $fatal(1, "分频%0d：从机接收错误，预期%02h，实际%02h",
                   CLK_DIV, send_byte, slave_rx);
        if (rise_count != 8 || fall_count != 8 || busy !== 1'b0 ||
            cs_n !== 1'b1 || sclk !== 1'b0)
            $fatal(1, "分频%0d：帧结束状态或时钟沿数量错误", CLK_DIV);
        if (($time - 10 - cs_start) != 17 * CLK_DIV * 20)
            $fatal(1, "分频%0d：片选建立/保持时间错误", CLK_DIV);
        @(negedge clk);
        if (done !== 1'b0 || busy !== 1'b0)
            $fatal(1, "分频%0d：done不为单周期或忙时请求被排队", CLK_DIV);
        pass_count++;
    endtask

    initial begin
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        if (cs_n !== 1'b1 || sclk !== 1'b0 || busy !== 1'b0 || done !== 1'b0)
            $fatal(1, "复位后的空闲状态错误");
        transfer(8'h00, 8'hFF, 0, 0);
        transfer(8'hFF, 8'h00, 0, 0);
        transfer(8'hAA, 8'h55, 0, 1);
        transfer(8'h80, 8'h01, 0, 0);
        transfer(8'h01, 8'h80, 0, 0);
        for (int i = 0; i < 256; i++)
            transfer(i[7:0], ~i[7:0], 0, 0);
        transfer(8'hA5, 8'h00, 1, 0);
        transfer(8'h3C, 8'h00, 1, 0);

        // 传输中复位应立即取消当前帧，随后仍能重新通信。
        @(negedge clk);
        tx_data = 8'h96;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        repeat (3) @(posedge sclk);
        @(negedge clk);
        rst_n = 1'b0;
        @(negedge clk);
        if (busy !== 1'b0 || cs_n !== 1'b1 || sclk !== 1'b0 || done !== 1'b0)
            $fatal(1, "传输中复位未清除状态");
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        transfer(8'h96, 8'h69, 0, 0);
        $display("PASS: CLK_DIV=%0d，%0d帧，双向通信/回环/忙时请求/复位恢复", CLK_DIV, pass_count);
        finished = 1'b1;
    end
endmodule

module tb_spi_master;
    wire finished_1, finished_2, finished_5;
    // 将分频5的演示信号引到顶层，便于直接加入Vivado波形窗口。
    wire clk, rst_n, start, busy, done, sclk, cs_n, mosi, miso;
    wire [7:0] tx_data, rx_data, slave_rx;
    spi_master_checker #(.CLK_DIV(1)) check_1 (.finished(finished_1), .rx_data());
    spi_master_checker #(.CLK_DIV(2)) check_2 (.finished(finished_2), .rx_data());
    spi_master_checker #(.CLK_DIV(5)) check_5 (
        .finished(finished_5), .clk(clk), .rst_n(rst_n),
        .start(start), .tx_data(tx_data), .rx_data(rx_data),
        .busy(busy), .done(done), .sclk(sclk), .cs_n(cs_n),
        .mosi(mosi), .miso(miso), .slave_rx(slave_rx)
    );
    initial begin
        wait (finished_1 && finished_2 && finished_5);
        $display("PASS: SPI全部自检通过，共792帧");
        $finish;
    end
    initial begin
        #1_000_000;
        $fatal(1, "SPI仿真超时");
    end
endmodule
