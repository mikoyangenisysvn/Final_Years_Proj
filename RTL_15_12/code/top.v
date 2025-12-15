// pwm_top.v
// Top module với giao tiếp APB-lite (simple): psel, penable, pwrite, paddr, pwdata
// Kết nối: pwm_register -> pwm_prescaler -> pwm_counter -> 2 x pwm_comparator

module top #(
    parameter WIDTH = 16
)(
    input  wire  clk,
    input  wire  rst,
    input  wire  capture,

    // APB-lite-ish interface (simple, single peripheral)
    inout  wire SDA_bus,
    input  wire SCL_bus,

    // PWM outputs
    output wire              pwm_ch1_a_o, pwm_ch1_b_o,
    output wire              pwm_ch2_a_o, pwm_ch2_b_o,
    output wire              pwm_ch3_a_o, pwm_ch3_b_o,
    output wire              pwm_ch4_a_o, pwm_ch4_b_o,
    output wire              pwm_ch5_a_o, pwm_ch5_b_o,
    output wire              pwm_ch6_a_o, pwm_ch6_b_o,
    output wire              pwm_ch7_a_o, pwm_ch7_b_o,
    output wire              pwm_ch8_a_o, pwm_ch8_b_o

);
    wire rst_n;
    assign rst_n = ~rst; 

    wire [2:0]  address_set_pin;
    assign address_set_pin = 0;

    wire clk_i2c, clk_pwm;
    I2C_PLL_120Mhz_20Mhz I2C_PLL_inst(
        .clkout(clk_pwm), //output clkout 120Mhz
        .clkoutd(clk_i2c), //output clkoutd 20Mhz
        .reset(rst), //input reset
        .clkin(clk) //input clkin
    );

   
    wire [7:0]addr;
    wire [15:0]wdata, rdata;
    wire rd_en, wr_en;

    // --- I2C Slave Instance ---
    i2c_top u_i2c_top (
        .clk_i            (clk_i2c),
        .rst_n_i          (rst_n),

        .sda_io           (SDA_bus),
        .scl_i            (SCL_bus),

        .address_set_pin_i(address_set_pin),

        .addr_o           (addr),
        .wdata_o          (wdata),
        .rdata_i          (rdata),
        .wr_en_o          (wr_en),
        .rd_en_o          (rd_en)
    );

    pwm_top pwm_top_dut(
        .clk_psc_i(clk_pwm),
        .rst_n_i(rst_n),

        .addr_i(addr),
        .wr_en_i(wr_en),
        .rd_en_i(rd_en),
        .wdata_i(wdata),
        .rdata_o(rdata),

        // Channel 1
        .pwm_ch1_a_o(pwm_ch1_a_o),
        .pwm_ch1_b_o(pwm_ch1_b_o),

        // Channel 2
        .pwm_ch2_a_o(pwm_ch2_a_o),
        .pwm_ch2_b_o(pwm_ch2_b_o),

        // Channel 3
        .pwm_ch3_a_o(pwm_ch3_a_o),
        .pwm_ch3_b_o(pwm_ch3_b_o),

        // Channel 4
        .pwm_ch4_a_o(pwm_ch4_a_o),
        .pwm_ch4_b_o(pwm_ch4_b_o),

        // Channel 5
        .pwm_ch5_a_o(pwm_ch5_a_o),
        .pwm_ch5_b_o(pwm_ch5_b_o),

        // Channel 6
        .pwm_ch6_a_o(pwm_ch6_a_o),
        .pwm_ch6_b_o(pwm_ch6_b_o),

        // Channel 7
        .pwm_ch7_a_o(pwm_ch7_a_o),
        .pwm_ch7_b_o(pwm_ch7_b_o),

        // Channel 8
        .pwm_ch8_a_o(pwm_ch8_a_o),
        .pwm_ch8_b_o(pwm_ch8_b_o)


    );

endmodule
