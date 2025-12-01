module i2c_slave_pwm #(
    parameter I2C_ADDR = 7'h42,     // Địa chỉ slave
    parameter WIDTH = 16
)(
    input  wire        clk,
    input  wire        rst_n,

    // I2C signals
    input  wire        scl,
    inout  wire        sda,

    // Outputs to PWM register interface
    output reg  [7:0]      reg_addr_o,
    output reg  [WIDTH-1:0] reg_wdata_o,
    output reg             reg_write_o,
    input  wire [WIDTH-1:0] reg_rdata_i
);

    //-------------------------------------------------------------
    // Internal SDA handling (open-drain)
    //-------------------------------------------------------------
    reg sda_out;
    reg sda_dir;  // 0 = input, 1 = output

    assign sda = sda_dir ? sda_out : 1'bz;

    wire sda_in = sda;

    //-------------------------------------------------------------
    // I2C state machine
    //-------------------------------------------------------------
    localparam [3:0]
        ST_IDLE   = 0,
        ST_ADDR   = 1,
        ST_ADDR_ACK = 2,
        ST_REGADDR = 3,
        ST_REGADDR_ACK = 4,
        ST_WRITE  = 5,
        ST_WRITE_ACK = 6,
        ST_READ   = 7,
        ST_READ_ACK = 8;

    reg [3:0] state;

    //-------------------------------------------------------------
    // Shift registers và flags
    //-------------------------------------------------------------
    reg [7:0] shift;
    reg [2:0] bit_cnt;

    reg rw_flag;         // 0=write, 1=read
    reg [7:0] reg_addr;  // địa chỉ thanh ghi sẽ access

    //-------------------------------------------------------------
    // START và STOP detect
    //-------------------------------------------------------------
    reg sda_prev, scl_prev;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sda_prev <= 1;
            scl_prev <= 1;
        end else begin
            sda_prev <= sda_in;
            scl_prev <= scl;
        end
    end

    wire start_cond = (sda_prev == 1 && sda_in == 0 && scl == 1);
    wire stop_cond  = (sda_prev == 0 && sda_in == 1 && scl == 1);

    //-------------------------------------------------------------
    // FSM logic
    //-------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state       <= ST_IDLE;
            reg_write_o <= 0;
            sda_dir     <= 0;
            bit_cnt     <= 0;
        end
        else begin

            reg_write_o <= 0;   // default

            //-----------------------------------------------------
            // START
            //-----------------------------------------------------
            if(start_cond) begin
                state   <= ST_ADDR;
                bit_cnt <= 3'd7;
            end

            //-----------------------------------------------------
            // STOP → reset state machine
            //-----------------------------------------------------
            if(stop_cond) begin
                state <= ST_IDLE;
                sda_dir <= 0;
            end

            //-----------------------------------------------------
            // STATE MACHINE
            //-----------------------------------------------------
            case(state)

            //=========================================
            // Receive 7bit address + R/W
            //=========================================
            ST_ADDR: begin
                if(scl && !scl_prev) begin  // rising SCL
                    shift[bit_cnt] <= sda_in;
                    if(bit_cnt == 0)
                        state <= ST_ADDR_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            //=========================================
            // Address ACK
            //=========================================
            ST_ADDR_ACK: begin
                if(shift[7:1] == I2C_ADDR) begin
                    rw_flag <= shift[0];  // R/W
                    sda_dir <= 1;         // Output ACK
                    sda_out <= 0;
                end
                state <= ST_REGADDR;
                bit_cnt <= 3'd7;
                sda_dir <= 0;
            end

            //=========================================
            // Register address (master write)
            //=========================================
            ST_REGADDR: begin
                if(scl && !scl_prev) begin
                    shift[bit_cnt] <= sda_in;
                    if(bit_cnt == 0)
                        state <= ST_REGADDR_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            //=========================================
            // ACK cho register address
            //=========================================
            ST_REGADDR_ACK: begin
                reg_addr <= shift;
                sda_dir <= 1;
                sda_out <= 0;
                sda_dir <= 0;

                bit_cnt <= 3'd7;

                if(rw_flag == 0) state <= ST_WRITE;
                else             state <= ST_READ;
            end

            //=========================================
            // WRITE DATA
            //=========================================
            ST_WRITE: begin
                if(scl && !scl_prev) begin
                    shift[bit_cnt] <= sda_in;
                    if(bit_cnt == 0) begin
                        state <= ST_WRITE_ACK;
                    end else bit_cnt <= bit_cnt - 1;
                end
            end

            ST_WRITE_ACK: begin
                reg_addr_o   <= reg_addr;
                reg_wdata_o  <= shift;
                reg_write_o  <= 1;

                sda_dir <= 1;
                sda_out <= 0;    // ACK
                sda_dir <= 0;

                bit_cnt <= 3'd7;
                state <= ST_WRITE;
            end

            //=========================================
            // READ DATA
            //=========================================
            ST_READ: begin
                sda_dir <= 1;  // output
                sda_out <= reg_rdata_i[bit_cnt];

                if(!scl && scl_prev) begin // SCL falling
                    if(bit_cnt == 0) begin
                        state <= ST_READ_ACK;
                    end else bit_cnt <= bit_cnt - 1;
                end
            end

            ST_READ_ACK: begin
                sda_dir <= 0; // SDA input to read ACK
                bit_cnt <= 3'd7;
                state   <= ST_READ;
            end

            endcase
        end
    end

endmodule
