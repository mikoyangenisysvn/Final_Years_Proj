module pwm_led_wave (
    input  wire clk,        // clock FPGA (27 MHz Tang Nano 9K)
    output reg  led1,       // LED1 - PIN10
    output reg  led2,       // LED2 - PIN11
    output reg  led3,       // LED3 - PIN13
    output reg  led4,       // LED4 - PIN14
    output reg  led5,       // LED5 - PIN15
    output reg  led6        // LED6 - PIN16
);

    // ======================
    // 1. Prescaler (chia clock PWM)
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
    // 3. Duty Registers (6 LED, lệch pha)
    // ======================
    reg [15:0] duty [0:5];
    reg dir = 1'b1;  // 1 = tăng, 0 = giảm

    reg [19:0] slow_cnt;

    integer i;

    initial begin
        // khởi tạo duty lệch nhau
        duty[0] = 16'd0;
        duty[1] = 16'd10000;
        duty[2] = 16'd20000;
        duty[3] = 16'd30000;
        duty[4] = 16'd40000;
        duty[5] = 16'd50000;
    end

    always @(posedge clk) begin
        slow_cnt <= slow_cnt + 1;
        if (slow_cnt == 20'd500000) begin   // điều chỉnh tốc độ breathing
            slow_cnt <= 0;
            for (i = 0; i < 6; i = i + 1) begin
                if (dir) begin
                    if (duty[i] < 16'd65535 - 200)
                        duty[i] <= duty[i] + 200;
                end else begin
                    if (duty[i] > 200)
                        duty[i] <= duty[i] - 200;
                end
            end

            // đổi hướng khi LED0 chạm biên
            if (duty[0] >= 16'd65535 - 200)
                dir <= 1'b0;
            else if (duty[0] <= 200)
                dir <= 1'b1;
        end
    end

    // ======================
    // 4. Comparator PWM cho từng LED
    // ======================
    always @(posedge pwm_clk) begin
        led1 <= (counter < duty[0]);
        led2 <= (counter < duty[1]);
        led3 <= (counter < duty[2]);
        led4 <= (counter < duty[3]);
        led5 <= (counter < duty[4]);
        led6 <= (counter < duty[5]);
    end

endmodule
