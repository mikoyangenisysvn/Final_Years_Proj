module comparator #(
    parameter CHANNELS = 4,      // số kênh PWM
    parameter WIDTH    = 16      // độ rộng counter và duty
)(
    input  wire [WIDTH-1:0]                counter_value,   // giá trị bộ đếm
    input  wire [CHANNELS-1:0][WIDTH-1:0] duty,            // duty cho từng kênh
    input  wire [CHANNELS-1:0]             enable,          // enable cho từng kênh
    output wire [CHANNELS-1:0]             pwm_out          // output cho từng kênh
);

    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin : cmp_gen
            assign pwm_out[i] = (enable[i]) ? 
                                ((counter_value < duty[i]) ? 1'b1 : 1'b0) 
                                : 1'b0;
        end
    endgenerate

endmodule
