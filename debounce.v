module debounce (
    input wire clk,
    input wire noisy,
    output logic clean
);

logic [15:0] shift_reg;

always @(posedge clk) begin
    shift_reg <= {shift_reg[14:0], noisy};
end

assign clean = (shift_reg == 16'hFFFF) ? 1 : 0;

endmodule