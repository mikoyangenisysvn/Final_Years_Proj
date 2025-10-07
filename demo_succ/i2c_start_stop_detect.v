// Code your design here
module i2c_start_stop_detect(
    input  wire clk,         // Clock
    input  wire rst_n,       // Active-low reset
    input  wire sda_in,      // Input from SDA line
    input  wire scl_in,      // Input from SCL line
    output reg  start_detected,
    output reg  stop_detected,
    output wire edge_detect
);

   

    // Synchronizers for SDA and SCL
    reg [1:0] sda_sync, scl_sync;

    assign edge_detect = ~scl_sync[1] & scl_sync[0];

    // Synchronize inputs to clk domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_sync <= 2'b11;
            scl_sync <= 2'b11;
        end else begin
            sda_sync <= {sda_sync[0], sda_in};
            scl_sync <= {scl_sync[0], scl_in};
        end
    end

    // Start/Stop detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_detected <= 1'b0;
            stop_detected  <= 1'b0;
        end else begin
            // Default: no detection
            start_detected <= 1'b0;
            stop_detected  <= 1'b0;
            // Detect START: SDA falling edge while SCL is HIGH
            if (sda_sync[1] == 1'b1 && sda_sync[0] == 1'b0 && scl_sync[0] == 1'b1)
                start_detected <= 1'b1;

            // Detect STOP: SDA rising edge while SCL is HIGH
            if (sda_sync[1]== 1'b0 && sda_sync[0] == 1'b1 && scl_sync[0] == 1'b1)
                stop_detected <= 1'b1;
        end
    end

endmodule
