`timescale 1ns / 1ps

module neuEm_mod_subtraction(
    // Inputs:
    input logic clk,
    input logic rst_n,
    
    input  logic [11:0] A,
    input  logic [11:0] B,
    // Output:
    output logic [11:0] out_sub
    
);
    // For ML-KEM, q = 3329
    localparam Q = 12'd3329;
    
    // Subtraction
    logic signed [12:0] diff;
    assign diff = $signed({1'b0, A}) - $signed({1'b0, B});
    
    // If diff is negative (sign bit is 1), add 3329.
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) out_sub <= 12'b0;
        else out_sub <= diff[12] ? (diff + Q) : diff[11:0];
    end  
    
endmodule