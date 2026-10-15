`timescale 1ns / 1ps

// 同步 FIFO IP 仿真：每4个时钟写入一个递增数据，FIFO满后连续读取
module tb_scfifo_256x8;
    logic        sys_clk = 1'b0;
    logic        srst;
    logic [7:0]  pi_data;
    logic        pi_flag;
    logic        rd_en;
    logic [1:0]  cnt_baud;

    wire [7:0]   po_data;
    wire         empty;
    wire         full;
    wire [7:0]   data_count;
    wire         wr_rst_busy;
    wire         rd_rst_busy;

    integer write_count;
    integer read_count;

    // 100 MHz时钟
    always #10 sys_clk = ~sys_clk;

    // 复位初始化
    initial begin
        srst = 1'b1;
        pi_data = 8'h00;
        pi_flag = 1'b0;
        rd_en = 1'b0;
        cnt_baud = 2'b00;
        write_count = 0;
        read_count = 0;

        repeat (5) @(negedge sys_clk);
        srst = 1'b0;
    end

    // 每4个时钟产生一次数据有效脉冲；读取期间暂停写入
    always @(posedge sys_clk) begin
        if (srst) begin
            cnt_baud <= 2'b00;
            pi_flag <= 1'b0;
            pi_data <= 8'h00;
        end else begin
            if (cnt_baud == 2'd3)
                cnt_baud <= 2'b00;
            else
                cnt_baud <= cnt_baud + 1'b1;

            pi_flag <= (cnt_baud == 2'd0) && !rd_en && !full;

            if ((cnt_baud == 2'd0) && !rd_en && !full)
                pi_data <= pi_data + 1'b1;
        end
    end

    // 满时启动读取，空时停止读取
    always @(posedge sys_clk) begin
        if (srst)
            rd_en <= 1'b0;
        else if (full)
            rd_en <= 1'b1;
        else if (empty)
            rd_en <= 1'b0;
    end

    // 统计 FIFO 实际接受的写入和读取请求
    always @(posedge sys_clk) begin
        if (srst) begin
            write_count <= 0;
            read_count <= 0;
        end else if (!wr_rst_busy && !rd_rst_busy) begin
            if (pi_flag && !full)
                write_count <= write_count + 1;
            if (rd_en && !empty)
                read_count <= read_count + 1;
        end
    end

    scfifo_256x8 fifo_inst (
        .clk(sys_clk),
        .srst(srst),
        .din(pi_data),
        .wr_en(pi_flag && !full),
        .rd_en(rd_en && !empty),
        .dout(po_data),
        .full(full),
        .empty(empty),
        .data_count(data_count),
        .wr_rst_busy(wr_rst_busy),
        .rd_rst_busy(rd_rst_busy)
    );

    // 先填满FIFO，再留出足够时间读取并读空
    initial begin
        wait (srst == 1'b0);
        repeat (2200) @(negedge sys_clk);
        #1;

        if (write_count == 0 || read_count == 0 || !empty) begin
            $fatal(1, "FIFO测试失败：写入=%0d，读取=%0d，empty=%b，data_count=%0d",
                   write_count, read_count, empty, data_count);
        end

        $display("FIFO测试通过：写入=%0d，读取=%0d，FIFO已读空。", write_count, read_count);
        $finish;
    end
endmodule
