module counter (
    input  wire        clk,
    input  wire        resetn,
    input  wire [15:0] period,
    output reg  [15:0] count
);

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            count <= 16'd0;
        end else begin
            if (count >= period)
                count <= 16'd0;
            else
                count <= count + 1'b1;
        end
    end

endmodule
