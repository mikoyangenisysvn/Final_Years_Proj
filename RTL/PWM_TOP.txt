module PWM_top (
    input  wire        clk,
    input  wire        resetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pwm_out
);

    wire [15:0] duty_cycle;
    wire [15:0] period;
    wire [15:0] counter_value;

    // Register module
    register u_reg (
        .clk(clk),
        .resetn(resetn),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .duty_cycle(duty_cycle),
        .period(period)
    );

    // Counter
    counter u_counter (
        .clk(clk),
        .resetn(resetn),
        .period(period),
        .count(counter_value)
    );

    // Comparator
    comparator u_comp (
        .counter(counter_value),
        .duty_cycle(duty_cycle),
        .pwm_out(pwm_out)
    );

endmodule
