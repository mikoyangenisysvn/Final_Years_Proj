module pwm_prescaler (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] div,     // giá trị chia
    output reg         tick     // xung clock enable
);

    reg [15:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 16'd0;
            tick  <= 1'b0;
        end 
        else if (div == 0) begin
            tick  <= 1'b1;  // luôn cho phép nếu chia = 0
        end
        else begin
            if (count >= div) begin
                count <= 16'd0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1;
                tick  <= 1'b0;
            end
        end
    end

endmodule
