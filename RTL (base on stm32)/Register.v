module Register #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] arr_in,
    input  wire [WIDTH-1:0] ccr_in,
    output reg  [WIDTH-1:0] arr,
    output reg  [WIDTH-1:0] ccr
);

    always @(*) begin
        arr = arr_in;
        ccr = ccr_in;
    end

endmodule
