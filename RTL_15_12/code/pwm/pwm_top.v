//=====================================================================
// File: pwm_top.v
// Description: PWM Top-Level Module with APB-lite interface
// Hierarchy: pwm_register → pwm_prescaler → pwm_counter → pwm_comparator → pwm_oc_channel
// Author: [Your Name]
//=====================================================================

module pwm_top #(
    parameter integer WIDTH = 16
)(
    // --------------------------------------------------------------
    // Clock & Reset
    // --------------------------------------------------------------
    input  wire              clk_psc_i,     // Prescaled system clock
    input  wire              rst_n_i,       // Active-low reset

    // --------------------------------------------------------------
    // Bus Read-Write Interface
    // --------------------------------------------------------------
    input  wire [7:0]        addr_i,
    input  wire [15:0]       wdata_i,
    output wire [15:0]       rdata_o,
    input  wire              wr_en_i,
    input  wire              rd_en_i,

    // --------------------------------------------------------------
    // PWM Outputs (4 channels)
    // --------------------------------------------------------------
    output wire              pwm_ch1_a_o, pwm_ch1_b_o,
    output wire              pwm_ch2_a_o, pwm_ch2_b_o,
    output wire              pwm_ch3_a_o, pwm_ch3_b_o,
    output wire              pwm_ch4_a_o, pwm_ch4_b_o,
    output wire              pwm_ch5_a_o, pwm_ch5_b_o,
    output wire              pwm_ch6_a_o, pwm_ch6_b_o,
    output wire              pwm_ch7_a_o, pwm_ch7_b_o,
    output wire              pwm_ch8_a_o, pwm_ch8_b_o

);

    //-----------------------------------------------------------------
    // Internal Signals
    //-----------------------------------------------------------------
   
    // --- Core 1 ---
    wire                cnt_en_1_w;
    wire [WIDTH-1:0]    psc_preload_1_w;
    wire [WIDTH-1:0]    arr_preload_1_w;

    // Channel 1
    wire [WIDTH-1:0]    cfg_reg_ch1;
    wire [WIDTH-1:0]    cmp_ch1_start_w, cmp_ch1_end_w;
    wire [7:0]          dtg_ch1_w;

    // Channel 2
    wire [WIDTH-1:0]    cfg_reg_ch2;
    wire [WIDTH-1:0]    cmp_ch2_start_w, cmp_ch2_end_w;
    wire [7:0]          dtg_ch2_w;

    // --- Core 2 ---
    wire                cnt_en_2_w;
    wire [WIDTH-1:0]    psc_preload_2_w;
    wire [WIDTH-1:0]    arr_preload_2_w;

    // Channel 3
    wire [WIDTH-1:0]    cfg_reg_ch3;
    wire [WIDTH-1:0]    cmp_ch3_start_w, cmp_ch3_end_w;
    wire [7:0]          dtg_ch3_w;

    // Channel 4
    wire [WIDTH-1:0]    cfg_reg_ch4;
    wire [WIDTH-1:0]    cmp_ch4_start_w, cmp_ch4_end_w;
    wire [7:0]          dtg_ch4_w;

    // --- Core 3 ---
    wire                cnt_en_3_w;
    wire [WIDTH-1:0]    psc_preload_3_w;
    wire [WIDTH-1:0]    arr_preload_3_w;

    // Channel 5
    wire [WIDTH-1:0]    cfg_reg_ch5;
    wire [WIDTH-1:0]    cmp_ch5_start_w, cmp_ch5_end_w;
    wire [7:0]          dtg_ch5_w;

    // Channel 6
    wire [WIDTH-1:0]    cfg_reg_ch6;
    wire [WIDTH-1:0]    cmp_ch6_start_w, cmp_ch6_end_w;
    wire [7:0]          dtg_ch6_w;

    // --- Core 4 ---
    wire                cnt_en_4_w;
    wire [WIDTH-1:0]    psc_preload_4_w;
    wire [WIDTH-1:0]    arr_preload_4_w;

    // Channel 7
    wire [WIDTH-1:0]    cfg_reg_ch7;
    wire [WIDTH-1:0]    cmp_ch7_start_w, cmp_ch7_end_w;
    wire [7:0]          dtg_ch7_w;

    // Channel 8
    wire [WIDTH-1:0]    cfg_reg_ch8;
    wire [WIDTH-1:0]    cmp_ch8_start_w, cmp_ch8_end_w;
    wire [7:0]          dtg_ch8_w;



    //-----------------------------------------------------------------
    // Register Block
    //-----------------------------------------------------------------
    pwm_register #(
        .WIDTH(WIDTH)
    ) u_pwm_register (
        .clk_psc_i(clk_psc_i),
        .rst_n_i(rst_n_i),

        .wr_en_i(wr_en_i),
        .rd_en_i(rd_en_i),
        .addr_i(addr_i),
        .wr_data_i(wdata_i),
        .rd_data_o(rdata_o),

        // --- Core 1 ---
        .cen_1_o(cnt_en_1_w),
        .arr_preload_1_o(arr_preload_1_w),
        .psc_preload_1_o(psc_preload_1_w),
        .cmp_ch1_start_o(cmp_ch1_start_w),
        .cmp_ch1_end_o(cmp_ch1_end_w),
        .cfg_reg_ch1(cfg_reg_ch1),
        .dtg_ch1_o(dtg_ch1_w),
        .cmp_ch2_start_o(cmp_ch2_start_w),
        .cmp_ch2_end_o(cmp_ch2_end_w),
        .cfg_reg_ch2(cfg_reg_ch2),
        .dtg_ch2_o(dtg_ch2_w),

        // --- Core 2 ---
        .cen_2_o(cnt_en_2_w),
        .arr_preload_2_o(arr_preload_2_w),
        .psc_preload_2_o(psc_preload_2_w),
        .cmp_ch3_start_o(cmp_ch3_start_w),
        .cmp_ch3_end_o(cmp_ch3_end_w),
        .cfg_reg_ch3(cfg_reg_ch3),
        .dtg_ch3_o(dtg_ch3_w),
        .cmp_ch4_start_o(cmp_ch4_start_w),
        .cmp_ch4_end_o(cmp_ch4_end_w),
        .cfg_reg_ch4(cfg_reg_ch4),
        .dtg_ch4_o(dtg_ch4_w),

        // --- Core 3 ---
        .cen_3_o(cnt_en_3_w),
        .arr_preload_3_o(arr_preload_3_w),
        .psc_preload_3_o(psc_preload_3_w),
        .cmp_ch5_start_o(cmp_ch5_start_w),
        .cmp_ch5_end_o(cmp_ch5_end_w),
        .cfg_reg_ch5(cfg_reg_ch5),
        .dtg_ch5_o(dtg_ch5_w),
        .cmp_ch6_start_o(cmp_ch6_start_w),
        .cmp_ch6_end_o(cmp_ch6_end_w),
        .cfg_reg_ch6(cfg_reg_ch6),
        .dtg_ch6_o(dtg_ch6_w),

        // --- Core 4 ---
        .cen_4_o(cnt_en_4_w),
        .arr_preload_4_o(arr_preload_4_w),
        .psc_preload_4_o(psc_preload_4_w),
        .cmp_ch7_start_o(cmp_ch7_start_w),
        .cmp_ch7_end_o(cmp_ch7_end_w),
        .cfg_reg_ch7(cfg_reg_ch7),
        .dtg_ch7_o(dtg_ch7_w),
        .cmp_ch8_start_o(cmp_ch8_start_w),
        .cmp_ch8_end_o(cmp_ch8_end_w),
        .cfg_reg_ch8(cfg_reg_ch8),
        .dtg_ch8_o(dtg_ch8_w)
    );


    pwm_core u_pwm_core_1 (
        .clk_psc_i       (clk_psc_i),
        .rst_n_i         (rst_n_i),

        .cnt_en_w        (cnt_en_1_w),
        .psc_preload_w   (psc_preload_1_w),
        .arr_preload_w   (arr_preload_1_w),

        .cmp_ch1_start_w (cmp_ch1_start_w),
        .cmp_ch1_end_w   (cmp_ch1_end_w),
        .cmp_ch2_start_w (cmp_ch2_start_w),
        .cmp_ch2_end_w   (cmp_ch2_end_w),

        .dtg_ch1_w       (dtg_ch1_w),
        .dtg_ch2_w       (dtg_ch2_w),

        .cfg_reg_ch1     (cfg_reg_ch1),
        .cfg_reg_ch2     (cfg_reg_ch2),

        .pwm_ch1_a_o     (pwm_ch1_a_o),
        .pwm_ch1_b_o     (pwm_ch1_b_o),
        .pwm_ch2_a_o     (pwm_ch2_a_o),
        .pwm_ch2_b_o     (pwm_ch2_b_o)
    );

    pwm_core u_pwm_core_2 (
        .clk_psc_i       (clk_psc_i),
        .rst_n_i         (rst_n_i),

        .cnt_en_w        (cnt_en_1_w),
        .psc_preload_w   (psc_preload_1_w),
        .arr_preload_w   (arr_preload_1_w),

        .cmp_ch1_start_w (cmp_ch3_start_w),
        .cmp_ch1_end_w   (cmp_ch3_end_w),
        .cmp_ch2_start_w (cmp_ch4_start_w),
        .cmp_ch2_end_w   (cmp_ch4_end_w),

        .dtg_ch1_w       (dtg_ch3_w),
        .dtg_ch2_w       (dtg_ch4_w),

        .cfg_reg_ch1     (cfg_reg_ch3),
        .cfg_reg_ch2     (cfg_reg_ch4),

        .pwm_ch1_a_o     (pwm_ch3_a_o),
        .pwm_ch1_b_o     (pwm_ch3_b_o),
        .pwm_ch2_a_o     (pwm_ch4_a_o),
        .pwm_ch2_b_o     (pwm_ch4_b_o)
    );

    pwm_core u_pwm_core_3 (
        .clk_psc_i       (clk_psc_i),
        .rst_n_i         (rst_n_i),

        .cnt_en_w        (cnt_en_3_w),
        .psc_preload_w   (psc_preload_3_w),
        .arr_preload_w   (arr_preload_3_w),

        .cmp_ch1_start_w (cmp_ch5_start_w),
        .cmp_ch1_end_w   (cmp_ch5_end_w),
        .cmp_ch2_start_w (cmp_ch6_start_w),
        .cmp_ch2_end_w   (cmp_ch6_end_w),

        .dtg_ch1_w       (dtg_ch5_w),
        .dtg_ch2_w       (dtg_ch6_w),

        .cfg_reg_ch1     (cfg_reg_ch5),
        .cfg_reg_ch2     (cfg_reg_ch6),

        .pwm_ch1_a_o     (pwm_ch5_a_o),
        .pwm_ch1_b_o     (pwm_ch5_b_o),
        .pwm_ch2_a_o     (pwm_ch6_a_o),
        .pwm_ch2_b_o     (pwm_ch6_b_o)
    );

    pwm_core u_pwm_core_4 (
        .clk_psc_i       (clk_psc_i),
        .rst_n_i         (rst_n_i),

        .cnt_en_w        (cnt_en_4_w),
        .psc_preload_w   (psc_preload_4_w),
        .arr_preload_w   (arr_preload_4_w),

        .cmp_ch1_start_w (cmp_ch7_start_w),
        .cmp_ch1_end_w   (cmp_ch7_end_w),
        .cmp_ch2_start_w (cmp_ch8_start_w),
        .cmp_ch2_end_w   (cmp_ch8_end_w),

        .dtg_ch1_w       (dtg_ch7_w),
        .dtg_ch2_w       (dtg_ch8_w),

        .cfg_reg_ch1     (cfg_reg_ch7),
        .cfg_reg_ch2     (cfg_reg_ch8),

        .pwm_ch1_a_o     (pwm_ch7_a_o),
        .pwm_ch1_b_o     (pwm_ch7_b_o),
        .pwm_ch2_a_o     (pwm_ch8_a_o),
        .pwm_ch2_b_o     (pwm_ch8_b_o)
    );





endmodule
