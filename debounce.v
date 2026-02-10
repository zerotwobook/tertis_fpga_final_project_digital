//============================================================
// Debounce module
// - Removes mechanical noise/glitches from a push button
// - Uses a 16-bit shift register to sample the noisy input
// - clean output goes HIGH only when noisy has been HIGH
//   for 16 consecutive clock cycles (fully stable)
//============================================================
module debounce (
    input wire clk,      // Sampling clock (should be slow, e.g., 1 kHz)
    input wire noisy,    // Raw noisy button input
    output logic clean   // Debounced output (clean signal)
);

// ------------------------------------------------------------
// 16-bit shift register
// - Stores the last 16 samples of the noisy input
// - If all bits become 1 => button is considered stable HIGH
// ------------------------------------------------------------
logic [15:0] shift_reg;

// ------------------------------------------------------------
// On each rising edge of clk:
//   - Shift previous samples to the left
//   - Insert the newest 'noisy' sample at bit 0
// ------------------------------------------------------------
// Example shift operation:
//   shift_reg <= {old[14:0], noisy};
// ------------------------------------------------------------
always @(posedge clk) begin
    shift_reg <= {shift_reg[14:0], noisy};
end

// ------------------------------------------------------------
// Output logic:
// clean = HIGH only when all 16 bits of shift_reg are 1
// This means the button remained HIGH for 16 consecutive cycles.
// Otherwise clean = LOW.
// ------------------------------------------------------------
assign clean = (shift_reg == 16'hFFFF) ? 1 : 0;

endmodule
