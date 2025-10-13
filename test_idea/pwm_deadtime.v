//============================================================
// Module: pwm_deadtime
// Mô tả: Chèn khoảng trễ (deadtime) giữa hai kênh PWM đảo pha
// Đầu vào: 
//   - pwm_in: tín hiệu PWM gốc (thường là đầu ra từ comparator)
//   - deadtime_en: bật/tắt tính năng deadtime
//   - deadtime_val: giá trị deadtime tính bằng chu kỳ clock
// Đầu ra:
//   - pwm_high: tín hiệu PWM trên (P)
//   - pwm_low: tín hiệu PWM dưới (N) — đảo pha, có deadtime
//============================================================
module pwm_deadtime #(
    parameter WIDTH = 16
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              pwm_in,
    input  wire              deadtime_en,
    input  wire [WIDTH-1:0]  deadtime_val,
    output reg               pwm_high,
    output reg               pwm_low
);

    // Trạng thái cũ của PWM để phát hiện cạnh
    reg pwm_in_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_in_d <= 1'b0;
        else
            pwm_in_d <= pwm_in;
    end

    // Bộ đếm deadtime
    reg [WIDTH-1:0] dt_counter;
    reg delay_active;  // cờ cho biết đang chèn trễ

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dt_counter   <= 0;
            delay_active <= 1'b0;
            pwm_high     <= 1'b0;
            pwm_low      <= 1'b0;
        end else begin
            if (!deadtime_en) begin
                // Nếu không bật deadtime → tín hiệu đảo pha trực tiếp
                pwm_high <= pwm_in;
                pwm_low  <= ~pwm_in;
                delay_active <= 1'b0;
                dt_counter   <= 0;
            end else begin
                // Có bật deadtime
                if (delay_active) begin
                    // Đang trong khoảng trễ → giảm đếm
                    if (dt_counter > 0)
                        dt_counter <= dt_counter - 1'b1;
                    else
                        delay_active <= 1'b0; // hết trễ
                end

                // Phát hiện cạnh thay đổi của PWM
                if (pwm_in != pwm_in_d && !delay_active) begin
                    delay_active <= 1'b1;
                    dt_counter   <= deadtime_val;
                    pwm_high     <= pwm_in;   // tắt cạnh trước
                    pwm_low      <= pwm_low;  // giữ nguyên trong khi trễ
                end else if (!delay_active) begin
                    // Sau khi hết trễ → cập nhật mức tín hiệu bình thường
                    pwm_high <= pwm_in;
                    pwm_low  <= ~pwm_in;
                end
            end
        end
    end

endmodule
