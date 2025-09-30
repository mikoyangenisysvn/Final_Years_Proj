module pwm_top_with_reg #(
    parameter WIDTH       = 16,
    parameter PRESC_WIDTH = 16
)(
    input  wire              clk,
    input  wire              rst_n,

    // giao diện bus tới register
    input  wire              wr_en,
    input  wire              rd_en,
    input  wire [3:0]        addr,
    input  wire [WIDTH-1:0]  wr_data,
    output wire [WIDTH-1:0]  rd_data,

    // output PWM
    output wire              pwm_out
);

    // kết nối nội bộ
    wire              en;
    wire              mode;
    wire [WIDTH-1:0]  ARR;
    wire [WIDTH-1:0]  CCR;
    wire [WIDTH-1:0]  prescaler_div;

    wire tick;
    wire [WIDTH-1:0] counter_value;

    // Register block
    pwm_register #(
        .WIDTH(WIDTH)
    ) u_register (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .en(en),
        .mode(mode),
        .period(period),
        .duty(duty),
        .prescaler_div(prescaler_div)
    );

    // Prescaler
    prescaler_tick #(
        .WIDTH(PRESC_WIDTH)
    ) u_prescaler (
        .clk_in(clk),
        .rst(rst),
        .en(en),
        .tick(tick)
    );

    // Counter
    counter #(
        .WIDTH(WIDTH)
    ) u_counter (
        .clk(tick),
        .cnt_rst(rst),
        .PWM_EN(en),
        .mode(mode),
        .period(period),
        .cnt_val(counter_value)
    );

    // Comparator
    comparator #(
        .WIDTH(WIDTH)
    ) u_comparator (
        .counter_value(counter_value),
        .duty(duty),
        .enable(en),
        .pwm_out(pwm_out)
    );

endmodule
