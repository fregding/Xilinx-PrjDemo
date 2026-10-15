`timescale 1ns / 1ps

// 伪双口RAM（Simple Dual Port RAM）仿真验证
// A口只写，B口只读；两个端口可以使用不同的时钟
module tb_ram_simpledual;
    logic       clka = 1'b0;
    logic       clkb = 1'b0;
    logic       ena;
    logic       wea;
    logic [7:0] addra;
    logic [7:0] dina;
    logic       enb;
    logic [7:0] addrb;
    wire  [7:0] doutb;

    always #5 clka = ~clka;  // 写时钟：100 MHz
    always #7 clkb = ~clkb;  // 读时钟：约71.4 MHz

    ram_256x8_simpledual dut (
        .clka(clka), .ena(ena), .wea(wea), .addra(addra), .dina(dina),
        .clkb(clkb), .enb(enb), .addrb(addrb), .doutb(doutb)
    );

    initial begin
        ena = 1'b0; wea = 1'b0; addra = 0; dina = 0;
        enb = 1'b0; addrb = 0;

        // 通过A口写入两个地址
        @(negedge clka);
        ena = 1'b1; wea = 1'b1; addra = 8'h12; dina = 8'hA5;
        @(negedge clka);
        addra = 8'h34; dina = 8'h5A;
        @(negedge clka);
        wea = 1'b0;

        // 通过B口读取地址12
        @(negedge clkb);
        enb = 1'b1; addrb = 8'h12;
        @(posedge clkb); #1;
        if (doutb !== 8'hA5)
            $fatal(1, "伪双口RAM地址12读取错误：实际=%h，期望=A5", doutb);

        // 通过B口读取地址34
        @(negedge clkb);
        addrb = 8'h34;
        @(posedge clkb); #1;
        if (doutb !== 8'h5A)
            $fatal(1, "伪双口RAM地址34读取错误：实际=%h，期望=5A", doutb);

        $display("伪双口RAM仿真通过：写入和独立读出均正确。");
        $finish;
    end
endmodule
