module counter #(
    parameter WIDTH = 16
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [WIDTH-1:0]  arr,     // auto-reload value
    output reg  [WIDTH-1:0]  count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else if (count >= arr)
            count <= {WIDTH{1'b0}};
        else
            count <= count + 1'b1;
    end

endmodule
