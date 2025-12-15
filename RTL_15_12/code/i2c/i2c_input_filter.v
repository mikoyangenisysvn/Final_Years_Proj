//=====================================================================
// Module: i2c_input_filter
// Description:
//   Simple digital filter for I2C SDA & SCL lines.
//   The filter outputs change only when N consecutive samples are
//   consistently 0 or consistently 1.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx HDL Naming Convention
//=====================================================================

module i2c_input_filter #(
    localparam integer FILTER_LEN = 2     // Number of stable samples required
)(
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire clk_i,                    // System clock
    input  wire rst_n_i,                  // Active-low reset

    //-----------------------------------------------------------------
    // Raw I2C inputs
    //-----------------------------------------------------------------
    input  wire sda_i,                    // Unfiltered SDA
    input  wire scl_i,                    // Unfiltered SCL

    //-----------------------------------------------------------------
    // Filtered outputs
    //-----------------------------------------------------------------
    output reg  sda_filt_o,                    // Filtered SDA
    output reg  scl_filt_o                     // Filtered SCL
);

    //-----------------------------------------------------------------
    // Shift registers for sampling
    //-----------------------------------------------------------------
    reg [FILTER_LEN-1:0] sda_shift_q;
    reg [FILTER_LEN-1:0] scl_shift_q;

    //-----------------------------------------------------------------
    // Filtering logic
    //-----------------------------------------------------------------
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            sda_shift_q <= {FILTER_LEN{1'b0}};
            scl_shift_q <= {FILTER_LEN{1'b0}};
            sda_filt_o       <= 1'b0;
            scl_filt_o       <= 1'b0;
        end 
        else begin
            // Shift in newest samples
            sda_shift_q <= {sda_shift_q[FILTER_LEN-2:0], sda_i};
            scl_shift_q <= {scl_shift_q[FILTER_LEN-2:0], scl_i};

            // SDA filter decision
            if (&sda_shift_q)
                sda_filt_o <= 1'b1;
            else if (~|sda_shift_q)
                sda_filt_o <= 1'b0;

            // SCL filter decision
            if (&scl_shift_q)
                scl_filt_o <= 1'b1;
            else if (~|scl_shift_q)
                scl_filt_o <= 1'b0;
        end
    end

endmodule
