module score_display (
    input logic slw_clk,
    input logic rst,
    input logic [15:0] score,
    output logic [3:0] an_cntrl,
    output logic [6:0] seg_cntrl
);

logic [1:0] dig_sel;

always @(posedge slw_clk or posedge rst) begin
    if (rst) begin
        dig_sel <= 2'b00;
    end else begin
        dig_sel <= dig_sel + 1;
    end
end

logic [3:0] dig;
logic [3:0] thousands, hundreds, tens, ones;

always_comb begin
    thousands = (score / 1000) % 10; // Most significant digit
    hundreds = (score / 100) % 10;   // Second digit
    tens = (score / 10) % 10;         // Third digit
    ones = score % 10;                // Least significant digit
end

always_comb begin
    case(dig_sel)
        2'b00: begin
            dig = ones;   // Least significant digit
            an_cntrl = 4'b1110; // Activate first digit
        end
        2'b01: begin
            dig = tens;   // Second digit
            an_cntrl = 4'b1101; // Activate second digit
        end
        2'b10: begin
            dig = hundreds;  // Third digit
            an_cntrl = 4'b1011; // Activate third digit
        end
        2'b11: begin
            dig = thousands; // Most significant digit
            an_cntrl = 4'b0111; // Activate fourth digit
        end
        default: begin
            dig = 4'b0000;       // Default case
            an_cntrl = 4'b1111;  // Deactivate all digits
        end
    endcase
end

segment_decoder seg_dec(
    .digit(dig),
    .seg(seg_cntrl)
);

endmodule