module pwm_apb_ip #(
    parameter WIDTH = 16
)(
    // Clock & reset
    input  wire        clk,
    input  wire        rst_n,

    // APB interface
    input  wire        psel,
    input  wire        pwrite,
    input  wire        penable,
    input  wire [11:0] paddr,
    input  wire [31:0] pwdata,
    output wire        pready,
    output wire [31:0] prdata,

    // PWM outputs
    output wire        pwm_ch1,
    output wire        pwm_ch2
);
    // Wires từ APB
    wire [WIDTH-1:0] arr_w;
    wire [WIDTH-1:0] ccr1_w, ccr2_w;
    wire en_global_w, en_ch1_w, en_ch2_w;
    wire inv_ch1_w, inv_ch2_w;

    // APB register block
    apb_pwm #(.WIDTH(WIDTH)) u_apb (
        .clk(clk),
        .rst_n(rst_n),
        .psel(psel),
        .pwrite(pwrite),
        .penable(penable),
        .paddr(paddr),
        .pwdata(pwdata),
        .pready(pready),
        .prdata(prdata),
        .arr(arr_w),
        .ccr1(ccr1_w),
        .ccr2(ccr2_w),
        .en_global(en_global_w),
        .en_ch1(en_ch1_w),
        .en_ch2(en_ch2_w),
        .inv_ch1(inv_ch1_w),
        .inv_ch2(inv_ch2_w)
    );

    // Counter dùng chung cho hai kênh
    wire [WIDTH-1:0] count_w;
    counter #(.WIDTH(WIDTH)) u_counter (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_global_w), // bật/tắt toàn IP
        .arr(arr_w),
        .count(count_w)
    );

    // Comparator cho CH1
    comparator #(.WIDTH(WIDTH)) u_cmp1 (
        .count(count_w),
        .ccr(ccr1_w),
        .en(en_ch1_w),
        .invert(inv_ch1_w),
        .pwm_out(pwm_ch1)
    );

    // Comparator cho CH2
    comparator #(.WIDTH(WIDTH)) u_cmp2 (
        .count(count_w),
        .ccr(ccr2_w),
        .en(en_ch2_w),
        .invert(inv_ch2_w),
        .pwm_out(pwm_ch2)
    );

endmodule
