`timescale 1ns / 1ps

module neuEm_unified_butterfly_tb;

    logic        clk;
    logic        rst_n;

    logic [11:0] A, B, W;
    logic        is_intt;

    logic [11:0] A_out, B_out;

    // ============================================================
    // DUT
    // ============================================================

    neuEm_unified_butterfly uut (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .W(W),
        .is_intt(is_intt),
        .A_out(A_out),
        .B_out(B_out)
    );

    // ============================================================
    // Clock Generation
    // 100 MHz clock
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ============================================================
    // Reference Model
    // ============================================================

    function automatic logic [11:0] mod_add(
        input logic [11:0] in_a,
        input logic [11:0] in_b
    );
        return (in_a + in_b) % 3329;
    endfunction


    function automatic logic [11:0] mod_sub(
        input logic [11:0] in_a,
        input logic [11:0] in_b
    );
        return (in_a + 3329 - in_b) % 3329;
    endfunction


    function automatic logic [11:0] mod_mult(
        input logic [11:0] in_a,
        input logic [11:0] in_b
    );
        integer raw_product;

        raw_product = in_a * in_b * 169;

        return raw_product % 3329;
    endfunction

    // ============================================================
    // Expected Result Structure
    // ============================================================

    typedef struct {
        logic [11:0] input_A;
        logic [11:0] input_B;
        logic [11:0] input_W;

        logic [11:0] exp_A;
        logic [11:0] exp_B;

        logic        mode;
    } expected_t;


    integer passed_tests = 0;
    integer total_tests  = 0;

    // ============================================================
    // Drive One Pipeline Transaction
    // ============================================================

    task drive_pipeline(
        input logic [11:0] t_A,
        input logic [11:0] t_B,
        input logic [11:0] t_W,
        input logic        t_mode
    );

        expected_t exp_data;

        logic [11:0] temp_mult;

        // --------------------------------------------------------
        // Calculate Expected Result
        // --------------------------------------------------------

        if (t_mode == 1'b0) begin

            // FNTT / Cooley-Tukey
            temp_mult = mod_mult(t_B, t_W);

            exp_data.exp_A = mod_add(t_A, temp_mult);
            exp_data.exp_B = mod_sub(t_A, temp_mult);

        end
        else begin

            // INTT / Gentleman-Sande
            exp_data.exp_A = mod_add(t_A, t_B);

            exp_data.exp_B =
                mod_mult(
                    mod_sub(t_A, t_B),
                    t_W
                );

        end

        // --------------------------------------------------------
        // Store Input Information
        // --------------------------------------------------------

        exp_data.input_A = t_A;
        exp_data.input_B = t_B;
        exp_data.input_W = t_W;
        exp_data.mode    = t_mode;

        // --------------------------------------------------------
        // Drive DUT Inputs
        // --------------------------------------------------------

        A       = t_A;
        B       = t_B;
        W       = t_W;
        is_intt = t_mode;

        // --------------------------------------------------------
        // Spawn Independent Checker
        // --------------------------------------------------------

        fork

            begin : CHECK_TRANSACTION

                automatic expected_t chk_exp;

                chk_exp = exp_data;

                // Wait exactly 4 rising edges
                repeat(4)
                    @(posedge clk);

                // Check after falling edge
                @(negedge clk);

                total_tests++;

                // ------------------------------------------------
                // Compare DUT output with expected output
                // ------------------------------------------------

                if ((A_out !== chk_exp.exp_A) ||
                    (B_out !== chk_exp.exp_B)) begin

                    $error(
                        "FAIL | Mode: %s | Input A=%4d B=%4d W=%4d | Expected A'=%4d B'=%4d | Got A'=%4d B'=%4d",
                        (chk_exp.mode ? "INTT" : "FNTT"),
                        chk_exp.input_A,
                        chk_exp.input_B,
                        chk_exp.input_W,
                        chk_exp.exp_A,
                        chk_exp.exp_B,
                        A_out,
                        B_out
                    );

                end
                else begin

                    $display(
                        "PASS | Mode: %s | Input A=%4d B=%4d W=%4d | Got A'=%4d B'=%4d",
                        (chk_exp.mode ? "INTT" : "FNTT"),
                        chk_exp.input_A,
                        chk_exp.input_B,
                        chk_exp.input_W,
                        A_out,
                        B_out
                    );

                    passed_tests++;

                end

            end

        join_none

        // --------------------------------------------------------
        // Wait one half cycle before applying next input
        // --------------------------------------------------------

        @(negedge clk);

    endtask

    // ============================================================
    // Main Test
    // ============================================================

    integer i;

    initial begin

        $display("=== Starting 4-Cycle Pipelined Butterfly Testbench ===");

        // --------------------------------------------------------
        // Initial Conditions
        // --------------------------------------------------------

        A       = 12'd0;
        B       = 12'd0;
        W       = 12'd0;
        is_intt = 1'b0;

        rst_n = 1'b0;

        // Hold reset for 22 ns
        #22;

        rst_n = 1'b1;

        // ========================================================
        // FNTT TESTS
        // ========================================================

        $display("");
        $display("--- Pumping Continuous FNTT (CT) Vectors ---");

        // Fixed vector 1
        drive_pipeline(
            12'd10,
            12'd20,
            12'd30,
            1'b0
        );

        // Fixed vector 2
        drive_pipeline(
            12'd3328,
            12'd1,
            12'd2,
            1'b0
        );

        // Fixed vector 3
        drive_pipeline(
            12'd100,
            12'd200,
            12'd300,
            1'b0
        );

        // Five random vectors
        for (i = 0; i < 5; i = i + 1) begin

            drive_pipeline(
                $urandom_range(0, 3328),
                $urandom_range(0, 3328),
                $urandom_range(0, 3328),
                1'b0
            );

        end

        // ========================================================
        // PIPELINE FLUSH
        // ========================================================

        repeat(4)
            @(posedge clk);


        // ========================================================
        // INTT TESTS
        // ========================================================
        #27;

        $display("");
        $display("--- Pumping Continuous INTT (GS) Vectors ---");

        // Fixed vector 1
        drive_pipeline(
            12'd50,
            12'd60,
            12'd70,
            1'b1
        );

        // Fixed vector 2
        drive_pipeline(
            12'd3328,
            12'd3328,
            12'd3328,
            1'b1
        );

        // Fixed vector 3
        drive_pipeline(
            12'd1000,
            12'd2000,
            12'd500,
            1'b1
        );

        // Five random vectors
        for (i = 0; i < 5; i = i + 1) begin

            drive_pipeline(
                $urandom_range(0, 3328),
                $urandom_range(0, 3328),
                $urandom_range(0, 3328),
                1'b1
            );

        end

        // ========================================================
        // FINAL PIPELINE FLUSH
        // ========================================================

        repeat(5)
            @(posedge clk);


        // ========================================================
        // TEST SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("Testbench Completed.");
        $display("Passed: %0d / %0d", passed_tests, total_tests);

        if (passed_tests == total_tests) begin

            $display("STATUS: SUCCESS (Perfect 4-Cycle Alignment)");

        end
        else begin

            $display(
                "STATUS: FAILED (%0d Errors)",
                total_tests - passed_tests
            );

        end

        $display("========================================");

        $finish;

    end

endmodule