// pwm_top.v
// Top module: I2C -> pwm_register -> prescaler -> counter -> comparator -> deadtime -> PWM1_OUT
module pwm_top #(
    parameter WIDTH = 32
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // I2C interface (simple slave wrapper)
    inout  wire SDA_bus,
    input  wire SCL_bus,

    // single PWM output for now
    output wire                 PWM1_OUT
);

    // bus wires from i2c_top (example)
    wire [15:0] addr;
    wire [WIDTH-1:0] wdata;
    wire [WIDTH-1:0] rdata;
    wire rd_en;
    wire wr_en;

    // internal regs/signals
    wire                en;
    wire                mode;
    wire [WIDTH-1:0]    period;
    wire [WIDTH-1:0]    ccr_on;
    wire [WIDTH-1:0]    ccr;
    wire [15:0]         prescaler_div;
    wire [15:0]         deadtime_val;

    wire tick;
    wire [WIDTH-1:0] cnt_val;
    wire pwm_raw;    // output from comparator (before deadtime)
    wire pwm_h;
    wire pwm_l;

    // --- I2C top (user's instance) ---
    i2c_top #(
        .SLAVE_ADDR(7'h50)
    ) i2c_top_inst (
        .clk(clk),
        .rst_n(rst_n),
        .SDA_bus(SDA_bus),
        .SCL_bus(SCL_bus),

        .addr(addr),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wdata(wdata),
        .rdata(rdata)
    );

    // --- Register block ---
    pwm_register #(.WIDTH(WIDTH)) u_reg (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .addr(addr),       // pass full 16-bit address
        .wr_data(wdata),
        .rd_data(rdata),

        .en(en),
        .mode(mode),
        .period(period),
        .ccr_on(ccr_on),
        .ccr(ccr),
        .prescaler_div(prescaler_div),
        .deadtime_val(deadtime_val)
    );

    // --- Prescaler ---
    pwm_prescaler u_prescaler (
        .clk(clk),
        .rst_n(rst_n),
        .div(prescaler_div),
        .tick(tick)
    );

    // --- Counter ---
    pwm_counter #(.WIDTH(WIDTH)) u_counter (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .PWM_EN(en),
        .mode(mode),
        .ARR(period),
        .CNT(cnt_val)
    );

    // --- Comparator: uses your comparator module (unchanged) ---
    comparator #(.WIDTH(WIDTH)) u_cmp1 (
        .CNT    (cnt_val),
        .CCR    (ccr),
        .CCR_ON (ccr_on),
        .PERIOD (period),
        .ENABLE (en),
        .PWM_OUT(pwm_raw)
    );

    // --- Deadtime (use your thuBai module unchanged) ---
    // thuBai parameter WIDTH default was 8 in your original file.
    // pass lower bits of deadtime_val (safe).
    thuBai #(.WIDTH(8)) u_deadtime (
        .clk(clk),
        .rst_n(rst_n),
        .pwm_in(pwm_raw),
        .deadtime_val(deadtime_val[7:0]),
        .pwm_high(pwm_h),
        .pwm_low(pwm_l)
    );

    // final output: choose pwm_high as external output
    assign PWM1_OUT = pwm_h;

endmodule
