module pwm_counter #(
    parameter WIDTH = 16
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              tick,       // clock enable
    input  wire              PWM_EN,
    input  wire              mode,       // 0: up, 1: up-down
    input  wire [WIDTH-1:0]  ARR,        // chu kỳ
    output reg  [WIDTH-1:0]  CNT         // giá trị counter
);

    reg dir; // hướng đếm (0: up, 1: down)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            CNT <= 0;
            dir <= 0;
        end
        else if (!PWM_EN) begin
            CNT <= 0;
            dir <= 0;
        end
        else if (tick) begin
            if (mode == 1'b0) begin
                // -------- Up Mode --------
                if (CNT >= ARR)
                    CNT <= 0;
                else
                    CNT <= CNT + 1;
            end
            else begin
                // -------- Up-Down Mode --------
                if (dir == 1'b0) begin
                    if (CNT >= ARR) begin
                        dir <= 1'b1;
                        CNT <= CNT - 1;
                    end else
                        CNT <= CNT + 1;
                end
                else begin
                    if (CNT == 0) begin
                        dir <= 1'b0;
                        CNT <= CNT + 1;
                    end else
                        CNT <= CNT - 1;
                end
            end
        end
    end

endmodule
