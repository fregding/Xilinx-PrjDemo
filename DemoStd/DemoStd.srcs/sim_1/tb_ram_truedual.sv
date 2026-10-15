`timescale 1ns / 1ps

// 真双口RAM（True Dual Port RAM）仿真验证
// A、B两个端口都可以独立读写，并使用各自的时钟
module tb_ram_truedual;
    logic       clka = 1'b0;
    logic       clkb = 1'b0;
    logic       ena;
    logic       wea;
    logic [7:0] addra;
    logic [7:0] dina;
    wire  [7:0] douta;
    logic       enb;
    logic       web;
    logic [7:0] addrb;
    logic [7:0] dinb;
    wire  [7:0] doutb;

    always #5 clka = ~clka;  // A口时钟：100 MHz
    always #7 clkb = ~clkb;  // B口时钟：约71.4 MHz

    ram_256x8_truedual dut (
        .clka(clka), .ena(ena), .wea(wea), .addra(addra), .dina(dina), .douta(douta),
        .clkb(clkb), .enb(enb), .web(web), .addrb(addrb), .dinb(dinb), .doutb(doutb)
    );

    initial begin
        ena = 1'b0; wea = 1'b0; addra = 0; dina = 0;
        enb = 1'b0; web = 1'b0; addrb = 0; dinb = 0;

        // A口写入地址12
        @(negedge clka);
        ena = 1'b1; wea = 1'b1; addra = 8'h12; dina = 8'hA5;
        @(posedge clka);
        wea = 1'b0;

        // B口读取地址12，验证A口写入内容
        @(negedge clkb);
        enb = 1'b1; addrb = 8'h12;
        @(posedge clkb); #1;
        if (doutb !== 8'hA5)
            $fatal(1, "真双口RAM B口读取错误：实际=%h，期望=A5", doutb);

        // B口写入地址34
        @(negedge clkb);
        web = 1'b1; addrb = 8'h34; dinb = 8'h5A;
        @(posedge clkb);
        web = 1'b0;

        // A口读取地址34，验证B口写入内容
        @(negedge clka);
        addra = 8'h34;
        @(posedge clka); #1;
        if (douta !== 8'h5A)
            $fatal(1, "真双口RAM A口读取错误：实际=%h，期望=5A", douta);

        $display("真双口RAM仿真通过：A、B端口独立读写均正确。");
        $finish;
    end
endmodule
