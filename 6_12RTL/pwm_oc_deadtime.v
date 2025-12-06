//=====================================================================
// Module: pwm_deadtime
// Description:
//   Deadtime insertion logic for PWM output stage.
//   Delays complementary output transitions to prevent shoot-through.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx HDL Naming Convention
//=====================================================================

module pwm_oc_deadtime #(
    parameter integer WIDTH = 8
)(
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire              clk_psc_i,       // Prescaled clock input
    input  wire              rst_n_i,         // Active-low reset

    //-----------------------------------------------------------------
    // Control & Config
    //-----------------------------------------------------------------
    input  wire              update_event_i,  // Update event (register update)
    input  wire              pwm_in_i,        // Raw PWM signal
    input  wire [WIDTH-1:0]  dtg_preload_i,   // Deadtime preload value

    //-----------------------------------------------------------------
    // Outputs
    //-----------------------------------------------------------------
    output wire              pwm_high_o,      // PWM main output (delayed)
    output wire              pwm_low_o        // PWM complementary output (delayed)
);

    //-----------------------------------------------------------------
    // Deadtime shadow register (updated on update_event_i)
    //-----------------------------------------------------------------
    reg [WIDTH-1:0] dtg_shadow_r;

    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i)
            dtg_shadow_r <= {WIDTH{1'b0}};
        else if (update_event_i)
            dtg_shadow_r <= dtg_preload_i;
    end

    //-----------------------------------------------------------------
    // Edge delay counter & synchronizer
    //-----------------------------------------------------------------
    reg [WIDTH-1:0] dt_counter_r;
    reg              pwm_in_dly_r;

    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            dt_counter_r <= {WIDTH{1'b0}};
            pwm_in_dly_r <= 1'b0;
        end 
        else begin
            if (pwm_in_dly_r != pwm_in_i) begin
                // Start counting delay when edge is detected
                if (dt_counter_r < dtg_shadow_r)
                    dt_counter_r <= dt_counter_r + 1'b1;
                else begin
                    dt_counter_r <= {WIDTH{1'b0}};
                    pwm_in_dly_r <= pwm_in_i; // Update delayed signal after deadtime expires
                end
            end 
            else begin
                dt_counter_r <= {WIDTH{1'b0}};
            end
        end
    end

    //-----------------------------------------------------------------
    // Deadtime output logic
    //-----------------------------------------------------------------
    assign pwm_high_o =  pwm_in_dly_r &  pwm_in_i;  // Active high output
    assign pwm_low_o  = ~(pwm_in_dly_r |  pwm_in_i); // Complementary output

endmodule
