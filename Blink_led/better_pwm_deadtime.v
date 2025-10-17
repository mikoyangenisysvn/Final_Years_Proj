//============================================================
// Phiên bản sửa rõ deadtime (xem được delay rõ trên Quartus)
//============================================================
module thuBai #(
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              pwm_in,
    //input  wire              deadtime_en,
    input  wire [WIDTH-1:0]  deadtime_val,
    output wire               pwm_high,
    output wire               pwm_low
);
reg clk_delay;
reg [WIDTH-1:0] counter;
 always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter <= 0;
		clk_delay <= 0;end
	else begin
	if(counter == deadtime_val - 1) begin
		counter <= 8'b00000000;
		clk_delay <= 1'b1;end	
	else begin
		clk_delay <= 0;
		counter = counter + 1;
		end
	end
end

reg Q;

always @(posedge clk_delay or negedge rst_n) begin
	if( !rst_n) begin
		Q <= 0;end
	else begin
		 Q <= pwm_in;end
		end
assign pwm_high = pwm_in & Q;
assign pwm_low  = ~(pwm_in | Q);


endmodule
