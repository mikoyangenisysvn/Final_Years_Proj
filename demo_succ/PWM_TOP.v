// pwm_top.v
// Top module với giao tiếp APB-lite (simple): psel, penable, pwrite, paddr, pwdata
// Kết nối: pwm_register -> pwm_prescaler -> pwm_counter -> 2 x pwm_comparator

module pwm_top #(
    parameter WIDTH = 32
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // APB-lite-ish interface (simple, single peripheral)
    inout  wire SDA_bus,
    input  wire SCL_bus,

    // PWM outputs (2 channels)
    output wire                 PWM1_OUT,
    output wire                 PWM2_OUT
);

    //wire rst_n;
    //assign rst_n = ~rst;    

    wire [15:0]addr;
    wire [31:0]wdata, rdata;
    wire rd_en, wr_en;
    wire PWM2_OUT_n, PWM1_OUT_n;

    assign PWM1_OUT = ~PWM1_OUT_n;
    assign PWM2_OUT = ~PWM2_OUT_n;

    // --- I2C Slave Instance ---
    i2c_top#(
        .SLAVE_ADDR(7'h50)  // Địa chỉ 0x42
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



    // -------- Internal signals --------
    wire                en;
    wire                mode;
    wire [WIDTH-1:0]    period;
    wire [WIDTH-1:0]    duty1;
    wire [WIDTH-1:0]    duty2;
    wire [WIDTH-1:0]    prescaler_div;

    wire tick;
    wire [WIDTH-1:0] cnt_val;

    // -------- Register block (memory-mapped) --------
    // pwm_register must have ports:
    // (clk, rst_n, wr_en, rd_en, addr, wr_data, rd_data, en, mode, period, duty1, duty2, prescaler_div)
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
        .prescaler_div(prescaler_div)
    );

    // -------- Prescaler (tick generator) --------
    // pwm_prescaler(clk, rst_n, div, tick)
    pwm_prescaler u_prescaler (
        .clk  (clk),
        .rst_n(rst_n),
        .div  (prescaler_div[15:0]),
        .tick (tick)
    );

    // -------- Counter (driven by tick) --------
    // pwm_counter(clk, rst_n, tick, PWM_EN, mode, ARR, CNT)
    pwm_counter #(.WIDTH(WIDTH)) u_counter (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (tick),
        .PWM_EN(en),
        .mode  (mode),
        .ARR   (period),
        .CNT   (cnt_val)
    );

    // -------- Comparators (2 channels) --------
    // pwm_comparator(CNT, CCR, PERIOD, ENABLE, PWM_OUT)
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

endmodule
