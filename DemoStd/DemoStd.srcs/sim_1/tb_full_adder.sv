`timescale 1ns / 1ps

// 1位全加器自检仿真：遍历全部8种输入组合
module tb_full_adder;
    logic a;
    logic b;
    logic cin;
    logic sum;
    logic cout;
    logic [1:0] expected;
    integer     i;

    // 实例化待测全加器（DUT）
    full_adder dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #10; // 等待组合逻辑稳定

            // expected[1]为进位，expected[0]为求和结果
            expected = a + b + cin;
            if ({cout, sum} !== expected) begin
                $fatal(1, "全加器错误：a=%b, b=%b, cin=%b, 期望={%b,%b}, 实际={%b,%b}",
                    a, b, cin, expected[1], expected[0], cout, sum);
            end
        end

        $display("通过：全加器的全部8种输入组合均正确。");
        $finish;
    end
endmodule
