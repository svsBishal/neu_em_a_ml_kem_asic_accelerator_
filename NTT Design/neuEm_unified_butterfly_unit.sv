`timescale 1ns / 1ps

module neuEm_unified_butterfly (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [11:0] A,
    input  logic [11:0] B,
    input  logic [11:0] W,
    input  logic is_intt, 
    
    output logic [11:0] A_out,
    output logic [11:0] B_out
);

    logic is_intt_d1, is_intt_d2, is_intt_d3, is_intt_d4;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_intt_d1 <= 1'b0;
            is_intt_d2 <= 1'b0;
            is_intt_d3 <= 1'b0;
            is_intt_d4 <= 1'b0;
        end else begin
            is_intt_d1 <= is_intt;
            is_intt_d2 <= is_intt_d1;
            is_intt_d3 <= is_intt_d2;
            is_intt_d4 <= is_intt_d3;
        end
    end

    // FNTT
    logic [11:0] A_d3;
    neuEm_delay_line #(.WIDTH(12), .DEPTH(3)) DELAY_A (
        .clk(clk), .rst_n(rst_n), .din(A), .dout(A_d3)
    );
    
    // INTT
    logic [11:0] W_d1;
    neuEm_delay_line #(.WIDTH(12), .DEPTH(1)) DELAY_W (
        .clk(clk), .rst_n(rst_n), .din(W), .dout(W_d1)
    );

    logic [11:0] add_out, sub_out;
    logic [11:0] add_out_d3;
    neuEm_delay_line #(.WIDTH(12), .DEPTH(3)) DELAY_ADD (
        .clk(clk), .rst_n(rst_n), .din(add_out), .dout(add_out_d3)
    );

    logic [11:0] mult_in_a, mult_in_w;
    logic [11:0] add_sub_in_a, add_sub_in_b;
    logic [11:0] mult_out;

    assign mult_in_a = is_intt ? sub_out : B;
    assign mult_in_w = is_intt ? W_d1 : W;

    assign add_sub_in_a = is_intt ? A : A_d3;
    assign add_sub_in_b = is_intt ? B : mult_out;
    
    neuEm_kred_mod_reduction MULT_INST (
            .clk(clk),
            .rst_n(rst_n),
            .A(mult_in_a),
            .B(mult_in_w),
            .result(mult_out)
    );

    neuEm_mod_addition ADD_INST (
        .clk(clk),
        .rst_n(rst_n),
        .A(add_sub_in_a),
        .B(add_sub_in_b),
        .out_add(add_out)
    );

    neuEm_mod_subtraction SUB_INST (
        .clk(clk),
        .rst_n(rst_n),
        .A(add_sub_in_a),
        .B(add_sub_in_b),
        .out_sub(sub_out)
    );

    assign A_out = is_intt_d4 ? add_out_d3 : add_out;
    assign B_out = is_intt_d4 ? mult_out : sub_out;

endmodule