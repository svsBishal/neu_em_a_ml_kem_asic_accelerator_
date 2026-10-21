`timescale 1ns / 1ps

module neuEm_kred_mod_reduction (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic [11:0] A,
    input  logic [11:0] B,
    output logic [11:0] result
); 

    // PIPELINE STAGE 1:
    logic [23:0] P;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) P <= 24'b0;
        else P <= A * B;
    end
    
    // PIPELINE STAGE 2: 
    logic [7:0]  P1_L;
    logic [15:0] P1_H;
    assign P1_L = P[7:0];
    assign P1_H = P[23:8];
    
    logic [11:0] P1_L_13;
    assign P1_L_13 = (P1_L << 3) + (P1_L << 2) + P1_L;
    
    logic signed [16:0] kred1;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) kred1 <= 17'b0;
        else kred1 <= $signed({1'b0, P1_L_13}) - $signed({1'b0, P1_H});
    end
    
    // PIPELINE STAGE 3:
    logic [7:0]        P2_L;
    logic signed [8:0] P2_H;
    assign P2_L = kred1[7:0];        
    assign P2_H = kred1[16:8];       

    logic [11:0] P2_L_13;
    assign P2_L_13 = (P2_L << 3) + (P2_L << 2) + P2_L;
    
    logic signed [13:0] kred2;
    assign kred2 = $signed({1'b0, P2_L_13}) - P2_H;
    
    logic signed [14:0] final_val;
    always_comb begin
        if (kred2 < 0)
            final_val = kred2 + 15'sd3329;
        else if (kred2 >= 15'sd3329)
            final_val = kred2 - 15'sd3329;
        else
            final_val = kred2;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) result <= 12'b0;
        else result <= final_val[11:0];
    end

endmodule