module synchronizer (
    input  logic        clk,
    input  logic [15:0] d,
    output logic [15:0] q
);
    logic [15:0] meta;
    always_ff @(posedge clk) begin
        meta <= d;      // may go metastable
        q    <= meta;   // safe for the rest of the design
    end
endmodule