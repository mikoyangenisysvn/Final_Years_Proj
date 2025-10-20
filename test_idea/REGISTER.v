// pwm_register.v
// Memory-mapped registers for PWM core.
// Addressing: byte addresses (lower 8 bits used in case statement).
// Map:
// 0x00 -> PERIOD (ARR)
// 0x04 -> CCR_ON
// 0x08 -> CCR (duty)
// 0x0C -> CONTROL (bit0 = ENABLE, bit1 = MODE)
// 0x0E -> PRESCALER_DIV
// 0x10 -> DEADTIME_VAL
module pwm_register #(
    parameter WIDTH = 32   // data bus width (wr_data/rd_data)
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // bus interface
    input  wire                 wr_en,
    input  wire                 rd_en,
    input  wire [15:0]          addr,      // full address from bus (byte address)
    input  wire [WIDTH-1:0]     wr_data,
    output reg  [WIDTH-1:0]     rd_data,

    // outputs to PWM core
    output reg                  en,
    output reg                  mode,
    output reg  [WIDTH-1:0]     period,
    output reg  [WIDTH-1:0]     ccr_on,
    output reg  [WIDTH-1:0]     ccr,
    output reg  [15:0]          prescaler_div,
    output reg  [15:0]          deadtime_val
);

    // synchronous write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en            <= 1'b0;
            mode          <= 1'b0;
            period        <= {WIDTH{1'b0}};
            ccr_on        <= {WIDTH{1'b0}};
            ccr           <= {WIDTH{1'b0}};
            prescaler_div <= 16'd0;
            deadtime_val  <= 16'd0;
        end else begin
            if (wr_en) begin
                case (addr[7:0])     // use low byte of address
                    8'h00: period    <= wr_data;
                    8'h04: ccr_on    <= wr_data;
                    8'h08: ccr       <= wr_data;
                    8'h0C: begin
                        en   <= wr_data[0];
                        mode <= wr_data[1];
                    end
                    8'h0E: prescaler_div <= wr_data[15:0];
                    8'h10: deadtime_val  <= wr_data[15:0];
                    default: ;
                endcase
            end
        end
    end

    // combinational read
    always @(*) begin
        rd_data = {WIDTH{1'b0}};
        if (rd_en) begin
            case (addr[7:0])
                8'h00: rd_data = period;
                8'h04: rd_data = ccr_on;
                8'h08: rd_data = ccr;
                8'h0C: rd_data = { {WIDTH-2{1'b0}}, mode, en };
                8'h0E: rd_data = { {WIDTH-16{1'b0}}, prescaler_div };
                8'h10: rd_data = { {WIDTH-16{1'b0}}, deadtime_val };
                default: rd_data = {WIDTH{1'b0}};
            endcase
        end
    end

endmodule
