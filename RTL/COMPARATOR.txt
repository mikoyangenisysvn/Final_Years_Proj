module comparator (
    input  wire [15:0] counter,
    input  wire [15:0] duty_cycle,
    output reg         pwm_out
);

    always @(*) begin
        if (counter < duty_cycle)
            pwm_out = 1;
        else
            pwm_out = 0;
    end

endmodule
