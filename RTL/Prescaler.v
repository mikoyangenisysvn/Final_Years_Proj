module prescaler (
    input  wire       clk,      // clock gốc (nhanh)
    input  wire       rst_n,    // reset bất đồng bộ, active low
    input  wire [15:0] div,     // hệ số chia clock (từ register)
    output reg        slow_clk  // clock sau khi chia
);

    reg [15:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count    <= 16'd0;
            slow_clk <= 1'b0;
        end
        else begin
            if (count >= div) begin
                count    <= 16'd0;
                slow_clk <= ~slow_clk;
            end
            else begin
                count <= count + 1'b1;
            end
        end
    end

endmodule
