module pwm_core #(
    parameter integer WIDTH = 16
)(
    input  wire                 clk_psc_i,
    input  wire                 rst_n_i,
    input  wire                 cnt_en_w,
    input  wire [WIDTH-1:0]     psc_preload_w,
    input  wire [WIDTH-1:0]     arr_preload_w,
    input  wire [WIDTH-1:0]     cmp_ch1_start_w,
    input  wire [WIDTH-1:0]     cmp_ch1_end_w,
    input  wire [WIDTH-1:0]     cmp_ch2_start_w,
    input  wire [WIDTH-1:0]     cmp_ch2_end_w,
    input  wire [7:0]           dtg_ch1_w,
    input  wire [7:0]           dtg_ch2_w,
    input  wire [WIDTH-1:0]     cfg_reg_ch1,
    input  wire [WIDTH-1:0]     cfg_reg_ch2,
    output wire                 pwm_ch1_a_o,
    output wire                 pwm_ch1_b_o,
    output wire                 pwm_ch2_a_o,
    output wire                 pwm_ch2_b_o
);

    wire ck_cnt_w;
    wire [WIDTH-1:0] cnt_val_w;
    wire overflow_w;

    pwm_prescaler #(
        .PSC_WIDTH(WIDTH)
    ) u_pwm_prescaler (
        .clk_psc_i(clk_psc_i),
        .rst_n_i(rst_n_i),
        .cen_i(cnt_en_w),
        .psc_preload_i(psc_preload_w),
        .ck_cnt_o(ck_cnt_w)
    );

    pwm_counter #(
        .CNT_WIDTH(WIDTH)
    ) u_pwm_counter (
        .clk_psc_i(clk_psc_i),
        .rst_n_i(rst_n_i),
        .ck_cnt_i(ck_cnt_w),
        .cnt_en_i(cnt_en_w),
        .arr_preload_i(arr_preload_w),
        .cnt_o(cnt_val_w),
        .overflow_o(overflow_w)
    );

    wire cnt_eq_cmp_ch1_start_w;
    wire cnt_gt_cmp_ch1_start_w;
    wire cnt_eq_cmp_ch1_end_w;
    wire cnt_gt_cmp_ch1_end_w;

    pwm_comparator #(.WIDTH(WIDTH)) u_pwm_comparator_ch1 (
        .clk_psc_i(clk_psc_i),
        .rst_n_i(rst_n_i),
        .update_event_i(overflow_w),
        .cnt_i(cnt_val_w),
        .cmp_start_i(cmp_ch1_start_w),
        .cmp_end_i(cmp_ch1_end_w),
        .cnt_eq_cmp_start_o(cnt_eq_cmp_ch1_start_w),
        .cnt_gt_cmp_start_o(cnt_gt_cmp_ch1_start_w),
        .cnt_eq_cmp_end_o(cnt_eq_cmp_ch1_end_w),
        .cnt_gt_cmp_end_o(cnt_gt_cmp_ch1_end_w)
    );

    wire oc_main_ch1_o;
    wire oc_comp_ch1_o;

    pwm_oc #(.DEADTIME_WIDTH(8)) u_pwm_oc_ch1 (
        .clk_psc_i(clk_psc_i),
        .rst_n_i(rst_n_i),
        .cmp_start_eq_i(cnt_eq_cmp_ch1_start_w),
        .cmp_start_gt_i(cnt_gt_cmp_ch1_start_w),
        .cmp_end_eq_i(cnt_eq_cmp_ch1_end_w),
        .cmp_end_gt_i(cnt_gt_cmp_ch1_end_w),
        .oc_mode_i(cfg_reg_ch1[0]),
        .dtg_src_sel_i(cfg_reg_ch1[1]),
        .update_event_i(overflow_w),
        .dtg_preload_i(dtg_ch1_w),
        .oc_main_sel_i(cfg_reg_ch1[3:2]),
        .oc_comp_sel_i(cfg_reg_ch1[5:4]),
        .oc_main_pol_i(cfg_reg_ch1[6]),
        .oc_comp_pol_i(cfg_reg_ch1[7]),
        .oc_main_o(oc_main_ch1_o),
        .oc_comp_o(oc_comp_ch1_o)
    );

    assign pwm_ch1_a_o = oc_main_ch1_o;
    assign pwm_ch1_b_o = oc_comp_ch1_o;

    wire cnt_eq_cmp_ch2_start_w;
    wire cnt_gt_cmp_ch2_start_w;
    wire cnt_eq_cmp_ch2_end_w;
    wire cnt_gt_cmp_ch2_end_w;

    pwm_comparator #(.WIDTH(16)) u_pwm_comparator_ch2 (
        .clk_psc_i(clk_psc_i),
        .rst_n_i(rst_n_i),
        .update_event_i(overflow_w),
        .cnt_i(cnt_val_w),
        .cmp_start_i(cmp_ch2_start_w),
        .cmp_end_i(cmp_ch2_end_w),
        .cnt_eq_cmp_start_o(cnt_eq_cmp_ch2_start_w),
        .cnt_gt_cmp_start_o(cnt_gt_cmp_ch2_start_w),
        .cnt_eq_cmp_end_o(cnt_eq_cmp_ch2_end_w),
        .cnt_gt_cmp_end_o(cnt_gt_cmp_ch2_end_w)
    );

    wire oc_main_ch2_o;
    wire oc_comp_ch2_o;

    pwm_oc #(.DEADTIME_WIDTH(8)) u_pwm_oc_ch2 (
        .clk_psc_i(clk_psc_i),
        .rst_n_i(rst_n_i),
        .cmp_start_eq_i(cnt_eq_cmp_ch2_start_w),
        .cmp_start_gt_i(cnt_gt_cmp_ch2_start_w),
        .cmp_end_eq_i(cnt_eq_cmp_ch2_end_w),
        .cmp_end_gt_i(cnt_gt_cmp_ch2_end_w),
        .oc_mode_i(cfg_reg_ch2[0]),
        .dtg_src_sel_i(cfg_reg_ch2[1]),
        .update_event_i(overflow_w),
        .dtg_preload_i(dtg_ch2_w),
        .oc_main_sel_i(cfg_reg_ch2[3:2]),
        .oc_comp_sel_i(cfg_reg_ch2[5:4]),
        .oc_main_pol_i(cfg_reg_ch2[6]),
        .oc_comp_pol_i(cfg_reg_ch2[7]),
        .oc_main_o(oc_main_ch2_o),
        .oc_comp_o(oc_comp_ch2_o)
    );

    assign pwm_ch2_a_o = oc_main_ch2_o;
    assign pwm_ch2_b_o = oc_comp_ch2_o;

endmodule
