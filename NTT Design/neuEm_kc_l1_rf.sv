`timescale 1ns / 1ps

module neuEm_kc_l1_rf (
    input  logic               clk,
    
    input  logic [5:0]         rd_addr_A [0:7],
    input  logic [5:0]         rd_addr_B [0:7],
    output logic [11:0]        rd_data_A [0:7],
    output logic [11:0]        rd_data_B [0:7],
    
    input  logic               wr_en,
    input  logic [5:0]         wr_addr_A [0:7],
    input  logic [5:0]         wr_addr_B [0:7],
    input  logic [11:0]        wr_data_A [0:7],
    input  logic [11:0]        wr_data_B [0:7]
);

    logic [11:0] mem [0:63];

    always_comb begin
        for (int k = 0; k < 8; k++) begin
            rd_data_A[k] = mem[rd_addr_A[k]];
            rd_data_B[k] = mem[rd_addr_B[k]];
        end
    end

    always_ff @(posedge clk) begin
        if (wr_en) begin
            for (int k = 0; k < 8; k++) begin
                mem[wr_addr_A[k]] <= wr_data_A[k];
                mem[wr_addr_B[k]] <= wr_data_B[k];
            end
        end
    end
endmodule