`timescale 1ns / 1ps


module mux2 (
    input  logic [15:0] switches_inputs,
    input  logic [15:0] bcd_out,
    input  logic        bin_bcd_select,
    output logic [15:0] disp_bus
);

    // 2-to-1 multiplexer
    //
    // bin_bcd_select = 0 --> display BCD/decimal value
    // bin_bcd_select = 1 --> display switch/hexadecimal value

    assign disp_bus = bin_bcd_select ? switches_inputs : bcd_out;

endmodule
