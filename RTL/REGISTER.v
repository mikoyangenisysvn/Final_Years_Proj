module register (
    input  wire        clk,
    input  wire        resetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,

    // output to other modules
    output reg  [15:0] duty_cycle,
    output reg  [15:0] period
);

    // Register map
    // 0x00 : DUTY_CYCLE
    // 0x04 : PERIOD
    // 0x08 : RESERVED (có thể giữ cho control nếu muốn)
    // 0x0C : RESERVED (status/intr nếu cần)

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            duty_cycle <= 16'd0;
            period     <= 16'd65535; // mặc định max 16-bit
        end else if (psel && penable && pwrite) begin
            case (paddr[7:0])
                8'h00: duty_cycle <= pwdata[15:0];
                8'h04: period     <= pwdata[15:0];
                default: ;
            endcase
        end
    end

    always @(*) begin
        case (paddr[7:0])
            8'h00: prdata = {16'd0, duty_cycle};
            8'h04: prdata = {16'd0, period};
            default: prdata = 32'd0;
        endcase
    end

endmodule
