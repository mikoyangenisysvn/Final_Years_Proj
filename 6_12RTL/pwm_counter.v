//=====================================================================
// Module: pwm_counter
// Description: PWM main counter module. Counts CK_CNT pulses up to ARR value.
//              Generates overflow flag when counter rolls over.
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx Vivado HDL Naming Convention
//=====================================================================

module pwm_counter #(
    parameter integer CNT_WIDTH = 16
)(
    // Clock & Reset
    input  wire                 clk_psc_i,       // Prescaler clock
    input  wire                 rst_n_i,         // Active-low reset

    // Control inputs
    input  wire                 ck_cnt_i,        // Clock enable from prescaler
    input  wire                 cnt_en_i,        // Counter enable
    input  wire [CNT_WIDTH-1:0] arr_preload_i,   // Auto-reload preload value

    // Outputs
    output reg  [CNT_WIDTH-1:0] cnt_o,           // Counter value
    output reg                  overflow_o       // Overflow flag
);

    //-----------------------------------------------------------------
    // Internal registers
    //-----------------------------------------------------------------
    reg [CNT_WIDTH-1:0] arr_shadow_reg;

    //-----------------------------------------------------------------
    // Auto-reload shadow register
    //-----------------------------------------------------------------
    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            arr_shadow_reg <= {CNT_WIDTH{1'b0}};
        end else begin
            // Reload shadow when counter disabled or overflow occurred
            if (!cnt_en_i || overflow_o)
                arr_shadow_reg <= arr_preload_i;
        end
    end

    //-----------------------------------------------------------------
    // Counter logic
    //-----------------------------------------------------------------
    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            cnt_o       <= {CNT_WIDTH{1'b0}};
            overflow_o  <= 1'b0;
        end else if (!cnt_en_i) begin
            cnt_o       <= {CNT_WIDTH{1'b0}};
            overflow_o  <= 1'b0;
        end else if (ck_cnt_i) begin
            if (cnt_o >= arr_shadow_reg) begin
                cnt_o       <= {CNT_WIDTH{1'b0}};
                overflow_o  <= 1'b1;
            end else begin
                cnt_o       <= cnt_o + 1'b1;
                overflow_o  <= 1'b0;
            end
        end else begin
            // giữ nguyên khi ck_cnt_i = 0
            overflow_o <= 1'b0;
        end
    end

endmodule
