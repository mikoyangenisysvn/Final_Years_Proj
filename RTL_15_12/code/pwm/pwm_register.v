//-----------------------------------------------------------------
// Module: pwm_register
//-----------------------------------------------------------------
module pwm_register #(
    parameter integer WIDTH = 16
)(
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire              clk_psc_i,
    input  wire              rst_n_i,

    //-----------------------------------------------------------------
    // Bus Interface
    //-----------------------------------------------------------------
    input  wire              wr_en_i,
    input  wire              rd_en_i,
    input  wire [7:0]        addr_i,
    input  wire [WIDTH-1:0]  wr_data_i,
    output reg  [WIDTH-1:0]  rd_data_o,

    //-----------------------------------------------------------------
    // Control outputs to PWM core
    //-----------------------------------------------------------------
    // --- Core 1 ---
    output reg               cen_1_o,
    output reg  [WIDTH-1:0]  arr_preload_1_o,
    output reg  [WIDTH-1:0]  psc_preload_1_o,
    output reg  [WIDTH-1:0]  cmp_ch1_start_o, cmp_ch1_end_o, cfg_reg_ch1,
    output reg  [7:0]        dtg_ch1_o,
    output reg  [WIDTH-1:0]  cmp_ch2_start_o, cmp_ch2_end_o, cfg_reg_ch2,
    output reg  [7:0]        dtg_ch2_o,

    // --- Core 2 ---
    output reg               cen_2_o,
    output reg  [WIDTH-1:0]  arr_preload_2_o,
    output reg  [WIDTH-1:0]  psc_preload_2_o,
    output reg  [WIDTH-1:0]  cmp_ch3_start_o, cmp_ch3_end_o, cfg_reg_ch3,
    output reg  [7:0]        dtg_ch3_o,
    output reg  [WIDTH-1:0]  cmp_ch4_start_o, cmp_ch4_end_o, cfg_reg_ch4,
    output reg  [7:0]        dtg_ch4_o,

    // --- Core 3 ---
    output reg               cen_3_o,
    output reg  [WIDTH-1:0]  arr_preload_3_o,
    output reg  [WIDTH-1:0]  psc_preload_3_o,
    output reg  [WIDTH-1:0]  cmp_ch5_start_o, cmp_ch5_end_o, cfg_reg_ch5,
    output reg  [7:0]        dtg_ch5_o,
    output reg  [WIDTH-1:0]  cmp_ch6_start_o, cmp_ch6_end_o, cfg_reg_ch6,
    output reg  [7:0]        dtg_ch6_o,

    // --- Core 4 ---
    output reg               cen_4_o,
    output reg  [WIDTH-1:0]  arr_preload_4_o,
    output reg  [WIDTH-1:0]  psc_preload_4_o,
    output reg  [WIDTH-1:0]  cmp_ch7_start_o, cmp_ch7_end_o, cfg_reg_ch7,
    output reg  [7:0]        dtg_ch7_o,
    output reg  [WIDTH-1:0]  cmp_ch8_start_o, cmp_ch8_end_o, cfg_reg_ch8,
    output reg  [7:0]        dtg_ch8_o
);

    //-----------------------------------------------------------------
    // Register write logic
    //-----------------------------------------------------------------
    always @(posedge clk_psc_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            // Counter enables
            cen_1_o <= 1'b0;
            cen_2_o <= 1'b0;
            cen_3_o <= 1'b0;
            cen_4_o <= 1'b0;

            // Preload defaults
            arr_preload_1_o <= {WIDTH{1'b1}};
            arr_preload_2_o <= {WIDTH{1'b1}};
            arr_preload_3_o <= {WIDTH{1'b1}};
            arr_preload_4_o <= {WIDTH{1'b1}};

            psc_preload_1_o <= {WIDTH{1'b0}};
            psc_preload_2_o <= {WIDTH{1'b0}};
            psc_preload_3_o <= {WIDTH{1'b0}};
            psc_preload_4_o <= {WIDTH{1'b0}};

            // Channels default
            cmp_ch1_start_o <= {WIDTH{1'b0}}; cmp_ch1_end_o <= {WIDTH{1'b0}}; cfg_reg_ch1 <= {WIDTH{1'b0}}; dtg_ch1_o <= 8'd1;
            cmp_ch2_start_o <= {WIDTH{1'b0}}; cmp_ch2_end_o <= {WIDTH{1'b0}}; cfg_reg_ch2 <= {WIDTH{1'b0}}; dtg_ch2_o <= 8'd1;

            cmp_ch3_start_o <= {WIDTH{1'b0}}; cmp_ch3_end_o <= {WIDTH{1'b0}}; cfg_reg_ch3 <= {WIDTH{1'b0}}; dtg_ch3_o <= 8'd1;
            cmp_ch4_start_o <= {WIDTH{1'b0}}; cmp_ch4_end_o <= {WIDTH{1'b0}}; cfg_reg_ch4 <= {WIDTH{1'b0}}; dtg_ch4_o <= 8'd1;

            cmp_ch5_start_o <= {WIDTH{1'b0}}; cmp_ch5_end_o <= {WIDTH{1'b0}}; cfg_reg_ch5 <= {WIDTH{1'b0}}; dtg_ch5_o <= 8'd1;
            cmp_ch6_start_o <= {WIDTH{1'b0}}; cmp_ch6_end_o <= {WIDTH{1'b0}}; cfg_reg_ch6 <= {WIDTH{1'b0}}; dtg_ch6_o <= 8'd1;

            cmp_ch7_start_o <= {WIDTH{1'b0}}; cmp_ch7_end_o <= {WIDTH{1'b0}}; cfg_reg_ch7 <= {WIDTH{1'b0}}; dtg_ch7_o <= 8'd1;
            cmp_ch8_start_o <= {WIDTH{1'b0}}; cmp_ch8_end_o <= {WIDTH{1'b0}}; cfg_reg_ch8 <= {WIDTH{1'b0}}; dtg_ch8_o <= 8'd1;

        end else if (wr_en_i) begin
            case (addr_i)
                8'd0: {cen_4_o, cen_3_o, cen_2_o, cen_1_o} <= wr_data_i[3:0];
                // Prescaler and ARR for each core
                8'd1: psc_preload_1_o <= wr_data_i; 
                8'd2: arr_preload_1_o <= wr_data_i;

                8'd3: psc_preload_2_o <= wr_data_i; 
                8'd4: arr_preload_2_o <= wr_data_i;

                8'd5: psc_preload_3_o <= wr_data_i; 
                8'd6: arr_preload_3_o <= wr_data_i;
                
                8'd7: psc_preload_4_o <= wr_data_i;
                8'd8: arr_preload_4_o <= wr_data_i;

                // Channels 1-8
                8'd10: cmp_ch1_start_o <= wr_data_i; 
                8'd11: cmp_ch1_end_o <= wr_data_i;
                8'd12: dtg_ch1_o <= wr_data_i[7:0];
				8'd13: cfg_reg_ch1 <= wr_data_i;

                8'd14: cmp_ch2_start_o <= wr_data_i;
				8'd15: cmp_ch2_end_o <= wr_data_i;
                8'd16: dtg_ch2_o <= wr_data_i[7:0];
				8'd17: cfg_reg_ch2 <= wr_data_i;

                8'd18: cmp_ch3_start_o <= wr_data_i;
				8'd19: cmp_ch3_end_o <= wr_data_i;
                8'd20: dtg_ch3_o <= wr_data_i[7:0];
				8'd21: cfg_reg_ch3 <= wr_data_i;

                8'd22: cmp_ch4_start_o <= wr_data_i;
				8'd23: cmp_ch4_end_o <= wr_data_i;
                8'd24: dtg_ch4_o <= wr_data_i[7:0];
				8'd25: cfg_reg_ch4 <= wr_data_i;

                8'd26: cmp_ch5_start_o <= wr_data_i;
				8'd27: cmp_ch5_end_o <= wr_data_i;
                8'd28: dtg_ch5_o <= wr_data_i[7:0];
				8'd29: cfg_reg_ch5 <= wr_data_i;

                8'd30: cmp_ch6_start_o <= wr_data_i;
				8'd31: cmp_ch6_end_o <= wr_data_i;
                8'd32: dtg_ch6_o <= wr_data_i[7:0];
				8'd33: cfg_reg_ch6 <= wr_data_i;

                8'd34: cmp_ch7_start_o <= wr_data_i;
				8'd35: cmp_ch7_end_o <= wr_data_i;
                8'd36: dtg_ch7_o <= wr_data_i[7:0];
				8'd37: cfg_reg_ch7 <= wr_data_i;

                8'd38: cmp_ch8_start_o <= wr_data_i;
				8'd39: cmp_ch8_end_o <= wr_data_i;
                8'd40: dtg_ch8_o <= wr_data_i[7:0];
				8'd41: cfg_reg_ch8 <= wr_data_i;

                default: ; 
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Register read logic
    //-----------------------------------------------------------------
    always @(*) begin
        if (rd_en_i) begin
            case (addr_i)
                8'd0: rd_data_o = {{(WIDTH-4){1'b0}}, cen_4_o, cen_3_o, cen_2_o, cen_1_o};
                8'd1: rd_data_o = psc_preload_1_o;
				8'd2: rd_data_o = arr_preload_1_o;
                8'd3: rd_data_o = psc_preload_2_o;
				8'd4: rd_data_o = arr_preload_2_o;
                8'd5: rd_data_o = psc_preload_3_o;
				8'd6: rd_data_o = arr_preload_3_o;
                8'd7: rd_data_o = psc_preload_4_o;
				8'd8: rd_data_o = arr_preload_4_o;

                8'd10: rd_data_o = cmp_ch1_start_o;
				8'd11: rd_data_o = cmp_ch1_end_o;
                8'd12: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch1_o};
				8'd13: rd_data_o = cfg_reg_ch1;

                8'd14: rd_data_o = cmp_ch2_start_o;
				8'd15: rd_data_o = cmp_ch2_end_o;
                8'd16: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch2_o};
				8'd17: rd_data_o = cfg_reg_ch2;

                8'd18: rd_data_o = cmp_ch3_start_o;
				8'd19: rd_data_o = cmp_ch3_end_o;
                8'd20: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch3_o};
				8'd21: rd_data_o = cfg_reg_ch3;

                8'd22: rd_data_o = cmp_ch4_start_o;
				8'd23: rd_data_o = cmp_ch4_end_o;
                8'd24: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch4_o};
				8'd25: rd_data_o = cfg_reg_ch4;

                8'd26: rd_data_o = cmp_ch5_start_o;
				8'd27: rd_data_o = cmp_ch5_end_o;
                8'd28: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch5_o};
				8'd29: rd_data_o = cfg_reg_ch5;

                8'd30: rd_data_o = cmp_ch6_start_o;
				8'd31: rd_data_o = cmp_ch6_end_o;
                8'd32: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch6_o};
				8'd33: rd_data_o = cfg_reg_ch6;

                8'd34: rd_data_o = cmp_ch7_start_o;
				8'd35: rd_data_o = cmp_ch7_end_o;
                8'd36: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch7_o};
				8'd37: rd_data_o = cfg_reg_ch7;

                8'd38: rd_data_o = cmp_ch8_start_o;
				8'd39: rd_data_o = cmp_ch8_end_o;
                8'd40: rd_data_o = {{(WIDTH-8){1'b0}}, dtg_ch8_o};
				8'd41: rd_data_o = cfg_reg_ch8;

                default: rd_data_o = {WIDTH{1'b0}};
            endcase
        end else begin
            rd_data_o = {WIDTH{1'b0}};
        end
    end

endmodule
