//=====================================================================
// Module: pwm_comparator
// Description: Compare current counter (CNT) value with start and end
//              compare registers. Generates equality and greater-than
//              comparison flags for PWM logic control.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx Vivado HDL Naming Convention
//=====================================================================

module pwm_comparator #(
    parameter integer WIDTH = 16
)(
    // Clock & Reset
    input  wire                     clk_psc_i,        // Prescaler clock
    input  wire                     rst_n_i,          // Active-low reset

    // Compare inputs
    input  wire [WIDTH-1:0]     cnt_i,            // Current counter value
    input  wire [WIDTH-1:0]     cmp_start_i,      // Compare start value
    input  wire [WIDTH-1:0]     cmp_end_i,        // Compare end value
    input  wire update_event_i,

    // Compare outputs
    output reg                      cnt_eq_cmp_start_o, // CNT == CMP_START
    output reg                      cnt_gt_cmp_start_o, // CNT >  CMP_START
    output reg                      cnt_eq_cmp_end_o,   // CNT == CMP_END
    output reg                      cnt_gt_cmp_end_o    // CNT >  CMP_END
);
    reg [WIDTH-1:0] cmp_start_reg, cmp_end_reg;
    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            cmp_start_reg <= 0;
            cmp_end_reg   <= 0;
        end else begin
            if(update_event_i) begin
                cmp_start_reg <= cmp_start_i;
                cmp_end_reg   <= cmp_end_i;
            end
            else begin
                cmp_start_reg <= cmp_start_reg;
                cmp_end_reg   <= cmp_end_reg;
            end
        end
    end


    //-----------------------------------------------------------------
    // Comparator logic
    //-----------------------------------------------------------------
    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            cnt_eq_cmp_start_o <= 1'b0;
            cnt_gt_cmp_start_o <= 1'b0;
            cnt_eq_cmp_end_o   <= 1'b0;
            cnt_gt_cmp_end_o   <= 1'b0;
        end else begin
            cnt_eq_cmp_start_o <= (cnt_i == cmp_start_reg);
            cnt_gt_cmp_start_o <= (cnt_i >  cmp_start_reg);
            cnt_eq_cmp_end_o   <= (cnt_i == cmp_end_reg);
            cnt_gt_cmp_end_o   <= (cnt_i >  cmp_end_reg);
        end
    end

endmodule


/*
    reg [WIDTH-1:0] CMP_START_shadow, CMP_END_shadow;

    // Lưu giá trị on/off khi overflow
    always @(negedge CLK_PSC or negedge rst_n) begin
        if (!rst_n) begin
            CMP_START_shadow  <= 0;
            CMP_END_shadow <= 0;
        end 
        else begin
            if (UEV) begin
                CMP_START_shadow  <= CMP_START;
                CMP_END_shadow    <= CMP_END;
            end
            else begin
                CMP_START_shadow  <= CMP_START_shadow;
                CMP_END_shadow    <= CMP_END_shadow;
            end
        end
    end
*/



