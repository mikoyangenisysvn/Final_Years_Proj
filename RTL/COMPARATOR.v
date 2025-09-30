module comparator #(
    parameter WIDTH = 16   // độ rộng counter và duty
)(
    input  wire [WIDTH-1:0] CCR, // giá trị counter
    input  wire [WIDTH-1:0] CCR_COMPARE,          // duty cycle
    input  wire             enable,        // enable
    output wire             pwm_out        // tín hiệu PWM
);

    // Logic so sánh đơn giản
    assign pwm_out = (enable) ? 
                     ((counter_value < duty) ? 1'b1 : 1'b0) 
                     : 1'b0;

endmodule

