module pwm_register #(
    parameter WIDTH = 16
)(
    input  wire              clk,
    input  wire              rst_n,

    // giao diện ghi/đọc
    input  wire              wr_en,
    input  wire              rd_en,
    input  wire [3:0]        addr,
    input  wire [WIDTH-1:0]  wr_data,
    output reg  [WIDTH-1:0]  rd_data,

    // output sang PWM core
    output reg               en,
    output reg               mode,
    output reg  [WIDTH-1:0]  period,
    output reg  [WIDTH-1:0]  duty1,
    output reg  [WIDTH-1:0]  duty2,
    output reg  [WIDTH-1:0]  prescaler_div,
    output reg               deadtime_en,    // <-- thêm
    output reg  [WIDTH-1:0]  deadtime_val    // <-- thêm
    // Thêm 2 output mới
    output reg [WIDTH-1:0] delay1,
    output reg [WIDTH-1:0] delay2,

);

    // ghi register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en            <= 1'b0;
            mode          <= 1'b0;
            period        <= 0;
            duty1         <= 0;
            duty2         <= 0;
            prescaler_div <= 0;
            deadtime_en   <= 1'b0;  // <-- thêm
            deadtime_val  <= 0;     // <-- thêm
            delay1 <= 0;
            delay2 <= 0;

        end 
        else if (wr_en) begin
            case (addr)
                4'h0: begin
                    en   <= wr_data[0];
                    mode <= wr_data[1];
                end
                4'h4: period        <= wr_data;   // ARR
                4'h8: duty1         <= wr_data;   // CCR1
                4'hC: duty2         <= wr_data;   // CCR2
                4'hD: deadtime_val  <= wr_data;   // <-- thêm
                4'hE: prescaler_div <= wr_data;   // chia tần số
                4'hF: deadtime_en   <= wr_data[0]; // <-- thêm
                4'h10: delay1 <= wr_data;   // DELAY1
                4'h14: delay2 <= wr_data;   // DELAY2

                default:;
            endcase
        end
    end

    // đọc register
    always @(*) begin
        if (rd_en) begin
            case (addr)
                4'h0: rd_data = { {WIDTH-2{1'b0}}, mode, en };
                4'h4: rd_data = period;
                4'h8: rd_data = duty1;
                4'hC: rd_data = duty2;
                4'hD: rd_data = deadtime_val;                       // <-- thêm
                4'hE: rd_data = prescaler_div;
                4'hF: rd_data = { {WIDTH-1{1'b0}}, deadtime_en };   // <-- thêm
                4'h10: rd_data = delay1;
                4'h14: rd_data = delay2;

                default: rd_data = 0;
            endcase
        end else begin
            rd_data = 0;
        end
    end

endmodule


endmodule
