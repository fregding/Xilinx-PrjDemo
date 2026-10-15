`timescale 1ns / 1ps

// UART 8N1 接收：在起始位、数据位和停止位的中心采样
module uart_rx #(
    parameter int CLK_FRE   = 50,
    parameter int BAUD_RATE = 115200
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx_pin,
    input  logic       rx_data_ready,
    output logic       rx_data_valid,
    output logic [7:0] rx_data
);

    localparam int CYCLE = CLK_FRE * 1_000_000 / BAUD_RATE;

    typedef enum logic [2:0] {
        S_IDLE,
        S_START,
        S_REC_BYTE,
        S_STOP,
        S_DATA
    } state_t;

    state_t state;
    logic rx_d0, rx_d1, rx_prev;
    logic [7:0] rx_bits;
    logic [$clog2(CYCLE+1)-1:0] cycle_cnt;
    logic [2:0] bit_cnt;

    // 异步串口输入先同步，再检测起始位下降沿
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d0   <= 1'b1;
            rx_d1   <= 1'b1;
            rx_prev <= 1'b1;
        end else begin
            rx_d0   <= rx_pin;
            rx_d1   <= rx_d0;
            rx_prev <= rx_d1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            cycle_cnt     <= '0;
            bit_cnt       <= '0;
            rx_bits       <= '0;
            rx_data       <= '0;
            rx_data_valid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    cycle_cnt <= '0;
                    if (rx_prev && !rx_d1)
                        state <= S_START;
                end

                S_START: begin
                    if (cycle_cnt == CYCLE/2 - 1) begin
                        cycle_cnt <= '0;
                        if (!rx_d1) begin
                            bit_cnt <= '0;
                            state   <= S_REC_BYTE;
                        end else begin
                            state <= S_IDLE; // 假起始位
                        end
                    end else begin
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end
                end

                S_REC_BYTE: begin
                    if (cycle_cnt == CYCLE - 1) begin
                        cycle_cnt        <= '0;
                        rx_bits[bit_cnt] <= rx_d1;
                        if (bit_cnt == 3'd7)
                            state <= S_STOP;
                        else
                            bit_cnt <= bit_cnt + 1'b1;
                    end else begin
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end
                end

                S_STOP: begin
                    if (cycle_cnt == CYCLE - 1) begin
                        cycle_cnt <= '0;
                        if (rx_d1) begin
                            rx_data       <= rx_bits;
                            rx_data_valid <= 1'b1;
                            state         <= S_DATA;
                        end else begin
                            state <= S_IDLE; // 停止位错误，丢弃该帧
                        end
                    end else begin
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end
                end

                S_DATA: begin
                    if (rx_data_ready) begin
                        rx_data_valid <= 1'b0;
                        state         <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
