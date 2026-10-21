`timescale 1ns / 1ps

module neuEm_kred_mod_reduction_tb;

    // Signals
    logic [11:0] A;
    logic [11:0] B;
    logic [11:0] result;

    // Instantiate the Unit Under Test (UUT)
    neuEm_kred_mod_reduction uut (
        .A(A),
        .B(B),
        .result(result)
    );

    // Test variables
    integer i;
    integer total_tests = 0;
    integer passed_tests = 0;
    
    // Mathematical reference model for Two-Stage K-RED
    // The hardware computes: (A * B * 13 * 13) mod 3329
    function automatic logic [11:0] get_expected (input logic [11:0] a_val, input logic [11:0] b_val);
        integer raw_product;
        raw_product = a_val * b_val * 169; // 13 * 13 = 169
        return raw_product % 3329;
    endfunction

    // Task to drive inputs and check the output
    task run_test(input logic [11:0] test_A, input logic [11:0] test_B);
        logic [11:0] expected_val;
        begin
            A = test_A;
            B = test_B;
            
            // Wait for combinational logic to settle
            #10; 
            
            expected_val = get_expected(test_A, test_B);
            total_tests++;
            
            if (result !== expected_val) begin
                $error("FAIL | A: %4d | B: %4d || Expected: %4d | Got: %4d", test_A, test_B, expected_val, result);
            end else begin
                $display("PASS | A: %4d | B: %4d || Result: %4d", test_A, test_B, result);
                passed_tests++;
            end
        end
    endtask

    // Stimulus process
    initial begin
        $display("=== Starting Two-Stage K-RED Testbench ===");
        
        // 1. Boundary Cases (Min, Max, Ones)
        $display("--- Testing Boundary Cases ---");
        run_test(12'd0, 12'd0);
        run_test(12'd1, 12'd1);
        run_test(12'd3328, 12'd3328);  // Maximum valid coefficient
        run_test(12'd3328, 12'd0);
        run_test(12'd0, 12'd3328);
        
        // 2. Specific Tricky Values
        $display("--- Testing Specific Edge Cases ---");
        run_test(12'd1664, 12'd2);     // Values crossing boundaries
        run_test(12'd256, 12'd13);     
        run_test(12'd3328, 12'd1);
        
        // 3. Randomized Fuzz Testing within ML-KEM bounds [0, 3328]
        $display("--- Testing Randomized Vectors ---");
        for (i = 0; i < 20; i++) begin
            // Generate random values strictly between 0 and 3328
            run_test($urandom_range(0, 3328), $urandom_range(0, 3328));
        end

        // 4. Test Summary
        $display("========================================");
        $display("Testbench Completed.");
        $display("Passed: %0d / %0d", passed_tests, total_tests);
        if (passed_tests == total_tests)
            $display("STATUS: SUCCESS (100%% Match with Golden Model)");
        else
            $display("STATUS: FAILED (%0d Errors)", total_tests - passed_tests);
        $display("========================================");
        
        $finish;
    end

endmodule