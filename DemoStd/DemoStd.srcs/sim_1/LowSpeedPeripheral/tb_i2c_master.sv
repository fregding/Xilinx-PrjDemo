`timescale 1ns / 1ps

module i2c_master_checker #(
    parameter int REG_BITS = 8,
    parameter int DATA_BITS = 8,
    parameter int I2C_HZ = 100_000
)(
    output logic finished = 0,
    output logic clk = 0, rst_n = 0, start = 0, read_not_write = 0,
    output logic [6:0] dev_addr = 7'h52,
    output logic [REG_BITS-1:0] reg_addr = '0,
    output logic [DATA_BITS-1:0] write_data = '0,
    output wire [DATA_BITS-1:0] read_data,
    output wire busy, done, ack_error, stretch_timeout,
    output wire scl_view, sda_view,
    output logic slave_scl_low = 0, slave_sda_low = 0
);
    localparam int PERIOD = 50_000_000 / I2C_HZ;
    tri1 scl, sda;
    assign scl_view = scl;
    assign sda_view = sda;
    int starts = 0, stops = 0, byte_count = 0, slave_ack_count = 0;
    int rise_start_count = -1;
    time last_rise = 0, last_fall = 0;
    bit check_high = 0;
    int nack_at = -1;
    bit expect_read = 0, stretch_enable = 0, stretch_done = 0;
    bit hold_scl = 0;
    logic [REG_BITS-1:0] expected_reg;
    logic [DATA_BITS-1:0] expected_data;
    logic [DATA_BITS-1:0] response;

    always #10 clk = ~clk;
    assign scl = slave_scl_low ? 1'b0 : 1'bz;
    assign sda = slave_sda_low ? 1'b0 : 1'bz;
    i2c_master #(.I2C_HZ(I2C_HZ), .REG_BITS(REG_BITS), .DATA_BITS(DATA_BITS),
                 .STRETCH_TIMEOUT_CYCLES(2_000)) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .read_not_write(read_not_write),
        .dev_addr(dev_addr), .reg_addr(reg_addr), .write_data(write_data),
        .read_data(read_data), .busy(busy), .done(done),
        .ack_error(ack_error), .stretch_timeout(stretch_timeout), .scl(scl), .sda(sda)
    );

    always @(negedge sda) if (rst_n && scl === 1'b1) starts++;
    always @(posedge sda) if (rst_n && scl === 1'b1) stops++;
    always @(posedge scl) if (rst_n && busy) begin
        if (rise_start_count == starts && !stretch_enable && ($time - last_rise) != PERIOD * 20)
            $fatal(1, "I2C %0d Hz: clock period expected %0d ns got %0d ns",
                   I2C_HZ, PERIOD * 20, $time - last_rise);
        if (check_high && !stretch_enable && I2C_HZ == 400_000 &&
            ($time - last_fall) < 1_300)
            $fatal(1, "fast mode SCL low period too short");
        check_high = 1;
        rise_start_count = starts;
        last_rise = $time;
    end
    always @(negedge scl) if (rst_n && busy) begin
        if (check_high && !stretch_enable && I2C_HZ == 400_000 &&
            ($time - last_rise) < 600)
            $fatal(1, "fast mode SCL high period too short");
        last_fall = $time;
    end
    always @(sda or scl) if (rst_n && (sda !== 1'b0 && sda !== 1'b1 ||
                                      scl !== 1'b0 && scl !== 1'b1))
        $fatal(1, "I2C %0d/%0d @%0d: missing pull-up or bus X", REG_BITS, DATA_BITS, I2C_HZ);
    always @(negedge scl) if (rst_n && stretch_enable && !stretch_done && busy) begin
        stretch_done = 1;
        slave_scl_low = 1;
        if (!hold_scl) begin
            repeat (PERIOD + 20) @(negedge clk);
            slave_scl_low = 0;
        end
    end

    task automatic wait_start;
        forever begin
            @(negedge sda);
            if (scl === 1'b1 && busy === 1'b1) return;
        end
    endtask

    task automatic recv_byte(input byte expected, input bit ack);
        byte observed;
        observed = 0;
        for (int i = 7; i >= 0; i--) begin
            @(posedge scl);
            #1;
            observed[i] = sda;
        end
        if (observed !== expected)
            $fatal(1, "I2C %0d/%0d @%0d byte %0d expected %02h got %02h",
                   REG_BITS, DATA_BITS, I2C_HZ, byte_count, expected, observed);
        byte_count++;
        @(negedge scl);
        slave_sda_low = ack;
        @(posedge scl);
        #1;
        if (sda !== (ack ? 1'b0 : 1'b1)) $fatal(1, "slave ACK bus error");
        if (ack) slave_ack_count++;
        @(negedge scl);
        slave_sda_low = 0;
    endtask

    task automatic send_byte(input byte value, input bit master_ack);
        for (int i = 7; i >= 0; i--) begin
            slave_sda_low = ~value[i];
            @(posedge scl);
            #1;
            if (sda !== value[i]) $fatal(1, "slave transmit bit error");
            @(negedge scl);
        end
        slave_sda_low = 0;
        @(posedge scl);
        #1;
        if (sda !== (master_ack ? 1'b0 : 1'b1))
            $fatal(1, "I2C %0d/%0d: master read %s missing", REG_BITS, DATA_BITS,
                   master_ack ? "ACK" : "NACK");
        @(negedge scl);
    endtask

    initial begin : slave
        byte value;
        forever begin
            wait_start();
            byte_count = 0;
            recv_byte({7'h52, 1'b0}, nack_at != 0);
            if (nack_at == 0) continue;
            if (REG_BITS == 16) begin
                value = expected_reg >> 8;
                recv_byte(value, nack_at != 1);
                if (nack_at == 1) continue;
            end
            value = expected_reg[7:0];
            recv_byte(value, nack_at != byte_count);
            if (nack_at == byte_count - 1) continue;
            if (expect_read) begin
                wait_start();
                recv_byte({7'h52, 1'b1}, nack_at != byte_count);
                if (nack_at == byte_count - 1) continue;
                if (DATA_BITS == 16) begin
                    value = response >> 8;
                    send_byte(value, 1);
                end
                value = response[7:0];
                send_byte(value, 0);
            end else begin
                if (DATA_BITS == 16) begin
                    value = expected_data >> 8;
                    recv_byte(value, nack_at != byte_count);
                    if (nack_at == byte_count - 1) continue;
                end
                value = expected_data[7:0];
                recv_byte(value, nack_at != byte_count);
            end
        end
    end

    task automatic transaction(input bit rd, input int nack, input bit stretch);
        int start_before, stop_before;
        @(negedge clk);
        expect_read = rd;
        nack_at = nack;
        stretch_enable = stretch;
        stretch_done = 0;
        start_before = starts;
        stop_before = stops;
        read_not_write = rd;
        start = 1;
        @(negedge clk);
        start = 0;
        if (busy !== 1 || done !== 0) $fatal(1, "request not accepted");
        wait (done === 1'b1);
        @(negedge clk);
        if (busy !== 0 || done !== 1 || ack_error !== (nack >= 0) ||
            stretch_timeout !== 0 || scl !== 1 || sda !== 1)
            $fatal(1, "I2C %0d/%0d @%0d: completion/status wrong nack=%0d",
                   REG_BITS, DATA_BITS, I2C_HZ, nack);
        if (starts - start_before != (rd && nack < 0 ? 2 : 1) || stops - stop_before != 1)
            $fatal(1, "I2C %0d/%0d @%0d START/STOP wrong: %0d/%0d",
                   REG_BITS, DATA_BITS, I2C_HZ, starts-start_before, stops-stop_before);
        if (rd && nack < 0 && read_data !== response)
            $fatal(1, "I2C %0d/%0d read expected %h got %h", REG_BITS, DATA_BITS, response, read_data);
        @(negedge clk);
        if (done !== 0) $fatal(1, "done must be one clock pulse");
    endtask

    initial begin
        expected_reg = REG_BITS == 16 ? 16'hA15C : 8'hA1;
        expected_data = DATA_BITS == 16 ? 16'hB36E : 8'hB3;
        response = DATA_BITS == 16 ? 16'h3C92 : 8'h3C;
        reg_addr = expected_reg;
        write_data = expected_data;
        repeat (8) @(negedge clk);
        rst_n = 1;
        repeat (5) @(negedge clk);
        if (scl !== 1 || sda !== 1 || busy !== 0 || done !== 0)
            $fatal(1, "idle bus/status wrong");
        // 仅展示正常写入和读取，输入数据在整个事务期间保持不变。
        transaction(0, -1, 0);
        transaction(1, -1, 0);
        if (ack_error !== 0 || stretch_timeout !== 0)
            $fatal(1, "normal I2C communication reported an error");
        $display("PASS: I2C write/read REG=%0d DATA=%0d RATE=%0d", REG_BITS, DATA_BITS, I2C_HZ);
        finished = 1;
    end
endmodule

module tb_i2c_master;
    wire [4:0] finished;
    // 8位地址/8位数据、100 kHz：直接在仿真顶层观察完整I2C时序。
    wire clk, rst_n, start, read_not_write, busy, done;
    wire ack_error, stretch_timeout, scl, sda;
    wire slave_scl_low, slave_sda_low;
    wire [6:0] dev_addr;
    wire [7:0] reg_addr, write_data, read_data;
    i2c_master_checker #(8, 8, 100_000) c0 (
        .finished(finished[0]), .clk(clk), .rst_n(rst_n),
        .start(start), .read_not_write(read_not_write),
        .dev_addr(dev_addr), .reg_addr(reg_addr), .write_data(write_data),
        .read_data(read_data), .busy(busy), .done(done),
        .ack_error(ack_error), .stretch_timeout(stretch_timeout),
        .scl_view(scl), .sda_view(sda),
        .slave_scl_low(slave_scl_low), .slave_sda_low(slave_sda_low)
    );
    i2c_master_checker #(8, 16, 100_000) c1(.finished(finished[1]), .read_data());
    i2c_master_checker #(16, 8, 100_000) c2(.finished(finished[2]), .read_data());
    i2c_master_checker #(16, 16, 100_000) c3(.finished(finished[3]), .read_data());
    i2c_master_checker #(16, 16, 400_000) c4(.finished(finished[4]), .read_data());
    initial begin
        wait (&finished);
        $display("PASS: all 10 normal I2C write/read transactions");
        $finish;
    end
    initial begin
        #20_000_000;
        $fatal(1, "I2C testbench timeout");
    end
endmodule
