`timescale 1ns / 1ps

module tb_async_fifo;
    localparam int WIDTH = 8;
    localparam int DEPTH = 8;

    logic wr_clk = 1'b0;
    logic rd_clk = 1'b0;
    logic rst;
    logic wr_en;
    logic [WIDTH-1:0] wr_data;
    logic rd_en;
    wire full;
    wire empty;
    wire [WIDTH-1:0] rd_data;

    logic [WIDTH-1:0] expected [0:DEPTH-1];
    integer expected_head;
    integer expected_tail;
    integer expected_count;
    integer write_count;
    integer read_count;
    integer error_count;
    integer i;

    // 写时钟周期 10 ns，读时钟周期 14 ns
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    async_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

    // 写入 32 个递增数据，每写满一轮后等待读取端腾出空间
    initial begin
        rst = 1'b1;
        wr_en = 1'b0;
        wr_data = '0;
        rd_en = 1'b0;
        expected_head = 0;
        expected_tail = 0;
        expected_count = 0;
        write_count = 0;
        read_count = 0;
        error_count = 0;

        repeat (5) @(negedge wr_clk);
        rst = 1'b0;

        for (i = 0; i < 32; i = i + 1) begin
            @(negedge wr_clk);
            while (full) @(negedge wr_clk);
            wr_data = i[WIDTH-1:0];
            wr_en = 1'b1;
            @(posedge wr_clk);
            expected[expected_tail] = wr_data;
            expected_tail = (expected_tail + 1) % DEPTH;
            expected_count = expected_count + 1;
            write_count = write_count + 1;
            @(negedge wr_clk);
            wr_en = 1'b0;
        end
    end

    // 持续读取；在读时钟沿检查同步读出的 FIFO 数据
    initial begin
        wait (rst == 1'b1);
        repeat (5) @(negedge rd_clk);
        wait (rst == 1'b0);

        forever begin
            @(negedge rd_clk);
            rd_en = !empty;
            if (!empty) begin
                @(posedge rd_clk);
                #1;
                if (expected_count == 0) begin
                    error_count = error_count + 1;
                end else begin
                    if (rd_data !== expected[expected_head])
                        error_count = error_count + 1;
                    expected_head = (expected_head + 1) % DEPTH;
                    expected_count = expected_count - 1;
                    read_count = read_count + 1;
                end
                @(negedge rd_clk);
                rd_en = 1'b0;
            end
        end
    end

    initial begin
        wait (write_count == 32);
        wait (read_count == 32);
        repeat (3) @(posedge rd_clk);
        if (error_count != 0 || !empty || expected_count != 0)
            $fatal(1, "异步FIFO测试失败：写入=%0d，读出=%0d，错误=%0d，empty=%b",
                   write_count, read_count, error_count, empty);

        $display("PASS: async_fifo WIDTH=%0d DEPTH=%0d COUNT=%0d", WIDTH, DEPTH, read_count);
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "异步FIFO测试超时：写入=%0d，读出=%0d，错误=%0d",
               write_count, read_count, error_count);
    end
endmodule
