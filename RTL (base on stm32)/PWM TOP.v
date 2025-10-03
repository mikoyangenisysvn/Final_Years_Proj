module pwm_ip (
    input  wire clk,
    input  wire rst_n,
    input  wire [15:0] arr_in,
    input  wire [15:0] ccr_in,
    output wire pwm_out
);

    wire [15:0] arr, ccr;
    wire [15:0] count;

    // Register bank
    reg_bank u_reg (
        .arr_in(arr_in),
        .ccr_in(ccr_in),
        .arr(arr),
        .ccr(ccr)
    );

    // Counter
    counter u_cnt (
        .clk(clk),
        .rst_n(rst_n),
        .arr(arr),
        .count(count)
    );

    // Comparator
    comparator u_cmp (
        .count(count),
        .ccr(ccr),
        .pwm_out(pwm_out)
    );

endmodule
