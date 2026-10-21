`timescale 1ns / 1ps

module tb_neuEm_kaleidoscope_sm_cluster();

    // =========================================================================
    // 1. Signals Declaration
    // =========================================================================
    logic               clk;
    logic               rst_n;

    logic               is_intt;
    logic               start_load;
    logic               start_compute;
    logic               start_store;
    
    logic [7:0][11:0]   A_in;
    logic [7:0][11:0]   B_in;
    logic [7:0][11:0]   W_in;

    logic [7:0][11:0]   A_out;
    logic [7:0][11:0]   B_out;
    logic               sm_ready;
    logic [4:0]         local_twiddle_addr;

    // Golden Reference Memory Arrays
    logic [11:0] test_vector    [0:63];
    logic [11:0] twiddle_vector [0:31];
    logic [11:0] golden_vector  [0:63];

    // =========================================================================
    // 2. Clock & Reset Generation
    // =========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz Clock (10ns period)
    end

    initial begin
        rst_n = 0;
        #23 rst_n = 1;
    end

    // =========================================================================
    // 3. Local Twiddle ROM Routing
    // =========================================================================
    always_comb begin
        for (int k = 0; k < 8; k++) begin
            // Matching the exact Kyber Modulo math used in the Python GRM
            W_in[k] = (twiddle_vector[local_twiddle_addr] + k) % 3329; 
        end
    end

    // =========================================================================
    // 4. Instantiate the DUT
    // =========================================================================
    neuEm_kaleidoscope_cluster dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .is_intt            (is_intt),
        .start_load         (start_load),
        .start_compute      (start_compute),
        .start_store        (start_store),
        .A_in               (A_in),
        .B_in               (B_in),
        .W_in               (W_in),
        .A_out              (A_out),
        .B_out              (B_out),
        .sm_ready           (sm_ready),
        .local_twiddle_addr (local_twiddle_addr)
    );

    // =========================================================================
    // 5. Global AGU Emulation Tasks
    // =========================================================================
    task run_load_phase();
        logic [5:0] addr_A, addr_B;
        $display("\n--- [GLOBAL AGU] Initiating LOAD Phase ---");
        @(posedge clk);
        start_load = 1;
        
        for (int c = 0; c < 4; c++) begin
            for (int k = 0; k < 8; k++) begin
                addr_A = {c[1:0], k[2:0]};
                addr_B = {1'b1, c[1:0], k[2:0]};
                // Load actual hex data instead of dummy sequential numbers
                A_in[k] = test_vector[addr_A];
                B_in[k] = test_vector[addr_B];
            end
            @(posedge clk);
            start_load = 0; 
        end
        
        wait(sm_ready == 1);
        $display("--- LOAD Phase Complete. Cluster is Ready. ---\n");
    endtask

    task run_compute_phase();
        $display("--- [GLOBAL AGU] Triggering Autonomous COMPUTE Phase ---");
        @(posedge clk);
        start_compute = 1;
        @(posedge clk);
        start_compute = 0;

        while (!sm_ready) @(posedge clk);
        $display("--- COMPUTE Phase Complete. Cluster is Ready. ---\n");
    endtask

    task run_store_phase();
        static int error_count = 0;
        logic [11:0] expected_A, expected_B;
        logic [5:0]  addr_A, addr_B;
        
        $display("--- [SCOREBOARD] Initiating STORE Phase & Verifying Outputs ---");
        @(posedge clk);
        start_store = 1;
        
        for (int c = 0; c < 4; c++) begin
            @(posedge clk);
            start_store = 0;
            
            for (int k = 0; k < 8; k++) begin
                addr_A = {c[1:0], k[2:0]};           
                addr_B = {1'b1, c[1:0], k[2:0]};     
                
                expected_A = golden_vector[addr_A];
                expected_B = golden_vector[addr_B];
                
                if (A_out[k] !== expected_A) begin
                    $error("[FAIL] Addr %0d | Expected: %0h | Got: %0h", addr_A, expected_A, A_out[k]);
                    error_count++;
                end
                
                if (B_out[k] !== expected_B) begin
                    $error("[FAIL] Addr %0d | Expected: %0h | Got: %0h", addr_B, expected_B, B_out[k]);
                    error_count++;
                end
            end
        end
        
        wait(sm_ready == 1);
        
        if (error_count == 0) begin
            $display("--- [PASS] ALL 64 COEFFICIENTS MATCH THE GOLDEN REFERENCE! ---");
        end else begin
            $display("--- [FAIL] FOUND %0d MISMATCHES. CHECK PIPELINE DELAYS. ---", error_count);
        end
    endtask

    // =========================================================================
    // 6. Main Test Sequence
    // =========================================================================
    initial begin
        is_intt       = 0;
        start_load    = 0;
        start_compute = 0;
        start_store   = 0;
        A_in          = '0;
        B_in          = '0;
    
        $display("======================================================");
        $display(" Kaleidoscope Cluster Full Integration Testbench");
        $display("======================================================");

        // Load the Golden Reference Files
        $readmemh("D:/IITG_RISCV/ML-KEM HEX/input_data.hex", test_vector);
        $readmemh("D:/IITG_RISCV/ML-KEM HEX/twiddle_factors.hex", twiddle_vector);
        $readmemh("D:/IITG_RISCV/ML-KEM HEX/golden_output.hex", golden_vector);
        
        wait(rst_n == 1);
        @(posedge clk);

        // Execute the Pipeline
        run_load_phase();
        run_compute_phase();
        run_store_phase();
        
        $display("======================================================");
        $display(" Simulation Finished.");
        $display("======================================================");
        $finish;
    end

endmodule