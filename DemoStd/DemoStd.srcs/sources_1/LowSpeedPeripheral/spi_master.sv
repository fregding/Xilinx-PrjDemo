`timescale 1ns / 1ps

// SPI Mode 0：SCLK 空闲为低，上升沿采样，下降沿换位，MSB 先发。
// 每次 start 发送一个字节，CS 在字节结束后释放。
module spi_master #(
    parameter int CLK_DIV = 5  // SCLK 半周期的系统时钟数，必须 >= 1
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,
    output logic       spi_sclk,
    output logic       spi_cs_n,
    output logic       spi_mosi,
    input  logic       spi_miso
);
    localparam int DIV_WIDTH = (CLK_DIV > 1) ? $clog2(CLK_DIV) : 1;
    typedef enum logic [1:0] {S_IDLE, S_TRANSFER, S_HOLD} state_t;
    state_t state;
    logic [DIV_WIDTH-1:0] div_cnt;
    logic [2:0] bit_cnt;
    logic [7:0] tx_shift;
    logic [7:0] rx_shift;

    // 所有寄存器使用系统时钟，SCLK 仅作为外部输出。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            div_cnt  <= '0;
            bit_cnt  <= '0;
            tx_shift <= '0;
            rx_shift <= '0;
            rx_data  <= '0;
            busy     <= 1'b0;
            done     <= 1'b0;
            spi_sclk <= 1'b0;
            spi_cs_n <= 1'b1;
            spi_mosi <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (start) begin
                        tx_shift <= tx_data;
                        rx_shift <= '0;
                        bit_cnt  <= 3'd7;
                        div_cnt  <= '0;
                        spi_mosi <= tx_data[7]; // 首位先于第一个上升沿准备好
                        spi_cs_n <= 1'b0;
                        busy     <= 1'b1;
                        state    <= S_TRANSFER;
                    end
                end
                S_TRANSFER: begin
                    if (div_cnt == CLK_DIV - 1) begin
                        div_cnt <= '0;
                        if (!spi_sclk) begin
                            spi_sclk <= 1'b1;
                            rx_shift <= {rx_shift[6:0], spi_miso};
                        end else begin
                            spi_sclk <= 1'b0;
                            if (bit_cnt == 0) begin
                                state <= S_HOLD;
                            end else begin
                                bit_cnt  <= bit_cnt - 1'b1;
                                tx_shift <= {tx_shift[6:0], 1'b0};
                                spi_mosi <= tx_shift[6];
                            end
                        end
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end
                S_HOLD: begin
                    // 最后一个下降沿之后保持半周期，再释放片选。
                    if (div_cnt == CLK_DIV - 1) begin
                        div_cnt  <= '0;
                        rx_data  <= rx_shift;
                        spi_cs_n <= 1'b1;
                        spi_mosi <= 1'b0;
                        busy     <= 1'b0;
                        done     <= 1'b1;
                        state    <= S_IDLE;
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end
                default: begin
                    state    <= S_IDLE;
                    spi_sclk <= 1'b0;
                    spi_cs_n <= 1'b1;
                    busy     <= 1'b0;
                    spi_mosi <= 1'b0;
                end
            endcase
        end
    end
endmodule
