// debounce.v
// Simple button debouncer for Basys3 buttons
// - Filters mechanical bouncing and produces a stable "clean" output.
//
// The algorithm:
//   - If noisy input == current clean state -> reset counter
//   - If noisy input != current clean state -> increment counter
//   - When counter reaches threshold, flip clean state
//
// Parameter CNT_MAX controls debounce time.
// Example: with 100 MHz clock and CNT_MAX = 1_000_000 -> ~10 ms.

module debounce #(
    parameter integer CNT_MAX = 1_000_000  // adjust for desired debounce time
)(
    input  wire clk,
    input  wire reset,   // active-high synchronous reset
    input  wire noisy,   // raw button signal
    output reg  clean    // debounced signal
);

    reg [$clog2(CNT_MAX)-1:0] cnt = 0;

    always @(posedge clk) begin
        if (reset) begin
            clean <= 1'b0;
            cnt   <= {($clog2(CNT_MAX)){1'b0}};
        end else begin
            if (noisy == clean) begin
                // no change, reset counter
                cnt <= {($clog2(CNT_MAX)){1'b0}};
            end else begin
                // input differs from clean -> count
                if (cnt == CNT_MAX-1) begin
                    clean <= noisy;
                    cnt   <= {($clog2(CNT_MAX)){1'b0}};
                end else begin
                    cnt <= cnt + 1;
                end
            end
        end
    end

endmodule
