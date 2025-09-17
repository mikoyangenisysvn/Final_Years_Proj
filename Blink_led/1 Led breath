module pwm_led_breath (
    input  wire clk,        // clock FPGA (27 MHz Tang Nano 9K)
    output reg  led_out     // LED output (LED1 - PIN10)
);

    // ======================
    // 1. Prescaler (chia clock)
    // ======================
    reg [15:0] prescaler;
    reg        pwm_clk;

    always @(posedge clk) begin
        if (prescaler == 16'd50000) begin   // ~270 Hz
            prescaler <= 0;
            pwm_clk   <= ~pwm_clk;
        end else begin
            prescaler <= prescaler + 1;
        end
    end

    // ======================
    // 2. PWM Counter
    // ======================
    reg [15:0] counter;
    always @(posedge pwm_clk) begin
        counter <= counter + 1;
    end

    // ======================
    // 3. Duty Register (tăng/giảm tự động)
    // ======================
    reg [15:0] duty = 0;
    reg dir = 1'b1;  // 1 = tăng, 0 = giảm

    reg [19:0] slow_cnt;  // bộ đếm chậm để điều chỉnh tốc độ breathing

    always @(posedge clk) begin
        slow_cnt <= slow_cnt + 1;
        if (slow_cnt == 20'd500000) begin   // điều chỉnh tốc độ breathing (~20Hz update)
            slow_cnt <= 0;
            if (dir) begin
                if (duty < 16'd65535 - 200)
                    duty <= duty + 200;
                else
                    dir <= 1'b0; // đổi hướng sang giảm
            end else begin
                if (duty > 200)
                    duty <= duty - 200;
                else
                    dir <= 1'b1; // đổi hướng sang tăng
            end
        end
    end

    // ======================
    // 4. Comparator PWM
    // ======================
    always @(posedge pwm_clk) begin
        if (counter < duty)
            led_out <= 1;
        else
            led_out <= 0;
    end

endmodule
