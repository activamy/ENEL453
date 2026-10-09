module register (
    input  logic        clk, reset, en,
    input  logic [15:0] d,
    output logic [15:0] q
);
    always_ff @(posedge clk)
        if (reset)   q <= '0;
        else if (en) q <= d;   // en is a clock enable, not a clock
endmodule