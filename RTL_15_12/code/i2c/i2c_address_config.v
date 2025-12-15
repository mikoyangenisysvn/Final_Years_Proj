//=====================================================================
// Module: i2c_address_config
// Description:
//   Capture I2C 7-bit slave address after a small delay
//   following reset. Address is based on 3 input configuration pins.
//
// Naming Style:
//   - Follows ARM / Intel / Xilinx HDL naming convention
//   - *_i : input
//   - *_o : output
//   - *_q : registered signals
//
// Author: [Your Name]
//=====================================================================

module i2c_address_config #(
    parameter integer DELAY_CYCLES = 3   // Number of clock cycles to wait after reset
)(
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire        clk_i,             // System clock
    input  wire        rst_n_i,           // Active-low reset

    //-----------------------------------------------------------------
    // Configuration pins
    //-----------------------------------------------------------------
    input  wire [2:0]  address_set_pin_i, // DIP / jumper config pins

    //-----------------------------------------------------------------
    // Output I2C address
    //-----------------------------------------------------------------
    output reg  [6:0]  slave_address_o    // 7-bit I2C slave address
);

    //-----------------------------------------------------------------
    // Internal registers
    //-----------------------------------------------------------------
    reg [3:0] delay_cnt_q;     // Counter to reach DELAY_CYCLES
    reg       addr_latched_q;  // Indicates address already captured

    //-----------------------------------------------------------------
    // Sequential Logic
    //-----------------------------------------------------------------
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            delay_cnt_q      <= 4'd0;
            addr_latched_q   <= 1'b0;
            slave_address_o  <= 7'd0;
        end 
        else begin
            if (!addr_latched_q) begin
                if (delay_cnt_q < DELAY_CYCLES) begin
                    delay_cnt_q <= delay_cnt_q + 1'b1;
                end 
                else begin
                    // After DELAY_CYCLES clock pulses, latch address
                    slave_address_o <= {4'b1010, address_set_pin_i};
                    addr_latched_q  <= 1'b1;
                end
            end
        end
    end

endmodule
