`timescale 1ns / 1ps

module neuEm_mod_addition(
    // Inputs:
    input logic clk,
    input logic rst_n,
    
    input  logic [11:0] A,
    input  logic [11:0] B,
    // Output:
    output logic [11:0] out_add
    
    );
    // For ML-KEM, q = 3329
    localparam Q = 12'd3329;
    
    //Addition
    logic [12:0] sum;
    assign sum = A + B;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) out_add <= 12'b0;
        else out_add <= (sum >= Q) ? (sum - Q) : sum[11:0];
    end 
    
        
endmodule
