`timescale 1ns / 1ps

module i2c_master_checker #(
    parameter int REG_BITS = 8,
    parameter int DATA_BITS = 8,
    parameter int SCL_HZ = 100_000
)(output logic finished = 1'b0);
    localparam int CLK_HZ = 50_000_000;
    logic clk = 0, rst_n = 0, start = 0, read_en = 0;
    logic [6:0] device_addr = 7'h52;
    logic [REG_BITS-1:0] reg_addr = '0;
    logic [DATA_BITS-1:0] wr_data = '0;
    wire [DATA_BITS-1:0] rd_data;
    wire busy, done, nack;
    tri1 scl, sda;
    logic slave_sda_low = 0;
    assign sda = slave_sda_low ? 1'b0 : 1'bz;
    always #10 clk = ~clk;

    i2c_master #(.CLK_HZ(CLK_HZ), .SCL_HZ(SCL_HZ),
                 .REG_ADDR_BITS(REG_BITS), .DATA_BITS(DATA_BITS)) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .read_en(read_en),
        .device_addr(device_addr), .reg_addr(reg_addr), .wr_data(wr_data),
        .rd_data(rd_data), .busy(busy), .done(done), .nack(nack),
        .scl(scl), .sda(sda)
    );

    task automatic recv_byte(input logic [7:0] expected, input bit ack_byte);
        logic [7:0] received;
        for (int i = 7; i >= 0; i--) begin
            @(posedge scl);
            received[i] = sda;
            @(negedge scl);
        end
        if (received !== expected)
            $fatal(1, "I2C %0d/%0d: expected byte %02h, got %02h", REG_BITS, DATA_BITS, expected, received);
        slave_sda_low = ack_byte;
        @(posedge scl);
        @(negedge scl);
        slave_sda_low = 0;
    endtask

    task automatic send_byte(input logic [7:0] value, input bit expected_ack);
        for (int i = 7; i >= 0; i--) begin
            slave_sda_low = ~value[i];
            @(posedge scl);
            @(negedge scl);
        end
        slave_sda_low = 0;
        @(posedge scl);
        if (sda !== (expected_ack ? 1'b0 : 1'b1))
            $fatal(1, "I2C %0d/%0d: master ACK/NACK error", REG_BITS, DATA_BITS);
        @(negedge scl);
    endtask

    task automatic slave_transaction(input bit reading, input bit ack_first,
                                     input logic [REG_BITS-1:0] register_value,
                                     input logic [DATA_BITS-1:0] write_value,
                                     input logic [DATA_BITS-1:0] reply_value);
        @(negedge sda);
        if (scl !== 1'b1) $fatal(1, "START not during SCL high");
        recv_byte({7'h52, 1'b0}, ack_first);
        if (ack_first) begin
            if (REG_BITS == 16) recv_byte(register_value[REG_BITS-1 -: 8], 1);
            recv_byte(register_value[7:0], 1);
            if (reading) begin
                @(negedge sda);
                if (scl !== 1'b1) $fatal(1, "repeated START not during SCL high");
                recv_byte({7'h52, 1'b1}, 1);
                if (DATA_BITS == 16) send_byte(reply_value[DATA_BITS-1 -: 8], 1);
                send_byte(reply_value[7:0], 0);
            end else begin
                if (DATA_BITS == 16) recv_byte(write_value[DATA_BITS-1 -: 8], 1);
                recv_byte(write_value[7:0], 1);
            end
        end
        @(posedge sda);
        if (scl !== 1'b1) $fatal(1, "STOP not during SCL high");
    endtask

    task automatic run_case(input bit reading, input bit ack_first,
                            input logic [REG_BITS-1:0] register_value,
                            input logic [DATA_BITS-1:0] write_value,
                            input logic [DATA_BITS-1:0] reply_value);
        fork
            slave_transaction(reading, ack_first, register_value, write_value, reply_value);
            begin
                @(negedge clk);
                reg_addr = register_value;
                wr_data = write_value;
                read_en = reading;
                start = 1;
                @(negedge clk);
                start = 0;
                if (!busy) $fatal(1, "busy missing");
                reg_addr = '0;
                wr_data = '0; // 检查请求后输入已锁存
                wait (done);
                @(negedge clk);
                if (busy || nack !== !ack_first || (reading && ack_first && rd_data !== reply_value))
                    $fatal(1, "I2C %0d/%0d: final result incorrect", REG_BITS, DATA_BITS);
                @(negedge clk);
                if (done) $fatal(1, "done must be one clock");
            end
        join
        repeat (3) @(negedge clk);
    endtask

    initial begin
        repeat (5) @(negedge clk);
        rst_n = 1;
        run_case(0, 1, REG_BITS'(16'hA35C), DATA_BITS'(16'hC936), '0);
        run_case(1, 1, REG_BITS'(16'hA35C), '0, DATA_BITS'(16'h5AA5));
        run_case(0, 0, '0, '0, '0); // 地址NACK后必须STOP
        $display("PASS I2C: reg=%0d data=%0d scl=%0d", REG_BITS, DATA_BITS, SCL_HZ);
        finished = 1;
    end
endmodule

module tb_i2c_master;
    wire f88, f816, f168, f1616;
    i2c_master_checker #(.REG_BITS(8), .DATA_BITS(8)) c88 (.finished(f88));
    i2c_master_checker #(.REG_BITS(8), .DATA_BITS(16), .SCL_HZ(400_000)) c816 (.finished(f816));
    i2c_master_checker #(.REG_BITS(16), .DATA_BITS(8)) c168 (.finished(f168));
    i2c_master_checker #(.REG_BITS(16), .DATA_BITS(16), .SCL_HZ(400_000)) c1616 (.finished(f1616));
    initial begin
        wait (f88 && f816 && f168 && f1616);
        $display("PASS I2C: all 4 configurations, writes/reads/NACK");
        $finish;
    end
    initial begin
        #5_000_000;
        $fatal(1, "I2C simulation timeout");
    end
endmodule
