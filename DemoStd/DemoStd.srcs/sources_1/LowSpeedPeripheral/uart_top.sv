`timescale 1ns / 1ps

// 上电发送 "hello world\r\n"，空闲时回发接收到的字节
module uart_top #(
    parameter int CLK_FRE   = 50,
    parameter int BAUD_RATE = 115200,
    parameter int ONE_SECOND_CNT = CLK_FRE * 1_000_000
)(
    input  logic       sys_clk,
    input  logic       rst_n,
    input  logic       uart_rx,
    output logic       uart_tx
);

    typedef enum logic [2:0] {
        IDLE, SEND, SEND_BUSY, SEND_DONE, WAIT, ECHO_BUSY, ECHO_DONE
    } state_t;
    state_t state;

    logic [7:0] tx_data;
    logic [7:0] tx_str;
    logic       tx_data_valid;
    logic       tx_data_ready;
    logic [7:0] rx_data;
    logic       rx_data_valid;
    logic [31:0] wait_cnt;
    logic [3:0]  tx_cnt;

    always_comb begin
        case (tx_cnt)
            4'd0 : tx_str = "h";
            4'd1 : tx_str = "e";
            4'd2 : tx_str = "l";
            4'd3 : tx_str = "l";
            4'd4 : tx_str = "o";
            4'd5 : tx_str = " ";
            4'd6 : tx_str = "w";
            4'd7 : tx_str = "o";
            4'd8 : tx_str = "r";
            4'd9 : tx_str = "l";
            4'd10: tx_str = "d";
            4'd11: tx_str = 8'h0d;
            4'd12: tx_str = 8'h0a;
            default: tx_str = 8'd0;
        endcase
    end

    // 每个字节只发送一个时钟周期的 valid 脉冲，等待 busy 再等待 ready
    always_ff @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            wait_cnt      <= '0;
            tx_data       <= '0;
            tx_cnt        <= '0;
            tx_data_valid <= 1'b0;
            state         <= IDLE;
        end else begin
            tx_data_valid <= 1'b0;
            case (state)
                IDLE: state <= SEND;

                SEND: begin
                    wait_cnt <= '0;
                    if (tx_data_ready) begin
                        tx_data       <= tx_str;
                        tx_data_valid <= 1'b1;
                        state         <= SEND_BUSY;
                    end
                end

                SEND_BUSY: if (!tx_data_ready) state <= SEND_DONE;

                SEND_DONE: if (tx_data_ready) begin
                    if (tx_cnt == 4'd12) begin
                        tx_cnt   <= '0;
                        state    <= WAIT;
                    end else begin
                        tx_cnt <= tx_cnt + 1'b1;
                        state  <= SEND;
                    end
                end

                WAIT: begin
                    if (rx_data_valid && tx_data_ready) begin
                        tx_data       <= rx_data;
                        tx_data_valid <= 1'b1;
                        wait_cnt      <= '0;
                        state         <= ECHO_BUSY;
                    end else if (wait_cnt == ONE_SECOND_CNT - 1) begin
                        wait_cnt <= '0;
                        state    <= SEND;
                    end else begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end
                end

                ECHO_BUSY: if (!tx_data_ready) state <= ECHO_DONE;
                ECHO_DONE: if (tx_data_ready) state <= WAIT;
                default: state <= IDLE;
            endcase
        end
    end

    uart_rx #(
        .CLK_FRE  (CLK_FRE),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk           (sys_clk),
        .rst_n         (rst_n),
        .rx_pin        (uart_rx),
        .rx_data_ready (1'b1),
        .rx_data_valid (rx_data_valid),
        .rx_data       (rx_data)
    );

    uart_tx #(
        .CLK_FRE  (CLK_FRE),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk           (sys_clk),
        .rst_n         (rst_n),
        .tx_data       (tx_data),
        .tx_data_valid (tx_data_valid),
        .tx_pin        (uart_tx),
        .tx_data_ready (tx_data_ready)
    );

endmodule
