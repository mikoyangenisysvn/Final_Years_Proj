module prescaler_tick #(
    parameter WIDTH = 16,
    parameter DIV   = 1000
)(
    input  wire clk_in,
    input  wire rst,
    input  wire en,
    output reg  tick   // tick = 1 trong 1 chu kỳ clock_in
);

    reg [WIDTH-1:0] cnt;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            cnt  <= 0;
            tick <= 0;
        end 
        else if (en) begin
            if (cnt == DIV-1) begin
                cnt  <= 0;
                tick <= 1;
            end
            else begin
                cnt  <= cnt + 1;
                tick <= 0;
            end
        end
        else begin
            tick <= 0;
        end
    end
endmodule
