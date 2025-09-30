module pwm_top #(
    parameter WIDTH = 16
)(
    input  wire             clk,       // clock hệ thống (nhanh)
    input  wire             rst_n,     // reset toàn cục, active low

    // giao diện ghi/đọc thanh ghi
    input  wire             wr_en,
    input  wire             rd_en,
    input  wire [3:0]       addr,
    input  wire [WIDTH-1:0] wr_data,
    output wire [WIDTH-1:0] rd_data,

    // output PWM
    output wire             pwm_out
);

    // --- Wire kết nối ---
    wire              en;
    wire              mode;
    wire [WIDTH-1:0]  period;
    wire [WIDTH-1:0]  duty;
    wire [WIDTH-1:0]  prescaler_div;

    wire              slow_clk;
    wire [WIDTH-1:0]  cnt_val;

    // --- Instance register block ---
    pwm_register #(
        .WIDTH(WIDTH)
    ) u_reg (
        .clk(clk),
        .rst(~rst_n),   // vì register bạn để reset active high
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

    // --- Instance prescaler ---
    prescaler u_prescaler (
        .clk(clk),
        .rst_n(rst_n),
        .div(prescaler_div[15:0]), // lấy 16 bit thấp
        .slow_clk(slow_clk)
    );

    // --- Instance counter ---
    counter #(
        .WIDTH(WIDTH)
    ) u_counter (
        .clk(slow_clk),
        .rst_n(rst_n),    // module counter bạn viết là active high -> cần sửa nếu muốn đồng bộ
        .PWM_EN(en),
        .mode(mode),
        .AAR(period),
        .cnt_val(cnt_val)
    );

    // --- Instance comparator ---
    comparator #(
        .WIDTH(WIDTH)
    ) u_comparator (
        .CCR(cnt_val),
        .CCR_COMPARE(duty),
        .period(period),
        .enable(en),
        .pwm_out(pwm_out)
    );

endmodule
