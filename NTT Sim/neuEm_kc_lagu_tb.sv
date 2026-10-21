`timescale 1ns / 1ps

module neuEm_kc_lagu_tb();

    // =========================================================================
    // 1. Signals Declaration
    // =========================================================================
    logic [2:0] state;
    logic [1:0] cycle_count;
    logic [2:0] layer_count;
    
    logic [5:0] rd_addr_A [0:7];
    logic [5:0] rd_addr_B [0:7];

    // FSM State Encodings (Matching the KC FSM)
    localparam IDLE    = 3'd0;
    localparam LOAD    = 3'd1;
    localparam COMPUTE = 3'd2;
    localparam DRAIN   = 3'd3;
    localparam STORE   = 3'd4;

    // =========================================================================
    // 2. Instantiate the Design Under Test (DUT)
    // =========================================================================
    neuEm_kc_lagu dut (
        .state       (state),
        .cycle_count (cycle_count),
        .layer_count (layer_count),
        .rd_addr_A   (rd_addr_A),
        .rd_addr_B   (rd_addr_B)
    );

    // =========================================================================
    // 3. Display Task for Console Verification
    // =========================================================================
    task display_addresses(input string phase_name);
        $display("===================================================================");
        $display("[%s] State: %0d | Layer: %0d | Cycle: %0d", phase_name, state, layer_count, cycle_count);
        $display("-------------------------------------------------------------------");
        $display("Lane  |  Addr A  |  Addr B  |  Expected Stride / Pattern");
        $display("-------------------------------------------------------------------");
        for (int k = 0; k < 8; k++) begin
            $display("  %0d   |    %02d    |    %02d    |  Diff = %0d", 
                     k, rd_addr_A[k], rd_addr_B[k], (rd_addr_B[k] - rd_addr_A[k]));
        end
        $display("===================================================================\n");
    endtask

    // =========================================================================
    // 4. Stimulus Generation
    // =========================================================================
    initial begin
        $display("\nStarting L-AGU Bit-Weaving Verification...\n");

        // ---------------------------------------------------------------------
        // TEST 1: The LOAD State (Sequential Addressing)
        // Expected: A gets indices 0-31, B gets indices 32-63
        // ---------------------------------------------------------------------
        state = LOAD; 
        layer_count = 0;
        for (int c = 0; c < 4; c++) begin
            cycle_count = c; 
            #10; // 10ns propagation delay for combinational logic
            display_addresses("LOAD (Sequential Dump)");
        end

        // ---------------------------------------------------------------------
        // TEST 2: The COMPUTE State - Phase 2 (True Horizontal)
        // ---------------------------------------------------------------------
        state = COMPUTE;
        
        // Layer 0 (Algorithmic Stride 32)
        // Expected: Addr A and Addr B are spaced exactly 32 indices apart
        layer_count = 0;
        for (int c = 0; c < 4; c++) begin
            cycle_count = c; #10;
            display_addresses("COMPUTE - Layer 0 (Stride 32)");
        end

        // Layer 1 (Algorithmic Stride 16)
        // Expected: Addr A and Addr B are spaced exactly 16 indices apart
        layer_count = 1;
        for (int c = 0; c < 4; c++) begin
            cycle_count = c; #10;
            display_addresses("COMPUTE - Layer 1 (Stride 16)");
        end

        // ---------------------------------------------------------------------
        // TEST 3: The COMPUTE State - Phase 3 (Interleaved Horizontal)
        // ---------------------------------------------------------------------
        // Layer 2 (Algorithmic Stride 8)
        layer_count = 2;
        for (int c = 0; c < 4; c++) begin
            cycle_count = c; #10;
            display_addresses("COMPUTE - Layer 2 (Stride 8 - Latency Hiding)");
        end

        // Layer 3 (Algorithmic Stride 4)
        layer_count = 3;
        for (int c = 0; c < 4; c++) begin
            cycle_count = c; #10;
            display_addresses("COMPUTE - Layer 3 (Stride 4 - Latency Hiding)");
        end

        // Layer 4 (Algorithmic Stride 2)
        // Expected: Pairs are tightly packed (e.g., 0 & 1, 2 & 3)
        layer_count = 4;
        for (int c = 0; c < 4; c++) begin
            cycle_count = c; #10;
            display_addresses("COMPUTE - Layer 4 (Stride 2 - Base Case)");
        end

        // ---------------------------------------------------------------------
        // TEST 4: The STORE State (Sequential Dump)
        // ---------------------------------------------------------------------
        state = STORE; 
        layer_count = 0; // Layer count doesn't matter for STORE
        for (int c = 0; c < 4; c++) begin
            cycle_count = c; #10;
            display_addresses("STORE (Sequential Dump)");
        end

        $display("Verification Complete.");
        $finish;
    end

endmodule