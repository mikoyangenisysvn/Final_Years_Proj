module pwm_top #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 CEN,         // Counter Enable
    input  wire [WIDTH-1:0]     ARR,         // Auto-Reload Register (Period)
    input  wire [WIDTH-1:0]     CCR1,        // Capture/Compare Register (Duty)
    input  wire [WIDTH-1:0]     PSC,         // Prescaler
    output reg                  PWM_OUT      // PWM Output
);

    // Prescaler
    reg [WIDTH-1:0] psc_cnt;
    reg             tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psc_cnt <= 0;
            tick    <= 0;
        end else if (CEN) begin
            if (psc_cnt >= PSC) begin
                psc_cnt <= 0;
                tick    <= 1;   // Tạo tick cho CNT
            end else begin
                psc_cnt <= psc_cnt + 1;
                tick    <= 0;
            end
        end else begin
            tick <= 0;
        end
    end

    // Counter (CNT)
    reg [WIDTH-1:0] CNT;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            CNT <= 0;
        end else if (CEN && tick) begin
            if (CNT >= ARR)
                CNT <= 0;
            else
                CNT <= CNT + 1;
        end
    end

    // PWM Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PWM_OUT <= 1'b0;
        end else if (CEN) begin
            if (CCR1 == 0)
                PWM_OUT <= 1'b0;               // Duty = 0% → luôn tắt
            else if (CCR1 >= ARR)
                PWM_OUT <= 1'b1;               // Duty = full → luôn bật
            else if (CNT < CCR1)
                PWM_OUT <= 1'b1;               // So sánh CNT với CCR1
            else
                PWM_OUT <= 1'b0;
        end else begin
            PWM_OUT <= 1'b0;                   // Disable → tắt PWM
        end
    end

endmodule
