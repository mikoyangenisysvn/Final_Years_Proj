//=====================================================================
// Module: pwm_oc_channel
// Description: PWM Output Compare Channel with Deadtime & Polarity Control
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx Vivado IP Naming Convention
//=====================================================================
module pwm_oc #(
    parameter integer DEADTIME_WIDTH = 8
)(
    // Clock & Reset
    input  wire clk_psc_i,           // Prescaled clock input
    input  wire rst_n_i,             // Active-low reset

    // Compare input signals
    input  wire cmp_start_eq_i,      // Counter == compare_start
    input  wire cmp_start_gt_i,      // Counter >  compare_start
    input  wire cmp_end_eq_i,        // Counter == compare_end
    input  wire cmp_end_gt_i,        // Counter >  compare_end

    // Mode & control
    input  wire oc_mode_i,           // Output compare mode
    input  wire dtg_src_sel_i,       // Deadtime source select
    input  wire update_event_i,      // Update event signal

    // Deadtime configuration
    input  wire [DEADTIME_WIDTH-1:0] dtg_preload_i, // Deadtime preload value

    // Output select & polarity
    input  wire [1:0] oc_main_sel_i, // Main output source select
    input  wire [1:0] oc_comp_sel_i, // Complementary output select
    input  wire oc_main_pol_i,       // Main output polarity
    input  wire oc_comp_pol_i,       // Complementary output polarity

    // Final outputs
    output wire oc_main_o,           // Main PWM output
    output wire oc_comp_o            // Complementary PWM output
);

    //-----------------------------------------------------------------
    // Internal signals
    //-----------------------------------------------------------------
    wire oc_ref_a_int;
    wire oc_ref_b_int;
    wire dtg_input_int;
    wire oc_main_dt_int;
    wire oc_comp_dt_int;

    //-----------------------------------------------------------------
    // Output compare logic
    //-----------------------------------------------------------------
    pwm_oc_refgen u_oc_ref (
        .clk_psc_i       (clk_psc_i),
        .rst_n_i         (rst_n_i),
        .cmp_start_eq_i  (cmp_start_eq_i),
        .cmp_start_gt_i  (cmp_start_gt_i),
        .cmp_end_eq_i    (cmp_end_eq_i),
        .cmp_end_gt_i    (cmp_end_gt_i),
        .mode_i          (oc_mode_i),
        .oc_a_ref_o      (oc_ref_a_int),
        .oc_b_ref_o      (oc_ref_b_int)
    );

    //-----------------------------------------------------------------
    // Deadtime input selection
    //-----------------------------------------------------------------
    assign dtg_input_int = (dtg_src_sel_i) ? oc_ref_a_int : oc_ref_b_int;

    //-----------------------------------------------------------------
    // Deadtime generator
    //-----------------------------------------------------------------
    pwm_oc_deadtime #(
        .WIDTH(DEADTIME_WIDTH)
    ) u_deadtime (
        .clk_psc_i    (clk_psc_i),
        .rst_n_i      (rst_n_i),
        .update_event_i(update_event_i),
        .pwm_in_i     (dtg_input_int),
        .dtg_preload_i(dtg_preload_i),
        .pwm_high_o   (oc_main_dt_int),
        .pwm_low_o    (oc_comp_dt_int)
    );

    //-----------------------------------------------------------------
    // Output selection (mux logic)
    //-----------------------------------------------------------------
    reg oc_main_mux_int;
    reg oc_comp_mux_int;

    always @(*) begin
        case (oc_main_sel_i)
            2'b00: oc_main_mux_int = 1'b0;
            2'b01: oc_main_mux_int = oc_ref_a_int;
            2'b10: oc_main_mux_int = dtg_input_int;
            2'b11: oc_main_mux_int = oc_main_dt_int;
            default: oc_main_mux_int = 1'b0;
        endcase

        case (oc_comp_sel_i)
            2'b00: oc_comp_mux_int = 1'b0;
            2'b01: oc_comp_mux_int = oc_ref_b_int;
            2'b10: oc_comp_mux_int = dtg_input_int;
            2'b11: oc_comp_mux_int = oc_comp_dt_int;
            default: oc_comp_mux_int = 1'b0;
        endcase
    end

    //-----------------------------------------------------------------
    // Output polarity control
    //-----------------------------------------------------------------
    assign oc_main_o = (oc_main_pol_i) ? ~oc_main_mux_int : oc_main_mux_int;
    assign oc_comp_o = (oc_comp_pol_i) ? ~oc_comp_mux_int : oc_comp_mux_int;

endmodule
