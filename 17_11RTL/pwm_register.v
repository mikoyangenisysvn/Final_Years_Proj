//=====================================================================
// Module: pwm_register
// Description:
//   Memory-mapped register block for PWM core.
//   Provides configuration registers for prescaler, counter, compare,
//   and deadtime control for up to 4 PWM channels.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx HDL Naming Convention
//=====================================================================

module pwm_register #(
    parameter integer WIDTH = 16
)(
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire              clk_psc_i,      // Clock input
    input  wire              rst_n_i,        // Active-low reset

    //-----------------------------------------------------------------
    // Bus Interface (simplified APB-like)
    //-----------------------------------------------------------------
    input  wire              wr_en_i,        // Write enable
    input  wire              rd_en_i,        // Read enable
    input  wire [7:0]        addr_i,         // Address
    input  wire [WIDTH-1:0]  wr_data_i,      // Write data
    output reg  [WIDTH-1:0]  rd_data_o,      // Read data

    //-----------------------------------------------------------------
    // Control outputs to PWM core
    //-----------------------------------------------------------------
    output reg               cen_o,          // Counter enable
    output reg  [WIDTH-1:0]  arr_preload_o,  // Auto-reload value
    output reg  [WIDTH-1:0]  psc_preload_o,  // Prescaler preload

    // Compare start/end registers (4 channels)
    output reg  [WIDTH-1:0]  cmp_ch1_start_o,
    output reg  [WIDTH-1:0]  cmp_ch1_end_o,

    // output CH1 configuration
    output reg  [WIDTH-1:0]  cfg_reg_ch1,

    // Deadtime CH1 configuration
    output reg  [7:0]        dtg_ch1_o
);

    //-----------------------------------------------------------------
    // Register write logic
    //-----------------------------------------------------------------
    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            cen_o             <= 1'b0;
            arr_preload_o     <= {WIDTH{1'b1}}; // Default: full scale
            psc_preload_o     <= {WIDTH{1'b0}};
            cmp_ch1_start_o   <= {WIDTH{1'b0}};
            cmp_ch1_end_o     <= {WIDTH{1'b0}};
            cfg_reg_ch1       <= {WIDTH{1'b0}};
            dtg_ch1_o         <= 8'd1;
        end 
        else if (wr_en_i) begin
            case (addr_i)
                8'd0: cen_o           <= wr_data_i[0];             // Enable
                8'd1: psc_preload_o   <= wr_data_i;                // Prescaler
                8'd2: arr_preload_o   <= wr_data_i;                // Auto-reload
                8'd3: cmp_ch1_start_o <= wr_data_i;                // CH1 start compare
                8'd4: cmp_ch1_end_o   <= wr_data_i;                // CH1 end compare
                8'd5: dtg_ch1_o       <= wr_data_i[7:0];   
                8'd6: cfg_reg_ch1     <= wr_data_i;          // Deadtime
                default: ; // no operation
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Register read logic
    //-----------------------------------------------------------------
    always @(*) begin
        if (rd_en_i) begin
            case (addr_i)
                8'd0: rd_data_o = {{(WIDTH-1){1'b0}}, cen_o};
                8'd1: rd_data_o = psc_preload_o;
                8'd2: rd_data_o = arr_preload_o;
                8'd3: rd_data_o = cmp_ch1_start_o;
                8'd4: rd_data_o = cmp_ch1_end_o;
                8'd5: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch1_o};
                8'd6: rd_data_o = cfg_reg_ch1;
                default: rd_data_o = {WIDTH{1'b0}};
            endcase
        end else begin
            rd_data_o = {WIDTH{1'b0}};
        end
    end

endmodule
