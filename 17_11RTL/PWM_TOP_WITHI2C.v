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
    // APB-lite Interface (simplified)
    // --------------------------------------------------------------
    input  wire [7:0]        addr_i,
    input  wire [15:0]       wdata_i,
    output wire [15:0]       rdata_o,
    input  wire              write_i,
    input  wire              read_i,

    // --------------------------------------------------------------
    // PWM Outputs (4 channels)
    // --------------------------------------------------------------
    output wire              pwm_ch1_o,
    output wire              pwm_ch2_o
);

  wire [7:0]  i2c_addr;
  wire [15:0] i2c_data;
  wire        i2c_write;
    //-----------------------------------------------------------------
    // Internal Signals
    //-----------------------------------------------------------------
    wire                cnt_en_w;
    wire [WIDTH-1:0]    arr_preload_w;
    wire [WIDTH-1:0]    cmp_ch1_start_w, cmp_ch1_end_w;
    wire [WIDTH-1:0]    cmp_ch2_start_w, cmp_ch2_end_w;
    wire [WIDTH-1:0]    cmp_ch3_start_w, cmp_ch3_end_w;
    wire [WIDTH-1:0]    cmp_ch4_start_w, cmp_ch4_end_w;
    wire [WIDTH-1:0]    psc_preload_w;

    wire [7:0]          dtg_ch1_w;
    wire                ck_cnt_w;
    wire [WIDTH-1:0]    cnt_val_w;
    wire                overflow_w;

    wire [WIDTH-1:0] cfg_reg_ch1;

//==========================================
//i2c
//===========================================
  i2c_slave_pwm i2c_if (
    .clk        (clk_psc_i),
    .rst_n      (rst_n_i),

    .scl        (i2c_scl_i),
    .sda        (i2c_sda_io),

    .reg_addr_o (i2c_addr),
    .reg_wdata_o(i2c_data),
    .reg_write_o(i2c_write),

    .reg_rdata_i(rdata_o)
);


    //-----------------------------------------------------------------
    // Register Block
    //-----------------------------------------------------------------
    pwm_register #(
        .WIDTH (WIDTH)
    ) u_pwm_register (
        .clk_psc_i       (clk_psc_i),
        .rst_n_i         (rst_n_i),

        .wr_en_i         (write_i),
        .rd_en_i         (read_i),
        .addr_i          (addr_i),
        .wr_data_i       (wdata_i),
        .rd_data_o       (rdata_o),

        .cen_o           (cnt_en_w),
        .arr_preload_o   (arr_preload_w),

        .cmp_ch1_start_o (cmp_ch1_start_w),
        .cmp_ch1_end_o   (cmp_ch1_end_w),

        .dtg_ch1_o       (dtg_ch1_w),
        .psc_preload_o   (psc_preload_w),
        .cfg_reg_ch1    (cfg_reg_ch1)
    );

    //-----------------------------------------------------------------
    // Prescaler
    //-----------------------------------------------------------------
    pwm_prescaler #(
        .PSC_WIDTH (16)
    ) u_pwm_prescaler (
        .clk_psc_i     (clk_psc_i),
        .rst_n_i       (rst_n_i),
        .cen_i         (cnt_en_w),
        .psc_preload_i (psc_preload_w),
        .ck_cnt_o      (ck_cnt_w)
    );

    //-----------------------------------------------------------------
    // Counter
    //-----------------------------------------------------------------
    pwm_counter #(
        .CNT_WIDTH (16)
    ) u_pwm_counter (
        .clk_psc_i     (clk_psc_i),
        .rst_n_i       (rst_n_i),
        .ck_cnt_i      (ck_cnt_w),
        .cnt_en_i      (cnt_en_w),
        .arr_preload_i (arr_preload_w),
        .cnt_o         (cnt_val_w),
        .overflow_o    (overflow_w)
    );

    //-----------------------------------------------------------------
    // Comparator - Channel 1 (example)
    //-----------------------------------------------------------------
    wire cnt_eq_cmp_start_w;
    wire cnt_gt_cmp_start_w;
    wire cnt_eq_cmp_end_w;
    wire cnt_gt_cmp_end_w;

    pwm_comparator #(
        .CMP_WIDTH (16)
    ) u_pwm_comparator_ch1 (
        .clk_psc_i          (clk_psc_i),
        .rst_n_i            (rst_n_i),
        .cnt_i              (cnt_val_w),
        .cmp_start_i        (cmp_ch1_start_w),
        .cmp_end_i          (cmp_ch1_end_w),
        .cnt_eq_cmp_start_o (cnt_eq_cmp_start_w),
        .cnt_gt_cmp_start_o (cnt_gt_cmp_start_w),
        .cnt_eq_cmp_end_o   (cnt_eq_cmp_end_w),
        .cnt_gt_cmp_end_o   (cnt_gt_cmp_end_w)
    );

    //-----------------------------------------------------------------
    // Output Compare Channel 1
    //-----------------------------------------------------------------
    wire        oc_mode_i, dtg_src_sel_i;
    wire [1:0]  oc_main_sel_i, oc_comp_sel_i;
    wire        oc_main_pol_i, oc_comp_pol_i;
    wire        oc_main_o, oc_comp_o;

    assign oc_mode_i      = cfg_reg_ch1[0];
    assign dtg_src_sel_i  = cfg_reg_ch1[1];
    assign oc_main_sel_i  = cfg_reg_ch1[3:2];
    assign oc_comp_sel_i  = cfg_reg_ch1[5:4];
    assign oc_main_pol_i  = cfg_reg_ch1[6];
    assign oc_comp_pol_i  = cfg_reg_ch1[7];




    pwm_oc #(
        .DEADTIME_WIDTH (8)
    ) u_pwm_oc_ch1 (
        .clk_psc_i           (clk_psc_i),
        .rst_n_i             (rst_n_i),
        .cmp_start_eq_i      (cnt_eq_cmp_start_w),
        .cmp_start_gt_i      (cnt_gt_cmp_start_w),
        .cmp_end_eq_i        (cnt_eq_cmp_end_w),
        .cmp_end_gt_i        (cnt_gt_cmp_end_w),
        .oc_mode_i           (oc_mode_i),
        .dtg_src_sel_i       (dtg_src_sel_i),
        .update_event_i      (overflow_w),    // use overflow as update event
        .dtg_preload_i       (dtg_ch1_w),
        .oc_main_sel_i       (oc_main_sel_i),
        .oc_comp_sel_i       (oc_comp_sel_i),
        .oc_main_pol_i       (oc_main_pol_i),
        .oc_comp_pol_i       (oc_comp_pol_i),
        .oc_main_o           (oc_main_o),
        .oc_comp_o           (oc_comp_o)
    );

    //-----------------------------------------------------------------
    // Assign final outputs (placeholder)
    //-----------------------------------------------------------------
    assign pwm_ch1_o = oc_main_o;
    assign pwm_ch2_o = oc_comp_o;

endmodule
