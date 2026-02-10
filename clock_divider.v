//============================================================
// Simple clock divider module
// - Divides the input clock frequency by DIVIDE_BY
// - Outputs a slower clock with roughly 50% duty cycle
//------------------------------------------------------------
// Example:
//   fast_clock = 100 MHz, DIVIDE_BY = 4
//   -> slow_clock = 25 MHz
//============================================================
module clock_divider #(parameter DIVIDE_BY = 4)(
    input  logic fast_clock,  // High-frequency input clock
    output logic slow_clock   // Divided (slower) output clock
);

// ------------------------------------------------------------
// Counter width is determined based on DIVIDE_BY.
// $clog2(N) gives number of bits needed to count from 0 to N-1.
// ------------------------------------------------------------
logic [$clog2(DIVIDE_BY) - 1:0] counter = 0;

// ------------------------------------------------------------
// Counter logic: increments on every rising edge of fast_clock.
// When it reaches DIVIDE_BY-1, it wraps back to zero.
// ------------------------------------------------------------
always @(posedge fast_clock) begin
    if(counter == DIVIDE_BY - 1) begin
        counter <= 0;               // Reset counter when full period reached
    end else begin
        counter <= counter + 1;     // Otherwise increment counter normally
    end
end

// ------------------------------------------------------------
// Output clock generation
// - slow_clock is HIGH for the first half of the count
// - slow_clock is LOW for the second half
// This produces a clean divided clock with ~50% duty cycle.
// ------------------------------------------------------------
assign slow_clock = (counter < (DIVIDE_BY / 2)) ? 1 : 0;

endmodule
