// Code your design here
module comparator #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] CNT, 
    input  wire [WIDTH-1:0] CCR,
    input  wire [WIDTH-1:0] CCR_ON, 
    input  wire [WIDTH-1:0] PERIOD,
    input  wire             ENABLE,
    output reg              PWM_OUT
);

    always @(*) begin
        if (!ENABLE)
            PWM_OUT = 1'b0;
        else if (CCR == 0)
            PWM_OUT = 1'b0;
        else if (CCR >= PERIOD)
            PWM_OUT = 1'b1;
        else if (CNT < CCR && CNT > CCR_ON)
            PWM_OUT = 1'b1;
        else
            PWM_OUT = 1'b0;
    end
endmodule
