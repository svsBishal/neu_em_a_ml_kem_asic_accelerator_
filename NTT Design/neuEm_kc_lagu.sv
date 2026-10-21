`timescale 1ns / 1ps

module neuEm_kc_lagu (
    input  logic [2:0]         state,
    input  logic [1:0]         cycle_count,
    input  logic [2:0]         layer_count,
    
    output logic [5:0]         rd_addr_A [0:7],
    output logic [5:0]         rd_addr_B [0:7]
);

    localparam LOAD=3'd1, STORE=3'd4;

    always_comb begin
        for (int k = 0; k < 8; k++) begin
            if (state == STORE || state == LOAD) begin
                rd_addr_A[k] = {1'b0, cycle_count, k[2:0]};
                rd_addr_B[k] = {1'b1, cycle_count, k[2:0]};
            end else begin
                case (layer_count)
                    3'd0: begin // Stride 32
                        rd_addr_A[k] = {1'b0, cycle_count[1:0], k[2:0]};
                        rd_addr_B[k] = {1'b1, cycle_count[1:0], k[2:0]};
                    end
                    3'd1: begin // Stride 16
                        rd_addr_A[k] = {cycle_count[1], 1'b0, cycle_count[0], k[2:0]};
                        rd_addr_B[k] = {cycle_count[1], 1'b1, cycle_count[0], k[2:0]};
                    end
                    3'd2: begin // Stride 8 (Interleaved)
                        rd_addr_A[k] = {cycle_count[1:0], 1'b0, k[2:0]};
                        rd_addr_B[k] = {cycle_count[1:0], 1'b1, k[2:0]};
                    end
                    3'd3: begin // Stride 4 (Interleaved)
                        rd_addr_A[k] = {cycle_count[1:0], k[2], 1'b0, k[1:0]};
                        rd_addr_B[k] = {cycle_count[1:0], k[2], 1'b1, k[1:0]};
                    end
                    3'd4: begin // Stride 2 (Interleaved)
                        rd_addr_A[k] = {cycle_count[1:0], k[2:1], 1'b0, k[0]};
                        rd_addr_B[k] = {cycle_count[1:0], k[2:1], 1'b1, k[0]};
                    end
                    default: begin
                        rd_addr_A[k] = '0; rd_addr_B[k] = '0;
                    end
                endcase
            end
        end
    end
endmodule