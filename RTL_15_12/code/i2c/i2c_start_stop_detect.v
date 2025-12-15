//=====================================================================
// Module: i2c_start_stop_detect
// Description:
//   Detects I2C START and STOP conditions.
//   Also generates SCL falling-edge detect signal.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx HDL Naming Convention
//=====================================================================

module i2c_start_stop_detect (
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire clk_i,             // System clock
    input  wire rst_n_i,           // Active-low reset

    //-----------------------------------------------------------------
    // I2C inputs (filtered externally)
    //-----------------------------------------------------------------
    input  wire sda_i,             // SDA input
    input  wire scl_i,             // SCL input

    //-----------------------------------------------------------------
    // Detected conditions
    //-----------------------------------------------------------------
    output reg  start_detected_o,  // START condition detected
    output reg  stop_detected_o,   // STOP condition detected
    output wire edge_detect_o      // SCL falling edge detect
);

    //-----------------------------------------------------------------
    // Synchronizers
    //-----------------------------------------------------------------
    reg [1:0] sda_sync_q;
    reg [1:0] scl_sync_q;

    // SCL falling edge detection (1 → 0)
    assign edge_detect_o = (~scl_sync_q[1] &  scl_sync_q[0]);

    //-----------------------------------------------------------------
    // Input Synchronization
    //-----------------------------------------------------------------
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            sda_sync_q <= 2'b11;
            scl_sync_q <= 2'b11;
        end 
        else begin
            sda_sync_q <= {sda_sync_q[0], sda_i};
            scl_sync_q <= {scl_sync_q[0], scl_i};
        end
    end

    //-----------------------------------------------------------------
    // START/STOP detection logic
    //-----------------------------------------------------------------
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            start_detected_o <= 1'b0;
            stop_detected_o  <= 1'b0;
        end 
        else begin
            // Default: no detection
            start_detected_o <= 1'b0;
            stop_detected_o  <= 1'b0;

            // START: SDA falling edge while SCL = 1
            if (sda_sync_q[1] == 1'b1 &&
                sda_sync_q[0] == 1'b0 &&
                scl_sync_q[0] == 1'b1)
                start_detected_o <= 1'b1;

            // STOP: SDA rising edge while SCL = 1
            if (sda_sync_q[1] == 1'b0 &&
                sda_sync_q[0] == 1'b1 &&
                scl_sync_q[0] == 1'b1)
                stop_detected_o <= 1'b1;
        end
    end

endmodule
