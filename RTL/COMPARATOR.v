module comparator #(
    parameter WIDTH = 16   // độ rộng counter và duty
)(
    input  wire [WIDTH-1:0] CCR, // giá trị counter
    input  wire [WIDTH-1:0] CCR_COMPARE,          // duty cycle
    input  wire [WIDTH-1:0] period,        // period (để check full duty)
    input  wire             enable,        // enable
    output wire             pwm_out        // tín hiệu PWM
);

   reg pwm_r;

always @* begin
    case (1'b1)
        (!enable):         pwm_r = 1'b0;
        (CCR_COMPARE == 0):       pwm_r = 1'b0;
        (CCR_COMPARE >= period):  pwm_r = 1'b1;
        (CCR < CCR_COMPARE): pwm_r = 1'b1;
        default:           pwm_r = 1'b0;
    endcase
end

assign pwm_out = pwm_r;


endmodule


