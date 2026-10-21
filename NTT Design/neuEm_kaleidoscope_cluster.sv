`timescale 1ns / 1ps

module neuEm_kaleidoscope_cluster (
    input  logic               clk,
    input  logic               rst_n,

    input  logic               is_intt,
    input  logic               start_load,
    input  logic               start_compute,
    input  logic               start_store,
    
    input  logic [7:0][11:0]   A_in,
    input  logic [7:0][11:0]   B_in,
    input  logic [7:0][11:0]   W_in,

    output logic [7:0][11:0]   A_out,
    output logic [7:0][11:0]   B_out,
    output logic               sm_ready,
    output logic [4:0]         local_twiddle_addr
);

    logic [2:0]  state, layer_count;
    logic [1:0]  cycle_count;
    
    logic [5:0]  lagu_addr_A [0:7], lagu_addr_B [0:7];
    logic [5:0]  fsm_wr_addr_A [0:7], fsm_wr_addr_B [0:7];
    logic        fsm_wr_en;

    logic [11:0] rf_rd_data_A [0:7], rf_rd_data_B [0:7];
    logic [5:0]  rf_wr_addr_A [0:7], rf_wr_addr_B [0:7];
    logic [11:0] rf_wr_data_A [0:7], rf_wr_data_B [0:7];
    logic        rf_wr_en;

    logic [11:0] bu_out_A [0:7], bu_out_B [0:7];

    localparam LOAD = 3'd1;

    assign local_twiddle_addr = {layer_count, cycle_count};

    always_comb begin
        for (int k = 0; k < 8; k++) begin
            A_out[k] = rf_rd_data_A[k];
            B_out[k] = rf_rd_data_B[k];
        end
    end

    assign rf_wr_en = (state == LOAD) ? 1'b1 : fsm_wr_en;

    always_comb begin
        for (int k = 0; k < 8; k++) begin
            rf_wr_addr_A[k] = (state == LOAD) ? lagu_addr_A[k] : fsm_wr_addr_A[k];
            rf_wr_addr_B[k] = (state == LOAD) ? lagu_addr_B[k] : fsm_wr_addr_B[k];
            rf_wr_data_A[k] = (state == LOAD) ? A_in[k]        : bu_out_A[k];
            rf_wr_data_B[k] = (state == LOAD) ? B_in[k]        : bu_out_B[k];
        end
    end

    neuEm_kc_fsm KC_FSM (
        .clk            (clk),
        .rst_n          (rst_n),
        .start_load     (start_load),
        .start_compute  (start_compute),
        .start_store    (start_store),
        .state          (state),
        .cycle_count    (cycle_count),
        .layer_count    (layer_count),
        .sm_ready       (sm_ready),
        .rd_addr_A      (lagu_addr_A),
        .rd_addr_B      (lagu_addr_B),
        .pipe_wr_en     (fsm_wr_en),
        .wr_addr_A      (fsm_wr_addr_A),
        .wr_addr_B      (fsm_wr_addr_B)
    );

    neuEm_kc_lagu L_AGU (
        .state          (state),
        .cycle_count    (cycle_count),
        .layer_count    (layer_count),
        .rd_addr_A      (lagu_addr_A),
        .rd_addr_B      (lagu_addr_B)
    );

    neuEm_kc_l1_rf L1_CACHE (
        .clk            (clk),
        .rd_addr_A      (lagu_addr_A),
        .rd_addr_B      (lagu_addr_B),
        .rd_data_A      (rf_rd_data_A),
        .rd_data_B      (rf_rd_data_B),
        .wr_en          (rf_wr_en),
        .wr_addr_A      (rf_wr_addr_A),
        .wr_addr_B      (rf_wr_addr_B),
        .wr_data_A      (rf_wr_data_A),
        .wr_data_B      (rf_wr_data_B)
    );

    genvar lane;
    generate
        for (lane = 0; lane < 8; lane++) begin : BU
            neuEm_unified_butterfly _KC (
                .clk     (clk),
                .rst_n   (rst_n),
                .A       (rf_rd_data_A[lane]),
                .B       (rf_rd_data_B[lane]),
                .W       (W_in[lane]),
                .is_intt (is_intt),
                .A_out   (bu_out_A[lane]),
                .B_out   (bu_out_B[lane])
            );
        end
    endgenerate

endmodule