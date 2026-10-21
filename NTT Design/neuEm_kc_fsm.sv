`timescale 1ns / 1ps

module neuEm_kc_fsm (
    input  logic               clk,
    input  logic               rst_n,

    input  logic               start_load,
    input  logic               start_compute,
    input  logic               start_store,
    
    output logic [2:0]         state,
    output logic [1:0]         cycle_count,
    output logic [2:0]         layer_count,
    output logic               sm_ready,
    
    input  logic [5:0]         rd_addr_A [0:7],
    input  logic [5:0]         rd_addr_B [0:7],
    
    output logic               pipe_wr_en,
    output logic [5:0]         wr_addr_A [0:7],
    output logic [5:0]         wr_addr_B [0:7]
);

    localparam IDLE=3'd0, LOAD=3'd1, COMPUTE=3'd2, DRAIN=3'd3, STORE=3'd4;
    
    assign sm_ready = (state == IDLE);

    logic       valid_pipe [0:3];
    logic [5:0] wr_addr_A_pipe [0:3][0:7];
    logic [5:0] wr_addr_B_pipe [0:3][0:7];
    
    assign pipe_wr_en = valid_pipe[3];
    
    always_comb begin
        for (int k = 0; k < 8; k++) begin
            wr_addr_A[k] = wr_addr_A_pipe[3][k];
            wr_addr_B[k] = wr_addr_B_pipe[3][k];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int p = 0; p < 4; p++) valid_pipe[p] <= 1'b0;
        end else begin
            valid_pipe[0] <= (state == COMPUTE);
            for (int k = 0; k < 8; k++) begin
                wr_addr_A_pipe[0][k] <= rd_addr_A[k];
                wr_addr_B_pipe[0][k] <= rd_addr_B[k];
            end
            for (int p = 1; p < 4; p++) begin
                valid_pipe[p]     <= valid_pipe[p-1];
                wr_addr_A_pipe[p] <= wr_addr_A_pipe[p-1];
                wr_addr_B_pipe[p] <= wr_addr_B_pipe[p-1];
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            cycle_count <= '0;
            layer_count <= '0;
        end else begin
            case (state)
                IDLE: begin
                    cycle_count <= '0;
                    layer_count <= '0;
                    if (start_load) state <= LOAD;
                    else if (start_compute) state <= COMPUTE;
                    else if (start_store) state <= STORE;
                end
                LOAD: begin
                    if (cycle_count == 2'd3) begin
                        cycle_count <= '0;
                        // Direct jump to COMPUTE if the command is ready
                        if (start_compute) state <= COMPUTE;
                        else state <= IDLE;
                    end else cycle_count <= cycle_count + 1;
                end
                COMPUTE: begin
                    if (cycle_count == 2'd3) begin
                        cycle_count <= '0;
                        if (layer_count == 3'd4) state <= DRAIN;
                        else layer_count <= layer_count + 1;
                    end else cycle_count <= cycle_count + 1;
                end
                DRAIN: begin
                    if (cycle_count == 2'd3) begin
                        cycle_count <= '0;
                        // Direct jump to STORE if the command is ready
                        if (start_store) state <= STORE;
                        else state <= IDLE;
                    end else cycle_count <= cycle_count + 1;
                end
                STORE: begin
                    if (cycle_count == 2'd3) begin
                        cycle_count <= '0;
                        // Direct jump to LOAD to immediately intake the next block
                        if (start_load) state <= LOAD;
                        else state <= IDLE;
                    end else cycle_count <= cycle_count + 1;
                end
            endcase
        end
    end
endmodule

