module comparator #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] count,
    input  wire [WIDTH-1:0] ccr,
    output wire pwm_out
);

    assign pwm_out = (count < ccr) ? 1'b1 : 1'b0;

endmodule
