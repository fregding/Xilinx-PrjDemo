`timescale 1ns / 1ps

// UART 发送模块（基于教程状态机，改写为 SystemVerilog）
module uart_tx #(
    parameter int CLK_FRE   = 50,
    parameter int BAUD_RATE = 115200
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] tx_data,
    input  logic       tx_data_valid,
    output logic       tx_pin,
    output logic       tx_data_ready
);

    localparam int CYCLE = CLK_FRE * 1_000_000 / BAUD_RATE;

    typedef enum logic [2:0] {
        S_IDLE,
        S_START,
        S_SEND_BYTE,
        S_STOP
    } state_t;

    state_t state;
    logic [$clog2(CYCLE+1)-1:0] cycle_cnt;
    logic [2:0] bit_cnt;
    logic [7:0] tx_data_latch;

    // UART 空闲/停止位为高，起始位为低，数据位按低位优先输出
    assign tx_pin = (state == S_START)                 ? 1'b0 :
                    (state == S_SEND_BYTE)             ? tx_data_latch[bit_cnt] :
                                                         1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            cycle_cnt     <= '0;
            bit_cnt       <= 3'd0;
            tx_data_latch <= 8'd0;
            tx_data_ready <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    // ready 表示可接收新字节；valid 到来时锁存数据并开始发送
                    tx_data_ready <= 1'b1;
                    if (tx_data_valid) begin
                        tx_data_latch <= tx_data;
                        tx_data_ready <= 1'b0;
                        state         <= S_START;
                    end
                end

                S_START: begin
                    tx_data_ready <= 1'b0;
                    if (cycle_cnt == CYCLE - 1) begin
                        cycle_cnt <= '0;
                        state     <= S_SEND_BYTE;
                    end else begin
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end
                end

                S_SEND_BYTE: begin
                    tx_data_ready <= 1'b0;
                    if (cycle_cnt == CYCLE - 1) begin
                        cycle_cnt <= '0;
                        if (bit_cnt == 3'd7) begin
                            bit_cnt <= 3'd0;
                            state   <= S_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 3'd1;
                        end
                    end else begin
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end
                end

                S_STOP: begin
                    if (cycle_cnt == CYCLE - 1) begin
                        tx_data_ready <= 1'b1;
                        cycle_cnt     <= '0;
                        state         <= S_IDLE;
                    end else begin
                        tx_data_ready <= 1'b0;
                        cycle_cnt     <= cycle_cnt + 1'b1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
