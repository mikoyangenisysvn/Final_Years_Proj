module pwm_test_top (
    input wire clk,
    input wire rst_n,
    output wire pwm_ch1,
    output wire pwm_ch2
);

    wire [15:0] arr_val  = 16'd9999;   // Chu kỳ ~10k
    wire [15:0] ccr1_val = 16'd2500;   // Duty 25%
    wire [15:0] ccr2_val = 16'd7500;   // Duty 75%

    pwm_apb_ip u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        .psel(1'b0),       // Không dùng APB
        .pwrite(1'b0),
        .penable(1'b0),
        .paddr(12'h000),
        .pwdata(32'h0),
        .pready(),
        .prdata(),
        .pwm_ch1(pwm_ch1),
        .pwm_ch2(pwm_ch2)
    );

    // Gán giá trị cố định
    initial begin
        u_pwm.u_apb.arr       = arr_val;
        u_pwm.u_apb.ccr1      = ccr1_val;
        u_pwm.u_apb.ccr2      = ccr2_val;
        u_pwm.u_apb.en_global = 1'b1;
        u_pwm.u_apb.en_ch1    = 1'b1;
        u_pwm.u_apb.en_ch2    = 1'b1;
    end

endmodule
