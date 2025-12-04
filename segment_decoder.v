//============================================================
// 7-Segment Decoder (Active-Low)
//------------------------------------------------------------
// - Converts a 4-bit digit (0–9) into a 7-segment LED pattern
// - Output segments are active-low (0 = LED ON, 1 = LED OFF)
// - Segment order: seg[6:0] = {G, F, E, D, C, B, A}
//============================================================
module segment_decoder (
    input  logic [3:0] digit,   // 4-bit input digit (0–9)
    output logic [6:0] seg      // Output for segments A-G (active low)
);

always_comb begin
    case (digit)
      // ------------------------------------------------------
      // Active-low segment patterns (G F E D C B A)
      // 0 = LED ON, 1 = LED OFF
      // ------------------------------------------------------

      4'd0: seg = 7'b1000000;   // Display "0" → A B C D E F on
      4'd1: seg = 7'b1111001;   // Display "1" → B C on
      4'd2: seg = 7'b0100100;   // Display "2" → A B D E G on
      4'd3: seg = 7'b0110000;   // Display "3" → A B C D G on
      4'd4: seg = 7'b0011001;   // Display "4" → B C F G on
      4'd5: seg = 7'b0010010;   // Display "5" → A C D F G on
      4'd6: seg = 7'b0000010;   // Display "6" → A C D E F G on
      4'd7: seg = 7'b1111000;   // Display "7" → A B C on
      4'd8: seg = 7'b0000000;   // Display "8" → All segments on
      4'd9: seg = 7'b0010000;   // Display "9" → A B C D F G on

      default: seg = 7'b1111111; // All segments off (blank)
    endcase
end

endmodule
