module pwm_top #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // giao diện ghi/đọc
    input  wire                 wr_en,
    input  wire                 rd_en,
    input  wire [3:0]           addr,
    input  wire [WIDTH-1:0]     wr_data,
    output wire [WIDTH-1:0]     rd_data,

    // ngõ ra PWM
    output wire                 PWM1_OUT,
    output wire                 PWM2_OUT
);

    // ------------------- Kết nối nội bộ -------------------
    wire en, mode;
    wire [WIDTH-1:0] period, duty1, duty2, prescaler_div;
    wire tick;
    wire [WIDTH-1:0] cnt_val;

    // ------------------- Register -------------------
    pwm_register #(.WIDTH(WIDTH)) u_reg (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data),

        .en(en),
        .mode(mode),
        .period(period),
        .duty1(duty1),
        .duty2(duty2),
        .prescaler_div(prescaler_div)
    );

    // ------------------- Prescaler (tick generator) -------------------
    pwm_prescaler u_prescaler (
        .clk(clk),
        .rst_n(rst_n),
        .div(prescaler_div[15:0]),
        .tick(tick)
    );

    // ------------------- Counter -------------------
    pwm_counter #(.WIDTH(WIDTH)) u_counter (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .PWM_EN(en),
        .mode(mode),
        .ARR(period),
        .CNT(cnt_val)
    );

    // ------------------- Comparator 1 -------------------
    pwm_comparator #(.WIDTH(WIDTH)) u_cmp1 (
        .CNT(cnt_val),
        .CCR(duty1),
        .PERIOD(period),
        .ENABLE(en),
        .PWM_OUT(PWM1_OUT)
    );

    // ------------------- Comparator 2 -------------------
    pwm_comparator #(.WIDTH(WIDTH)) u_cmp2 (
        .CNT(cnt_val),
        .CCR(duty2),
        .PERIOD(period),
        .ENABLE(en),
        .PWM_OUT(PWM2_OUT)
    );

endmodule
