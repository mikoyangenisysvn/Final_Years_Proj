//============================================================
// Module: pwm_top
// Chức năng: Top-level PWM IP có tích hợp I2C control, deadtime,
// 2 kênh PWM độc lập, prescaler, counter và register block.
//============================================================

module pwm_top #(
    parameter WIDTH = 32
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // --- I2C bus ---
    inout  wire SDA_bus,
    input  wire SCL_bus,

    // --- PWM outputs (2 channels) ---
    output wire                 PWM1_OUT,
    output wire                 PWM2_OUT
);

    // ------------------------------------------
    // Internal I2C interface signals
    // ------------------------------------------
    wire [15:0] addr;
    wire [31:0] wdata, rdata;
    wire rd_en, wr_en;
    wire PWM2_OUT_n, PWM1_OUT_n;

    // Deadtime-processed PWM outputs
    wire pwm1_deadtime_high, pwm1_deadtime_low;
    wire pwm2_deadtime_high, pwm2_deadtime_low;

    // Gán đầu ra cuối cùng
    assign PWM1_OUT = pwm1_deadtime_high;
    assign PWM2_OUT = pwm2_deadtime_high;

    // ------------------------------------------
    // I2C Slave Instance
    // ------------------------------------------
    i2c_top #(
        .SLAVE_ADDR(7'h50)
    ) i2c_top_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .SDA_bus(SDA_bus),
        .SCL_bus(SCL_bus),

        .addr  (addr),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .wdata (wdata),
        .rdata (rdata)
    );

    // ------------------------------------------
    // Internal control and configuration wires
    // ------------------------------------------
    wire                en;
    wire                mode;
    wire [WIDTH-1:0]    period;
    wire [WIDTH-1:0]    duty1;
    wire [WIDTH-1:0]    duty2;
    wire [WIDTH-1:0]    prescaler_div;
    wire                deadtime_en;
    wire [WIDTH-1:0]    deadtime_val;

    wire tick;
    wire [WIDTH-1:0] cnt_val;

    // ------------------------------------------
    // Register block (I2C-mapped control registers)
    // ------------------------------------------
    pwm_register #(.WIDTH(WIDTH)) u_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .wr_en        (wr_en),
        .rd_en        (rd_en),
        .addr         (addr[3:0]),
        .wr_data      (wdata),
        .rd_data      (rdata),

        .en           (en),
        .mode         (mode),
        .period       (period),
        .duty1        (duty1),
        .duty2        (duty2),
        .prescaler_div(prescaler_div),
        .deadtime_en  (deadtime_en),
        .deadtime_val (deadtime_val)
    );

    // ------------------------------------------
    // Prescaler (tick generator)
    // ------------------------------------------
    pwm_prescaler u_prescaler (
        .clk  (clk),
        .rst_n(rst_n),
        .div  (prescaler_div[15:0]),
        .tick (tick)
    );

    // ------------------------------------------
    // Counter (driven by tick)
    // ------------------------------------------
    pwm_counter #(.WIDTH(WIDTH)) u_counter (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (tick),
        .PWM_EN(en),
        .mode  (mode),
        .ARR   (period),
        .CNT   (cnt_val)
    );

    // ------------------------------------------
    // Comparators (2 PWM channels)
    // ------------------------------------------
    pwm_comparator #(.WIDTH(WIDTH)) u_cmp1 (
        .CNT     (cnt_val),
        .CCR     (duty1),
        .PERIOD  (period),
        .ENABLE  (en),
        .PWM_OUT (PWM1_OUT_n)
    );

    pwm_comparator #(.WIDTH(WIDTH)) u_cmp2 (
        .CNT     (cnt_val),
        .CCR     (duty2),
        .PERIOD  (period),
        .ENABLE  (en),
        .PWM_OUT (PWM2_OUT_n)
    );

    // ------------------------------------------
    // Deadtime blocks
    // ------------------------------------------
    pwm_deadtime #(.WIDTH(WIDTH)) u_deadtime_ch1 (
        .clk          (clk),
        .rst_n        (rst_n),
        .pwm_in       (~PWM1_OUT_n),        // đảo lại vì comparator xuất mức đảo
        .deadtime_en  (deadtime_en),
        .deadtime_val (deadtime_val[15:0]),
        .pwm_high     (pwm1_deadtime_high),
        .pwm_low      (pwm1_deadtime_low)
    );

    pwm_deadtime #(.WIDTH(WIDTH)) u_deadtime_ch2 (
        .clk          (clk),
        .rst_n        (rst_n),
        .pwm_in       (~PWM2_OUT_n),
        .deadtime_en  (deadtime_en),
        .deadtime_val (deadtime_val[15:0]),
        .pwm_high     (pwm2_deadtime_high),
        .pwm_low      (pwm2_deadtime_low)
    );

endmodule
