module apb_pwm #(
    parameter WIDTH = 16
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        psel,
    input  wire        pwrite,
    input  wire        penable,
    input  wire [11:0] paddr,
    input  wire [31:0] pwdata,
    output wire        pready,
    output reg  [31:0] prdata,

    // Kết nối ra PWM core
    output reg  [WIDTH-1:0] arr,
    output reg  [WIDTH-1:0] ccr1,
    output reg  [WIDTH-1:0] ccr2
);

    // Luôn sẵn sàng
    assign pready = 1'b1;

    // Địa chỉ ánh xạ (ví dụ)
    localparam ADDR_ARR  = 12'h000;
    localparam ADDR_CCR1 = 12'h004;
    localparam ADDR_CCR2 = 12'h008;

    // Ghi thanh ghi
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arr  <= 0;
            ccr1 <= 0;
            ccr2 <= 0;
        end else if (psel & penable & pwrite) begin
            case (paddr)
                ADDR_ARR:  arr  <= pwdata[WIDTH-1:0];
                ADDR_CCR1: ccr1 <= pwdata[WIDTH-1:0];
                ADDR_CCR2: ccr2 <= pwdata[WIDTH-1:0];
            endcase
        end
    end

    // Đọc thanh ghi
    always @(*) begin
        if (psel & !pwrite) begin
            case (paddr)
                ADDR_ARR:  prdata = {{(32-WIDTH){1'b0}}, arr};
                ADDR_CCR1: prdata = {{(32-WIDTH){1'b0}}, ccr1};
                ADDR_CCR2: prdata = {{(32-WIDTH){1'b0}}, ccr2};
                default:   prdata = 32'h0;
            endcase
        end else begin
            prdata = 32'h0;
        end
    end

endmodule
