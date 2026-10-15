`timescale 1ns / 1ps

// 单主机、7位地址、单寄存器事务；start仅在空闲时接受，输入在接受时锁存。
// 引脚必须有外部上拉；不支持多主机仲裁。参数仅支持 REG_BITS/DATA_BITS 为8或16。
module i2c_master #(
    parameter int CLK_HZ = 50_000_000,
    parameter int I2C_HZ = 100_000,
    parameter int REG_BITS = 8,
    parameter int DATA_BITS = 8,
    parameter int STRETCH_TIMEOUT_CYCLES = 50_000 // 0表示无限等待
)(
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 start,
    input  logic                 read_not_write,
    input  logic [6:0]           dev_addr,
    input  logic [REG_BITS-1:0]  reg_addr,
    input  logic [DATA_BITS-1:0] write_data,
    output logic [DATA_BITS-1:0] read_data,
    output logic                 busy,
    output logic                 done,
    output logic                 ack_error,
    output logic                 stretch_timeout,
    inout  wire                  scl,
    inout  wire                  sda
);
    localparam int PERIOD = CLK_HZ / I2C_HZ;
    // 标准模式约5/5 us；快速模式低电平至少1.3us，高电平至少0.6us。
    localparam int LOW_CYCLES = I2C_HZ <= 100_000 ? (PERIOD + 1) / 2 : (PERIOD * 56 + 99) / 100;
    localparam int HIGH_CYCLES = PERIOD - LOW_CYCLES;
    // 同步SCL实际高电平需要3个clk；抵消这一等待以保持总线频率。
    localparam int LOW_TIMER = LOW_CYCLES - 3;

    typedef enum logic [3:0] {
        IDLE, START_SETUP, START_HOLD, BIT_LOW, BIT_RISE, BIT_HIGH,
        REP_LOW, REP_RISE, REP_HIGH, STOP_LOW, STOP_RISE, STOP_HIGH, STOP_FREE
    } state_t;
    state_t state;
    logic scl_low, sda_low;
    logic scl_meta, scl_sync;
    logic [6:0] addr_latched;
    logic [REG_BITS-1:0] reg_latched;
    logic [DATA_BITS-1:0] data_latched;
    logic read_latched;
    logic [7:0] tx_byte;
    logic [2:0] bit_index;
    logic ack_slot;
    logic [2:0] phase;
    logic [DATA_BITS-1:0] rx_shift;
    logic [31:0] timer, stretch_count;

    assign scl = scl_low ? 1'b0 : 1'bz;
    assign sda = sda_low ? 1'b0 : 1'bz;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_meta <= 1'b0;
            scl_sync <= 1'b0;
        end else begin
            scl_meta <= scl;
            scl_sync <= scl_meta;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            scl_low <= 1'b0;
            sda_low <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            ack_error <= 1'b0;
            stretch_timeout <= 1'b0;
            read_data <= '0;
            rx_shift <= '0;
            addr_latched <= '0;
            reg_latched <= '0;
            data_latched <= '0;
            read_latched <= 1'b0;
            tx_byte <= '0;
            bit_index <= '0;
            ack_slot <= 1'b0;
            phase <= '0;
            timer <= '0;
            stretch_count <= '0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: if (start && scl_sync && sda) begin
                    addr_latched <= dev_addr;
                    reg_latched <= reg_addr;
                    data_latched <= write_data;
                    read_latched <= read_not_write;
                    ack_error <= 1'b0;
                    stretch_timeout <= 1'b0;
                    busy <= 1'b1;
                    phase <= 0;
                    timer <= HIGH_CYCLES - 1;
                    state <= START_SETUP;
                end
                START_SETUP: if (timer == 0) begin
                    sda_low <= 1'b1;
                    timer <= HIGH_CYCLES - 1;
                    state <= START_HOLD;
                end else timer <= timer - 1'b1;
                START_HOLD: if (timer == 0) begin
                    scl_low <= 1'b1;
                    tx_byte <= {addr_latched, phase == 5};
                    sda_low <= ~addr_latched[6];
                    if (phase != 5) phase <= 0;
                    bit_index <= 7;
                    ack_slot <= 1'b0;
                    timer <= LOW_TIMER - 1;
                    state <= BIT_LOW;
                end else timer <= timer - 1'b1;
                BIT_LOW, REP_LOW, STOP_LOW: if (timer == 0) begin
                    scl_low <= 1'b0;
                    stretch_count <= 0;
                    case (state)
                        BIT_LOW: state <= BIT_RISE;
                        REP_LOW: state <= REP_RISE;
                        default: state <= STOP_RISE;
                    endcase
                end else timer <= timer - 1'b1;
                BIT_RISE, REP_RISE, STOP_RISE: begin
                    if (scl_sync) begin
                        timer <= HIGH_CYCLES - 1;
                        case (state)
                            BIT_RISE: state <= BIT_HIGH;
                            REP_RISE: state <= REP_HIGH;
                            default: state <= STOP_HIGH;
                        endcase
                    end else if (STRETCH_TIMEOUT_CYCLES != 0 &&
                                 stretch_count >= STRETCH_TIMEOUT_CYCLES - 1) begin
                        // SCL被从机压低时无法保证生成STOP，释放双线并报告超时。
                        scl_low <= 1'b0;
                        sda_low <= 1'b0;
                        busy <= 1'b0;
                        done <= 1'b1;
                        stretch_timeout <= 1'b1;
                        state <= IDLE;
                    end else stretch_count <= stretch_count + 1'b1;
                end
                BIT_HIGH: if (timer != 0) timer <= timer - 1'b1;
                else if (phase >= 6) begin
                    // 接收字节：第9拍主机ACK第一字节，NACK最后一字节。
                    scl_low <= 1'b1;
                    timer <= LOW_TIMER - 1;
                    if (!ack_slot) begin
                        rx_shift <= {rx_shift[DATA_BITS-2:0], sda};
                        if (bit_index == 0) begin
                            ack_slot <= 1'b1;
                            sda_low <= (phase == 6 && DATA_BITS == 16);
                        end else bit_index <= bit_index - 1'b1;
                        state <= BIT_LOW;
                    end else if (phase == 6 && DATA_BITS == 16) begin
                        phase <= 7;
                        bit_index <= 7;
                        ack_slot <= 1'b0;
                        sda_low <= 1'b0;
                        state <= BIT_LOW;
                    end else begin
                        read_data <= rx_shift;
                        sda_low <= 1'b1;
                        state <= STOP_LOW;
                    end
                end else if (!ack_slot) begin
                    scl_low <= 1'b1;
                    timer <= LOW_TIMER - 1;
                    if (bit_index == 0) begin
                        ack_slot <= 1'b1;
                        sda_low <= 1'b0;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                        sda_low <= ~tx_byte[bit_index-1'b1];
                    end
                    state <= BIT_LOW;
                end else begin
                    scl_low <= 1'b1;
                    timer <= LOW_TIMER - 1;
                    ack_slot <= 1'b0;
                    bit_index <= 7;
                    if (sda !== 1'b0) begin
                        ack_error <= 1'b1;
                        sda_low <= 1'b1;
                        state <= STOP_LOW;
                    end else case (phase)
                        0: begin
                            phase <= 1;
                            tx_byte <= REG_BITS == 16 ? reg_latched >> 8 : reg_latched;
                            sda_low <= REG_BITS == 16 ? ~reg_latched[15] : ~reg_latched[REG_BITS-1];
                            state <= BIT_LOW;
                        end
                        1: if (REG_BITS == 16) begin
                            phase <= 2;
                            tx_byte <= reg_latched[7:0];
                            sda_low <= ~reg_latched[7];
                            state <= BIT_LOW;
                        end else if (read_latched) begin
                            sda_low <= 1'b0;
                            state <= REP_LOW;
                        end else begin
                            phase <= 3;
                            tx_byte <= DATA_BITS == 16 ? data_latched >> 8 : data_latched;
                            sda_low <= ~data_latched[DATA_BITS-1];
                            state <= BIT_LOW;
                        end
                        2: if (read_latched) begin
                            sda_low <= 1'b0;
                            state <= REP_LOW;
                        end else begin
                            phase <= 3;
                            tx_byte <= DATA_BITS == 16 ? data_latched >> 8 : data_latched;
                            sda_low <= ~data_latched[DATA_BITS-1];
                            state <= BIT_LOW;
                        end
                        3: if (DATA_BITS == 16) begin
                            phase <= 4;
                            tx_byte <= data_latched[7:0];
                            sda_low <= ~data_latched[7];
                            state <= BIT_LOW;
                        end else begin
                            sda_low <= 1'b1;
                            state <= STOP_LOW;
                        end
                        4: begin
                            sda_low <= 1'b1;
                            state <= STOP_LOW;
                        end
                        5: begin
                            phase <= 6;
                            rx_shift <= '0;
                            sda_low <= 1'b0;
                            state <= BIT_LOW;
                        end
                        default: state <= IDLE;
                    endcase
                end
                REP_HIGH: if (timer == 0) begin
                    sda_low <= 1'b1;
                    timer <= HIGH_CYCLES - 1;
                    state <= START_HOLD;
                    // START_HOLD通常准备写地址，重复起始改由phase选择读地址。
                    phase <= 5;
                end else timer <= timer - 1'b1;
                STOP_HIGH: if (timer == 0) begin
                    sda_low <= 1'b0;
                    timer <= LOW_CYCLES - 1;
                    state <= STOP_FREE;
                end else timer <= timer - 1'b1;
                STOP_FREE: if (timer == 0) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end else timer <= timer - 1'b1;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
