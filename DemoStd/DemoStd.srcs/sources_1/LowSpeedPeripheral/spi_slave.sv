`timescale 1ns / 1ps

// SPI ´Ó»ú£º8 Î»¡¢MSB first¡¢SPI Mode 0£¨CPOL=0£¬CPHA=0£©
module spi_slave #(
    parameter logic [7:0] RESPONSE_DATA = 8'hA5
)(
    input  logic       rst_n,
    input  logic       spi_cs_n,
    input  logic       spi_sclk,
    input  logic       spi_mosi,
    output logic       spi_miso,
    output logic [7:0] rx_data,
    output logic       rx_valid
);

    logic [7:0] rx_shift;
    logic [7:0] tx_shift;
    logic [2:0] bit_cnt;

    always_ff @(negedge spi_cs_n or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift <= '0;
            tx_shift <= RESPONSE_DATA;
            bit_cnt  <= '0;
            rx_data  <= '0;
            rx_valid <= 1'b0;
            spi_miso <= 1'b0;
        end else begin
            rx_shift <= '0;
            tx_shift <= RESPONSE_DATA;
            bit_cnt  <= '0;
            rx_valid <= 1'b0;
            spi_miso <= RESPONSE_DATA[7];
        end
    end

    always_ff @(posedge spi_sclk or posedge spi_cs_n or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift <= '0;
            tx_shift <= RESPONSE_DATA;
            bit_cnt  <= '0;
            rx_data  <= '0;
            rx_valid <= 1'b0;
            spi_miso <= 1'b0;
        end else if (spi_cs_n) begin
            spi_miso <= 1'b0;
        end else begin
            rx_shift <= {rx_shift[6:0], spi_mosi};
            if (bit_cnt == 3'd7) begin
                rx_data  <= {rx_shift[6:0], spi_mosi};
                rx_valid <= 1'b1;
            end
        end
    end

    always_ff @(negedge spi_sclk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= RESPONSE_DATA;
            bit_cnt  <= '0;
            spi_miso <= 1'b0;
        end else if (!spi_cs_n) begin
            if (bit_cnt != 3'd7) begin
                bit_cnt  <= bit_cnt + 1'b1;
                tx_shift <= {tx_shift[6:0], 1'b0};
                spi_miso <= tx_shift[6];
            end else begin
                spi_miso <= 1'b0;
            end
        end
    end

endmodule
