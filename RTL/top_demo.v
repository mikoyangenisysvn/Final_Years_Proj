// top_demo.v
// Demo top để nạp lên Tang Nano 9K.
// - Sinh một chuỗi ghi APB (mỗi ghi 1 cycle) để khởi tạo register:
//    0x0  : control (bit0 = en, bit1 = mode)
//    0x4  : period (ARR)
//    0x8  : duty1 (CCR1)
//    0xC  : duty2 (CCR2)
//    0xE  : prescaler_div
// - Sau khi ghi xong, APB idle.
// - Map PWM1_OUT -> led_out để quan sát.

module top_demo (
    input  wire clk,      // board clock (ví dụ 27 MHz)
    input  wire rst_n,    // active-low reset (nút reset trên board)
    output wire pwm1_led, // nối tới LED trên board để quan sát PWM1
    output wire pwm2_pin  // optional second PWM output pin
);

    parameter WIDTH = 16;
    // số chu kỳ delay giữa hai write (tùy chỉnh cho board)
    localparam integer DELAY_MAX = 24'd2_500_000;

    // ---------- APB control signals (generated here) ----------
    reg [2:0] step;
    reg [23:0] delay_cnt;

    // Apb signals driven combinationally from step & delay counter
    wire apb_fire = (delay_cnt == DELAY_MAX); // một xung khi delay_cnt đạt ngưỡng

    reg psel;
    reg penable;
    reg pwrite;
    reg [3:0] paddr;
    reg [WIDTH-1:0] pwdata;

    // PWM outputs from pwm_top
    wire [WIDTH-1:0] prdata;
    wire pready;
    wire PWM1_OUT;
    wire PWM2_OUT;

    // ---------- simple sequencer ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step <= 3'd0;
            delay_cnt <= 24'd0;
        end else begin
            if (delay_cnt >= DELAY_MAX) begin
                delay_cnt <= 24'd0;
                if (step < 3'd5) step <= step + 1'b1;
            end else begin
                delay_cnt <= delay_cnt + 1'b1;
            end
        end
    end

    // Generate one-cycle APB assertions when apb_fire == 1
    always @(*) begin
        // default idle
        psel   = 1'b0;
        penable= 1'b0;
        pwrite = 1'b0;
        paddr  = 4'h0;
        pwdata = {WIDTH{1'b0}};

        if (apb_fire) begin
            case (step)
                3'd0: begin
                    // control: en=1, mode=1 (center-aligned)
                    psel    = 1'b1;
                    penable = 1'b1;
                    pwrite  = 1'b1;
                    paddr   = 4'h0;
                    pwdata  = 16'h0003; // bit0=en=1, bit1=mode=1
                end
                3'd1: begin
                    // period (ARR)
                    psel    = 1'b1; penable = 1'b1; pwrite = 1'b1;
                    paddr   = 4'h4;
                    pwdata  = 16'd1000; // ARR = 1000
                end
                3'd2: begin
                    // duty1 (CCR1) smaller
                    psel    = 1'b1; penable = 1'b1; pwrite = 1'b1;
                    paddr   = 4'h8;
                    pwdata  = 16'd250; // 25% of 1000
                end
                3'd3: begin
                    // duty2 (CCR2) larger
                    psel    = 1'b1; penable = 1'b1; pwrite = 1'b1;
                    paddr   = 4'hC;
                    pwdata  = 16'd750; // 75% of 1000
                end
                3'd4: begin
                    // prescaler_div (slows the tick)
                    psel    = 1'b1; penable = 1'b1; pwrite = 1'b1;
                    paddr   = 4'hE;
                    pwdata  = 16'd2000; // prescaler
                end
                default: begin
                    // after sequence done remain idle
                    psel = 1'b0; penable = 1'b0; pwrite = 1'b0;
                end
            endcase
        end
    end

    // Instantiate pwm_top (APB driven)
    pwm_top #(.WIDTH(WIDTH)) u_pwm_top (
        .clk    (clk),
        .rst_n  (rst_n),
        .psel   (psel),
        .penable(penable),
        .pwrite (pwrite),
        .paddr  (paddr),
        .pwdata (pwdata),
        .prdata (prdata),
        .pready (pready),
        .PWM1_OUT(PWM1_OUT),
        .PWM2_OUT(PWM2_OUT)
    );

    // Map outputs to board pins (LED / header)
    assign pwm1_led = PWM1_OUT;
    assign pwm2_pin = PWM2_OUT;

endmodule
