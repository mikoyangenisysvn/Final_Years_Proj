//=====================================================================
// Module: pwm_oc_refgen
// Description:
//   Output Compare reference generator.
//   Generates reference signals (OC_A / OC_B) based on counter-compare
//   match flags and selected mode.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx HDL Naming Convention
//=====================================================================

module pwm_oc_refgen (
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire clk_psc_i,          // Prescaled clock input
    input  wire rst_n_i,            // Active-low reset

    //-----------------------------------------------------------------
    // Compare Flags
    //-----------------------------------------------------------------
    input  wire cmp_start_eq_i,     // Counter == CMP_START
    input  wire cmp_start_gt_i,     // Counter >  CMP_START
    input  wire cmp_end_eq_i,       // Counter == CMP_END
    input  wire cmp_end_gt_i,       // Counter >  CMP_END

    //-----------------------------------------------------------------
    // Mode Control
    //-----------------------------------------------------------------
    input  wire mode_i,             // Output compare mode select

    //-----------------------------------------------------------------
    // Outputs
    //-----------------------------------------------------------------
    output reg  oc_a_ref_o,         // Reference output A
    output reg  oc_b_ref_o          // Reference output B
);

    //-----------------------------------------------------------------
    // Reference Generation Logic
    //-----------------------------------------------------------------
    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            oc_a_ref_o <= 1'b0;
            oc_b_ref_o <= 1'b0;
        end 
        else begin
            // ---------------------------------------------------------
            // Mode 1: Toggle output on compare match
            // ---------------------------------------------------------
            if (mode_i) begin
                if (cmp_start_eq_i) begin
                    oc_a_ref_o <= 1'b1;
                    oc_b_ref_o <= 1'b0;
                end 
                else if (cmp_end_eq_i) begin
                    oc_a_ref_o <= 1'b0;
                    oc_b_ref_o <= 1'b1;
                end
            end
            // ---------------------------------------------------------
            // Mode 0: Set/Clear behavior based on compare window
            // ---------------------------------------------------------
            else begin
                // Channel A reference
                if (cmp_start_eq_i)
                    oc_a_ref_o <= 1'b0;
                else if (cmp_start_gt_i)
                    oc_a_ref_o <= oc_a_ref_o; // hold
                else
                    oc_a_ref_o <= 1'b1;

                // Channel B reference
                if (cmp_end_eq_i)
                    oc_b_ref_o <= 1'b0;
                else if (cmp_end_gt_i)
                    oc_b_ref_o <= oc_b_ref_o; // hold
                else
                    oc_b_ref_o <= 1'b1;
            end
        end
    end

endmodule
