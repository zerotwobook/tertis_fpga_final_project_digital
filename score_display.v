//============================================================
// 4-digit 7-segment Score Display
//------------------------------------------------------------
// - Takes a 16-bit score (0–9999)
// - Splits it into thousands, hundreds, tens, ones
// - Multiplexes four 7-segment digits using a slow clock
// - Uses active-low anode control (0 = ON, 1 = OFF)
//============================================================
module score_display (
    input  logic       slw_clk,    // Slow clock for digit scanning (e.g., ~1 kHz)
    input  logic       rst,        // Reset signal (active high)
    input  logic [15:0] score,     // 16-bit score value to display (0–9999)
    output logic [3:0] an_cntrl,   // Anode control for 4 digits (active low)
    output logic [6:0] seg_cntrl   // Segment control for current digit (a–g)
);

// ------------------------------------------------------------
// 2-bit digit selector
// - dig_sel chooses which digit (0..3) is currently active
// - 00 = ones, 01 = tens, 10 = hundreds, 11 = thousands
// ------------------------------------------------------------
logic [1:0] dig_sel;

// Cycle through digits on every rising edge of slw_clk
always @(posedge slw_clk or posedge rst) begin
    if (rst) begin
        dig_sel <= 2'b00;          // Reset: start at least significant digit
    end else begin
        dig_sel <= dig_sel + 1;    // Rotate through 00 → 01 → 10 → 11 → 00 ...
    end
end

// ------------------------------------------------------------
// BCD digit extraction (thousands, hundreds, tens, ones)
// ------------------------------------------------------------
logic [3:0] dig;                   // Currently selected digit value (0–9)
logic [3:0] thousands, hundreds, tens, ones;

// Convert binary score into individual decimal digits
always_comb begin
    thousands = (score / 1000) % 10;   // Most significant digit
    hundreds  = (score / 100)  % 10;   // Second digit
    tens      = (score / 10)   % 10;   // Third digit
    ones      = score % 10;            // Least significant digit
end

// ------------------------------------------------------------
// Digit multiplexer & anode control
// ------------------------------------------------------------
// Based on dig_sel, choose which digit to display and which
// anode line to activate (active low).
always_comb begin
    case(dig_sel)
        2'b00: begin
            dig      = ones;        // Show ones
            an_cntrl = 4'b1110;     // Enable digit 0 (rightmost)
        end
        2'b01: begin
            dig      = tens;        // Show tens
            an_cntrl = 4'b1101;     // Enable digit 1
        end
        2'b10: begin
            dig      = hundreds;    // Show hundreds
            an_cntrl = 4'b1011;     // Enable digit 2
        end
        2'b11: begin
            dig      = thousands;   // Show thousands
            an_cntrl = 4'b0111;     // Enable digit 3 (leftmost)
        end
        default: begin
            dig      = 4'b0000;     // Default digit = 0
            an_cntrl = 4'b1111;     // All digits off (just in case)
        end
    endcase
end

// ------------------------------------------------------------
// 7-segment decoder
// ------------------------------------------------------------
// Converts 4-bit digit (0–9) into 7-segment pattern.
// 'segment_decoder' must be defined separately.
segment_decoder seg_dec(
    .digit(dig),
    .seg(seg_cntrl)
);

endmodule
