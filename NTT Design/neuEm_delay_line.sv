`timescale 1ns / 1ps

module neuEm_delay_line #(
    parameter WIDTH = 12,
    parameter DEPTH = 1
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

    generate
        if (DEPTH == 0) begin : gen_no_delay
            assign dout = din;
        end else begin : gen_shift_register
            logic [WIDTH-1:0] shift_reg [DEPTH-1:0];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (int i = 0; i < DEPTH; i++) begin
                        shift_reg[i] <= '0;
                    end
                end else begin
                    shift_reg[0] <= din;
                    for (int i = 1; i < DEPTH; i++) begin
                        shift_reg[i] <= shift_reg[i-1];
                    end
                end
            end
            assign dout = shift_reg[DEPTH-1];
        end
    endgenerate

endmodule