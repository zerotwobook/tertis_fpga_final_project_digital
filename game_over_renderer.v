module game_over_renderer(
    input  logic [9:0] x,           // Current pixel x position (0..639)
    input  logic [9:0] y,           // Current pixel y position (0..479)
    output logic [11:0] pixel_color // Output pixel color (RGB 4:4:4)
);
    // ======================
    // Colors
    // ======================
    localparam BLACK = 12'h000; // Background color (black)
    localparam WHITE = 12'hFFF; // Text color (white)

    // ======================
    // 5x7 font (35 bits = 7 rows × 5 columns)
    // Each glyph is a 5x7 bitmap stored as 35 bits.
    // MSB = top-left, LSB = bottom-right.
    // ======================
    localparam logic [34:0] GLYPH_SP = 35'b0; // Space (no pixels on)

    localparam logic [34:0] GLYPH_G = {
        5'b01110,
        5'b10001,
        5'b10000,
        5'b10111,
        5'b10001,
        5'b10001,
        5'b01110
    };

    localparam logic [34:0] GLYPH_A = {
        5'b01110,
        5'b10001,
        5'b10001,
        5'b11111,
        5'b10001,
        5'b10001,
        5'b10001
    };

    localparam logic [34:0] GLYPH_M = {
        5'b10001,
        5'b11011,
        5'b10101,
        5'b10101,
        5'b10001,
        5'b10001,
        5'b10001
    };

    localparam logic [34:0] GLYPH_E = {
        5'b11111,
        5'b10000,
        5'b10000,
        5'b11110,
        5'b10000,
        5'b10000,
        5'b11111
    };

    localparam logic [34:0] GLYPH_O = {
        5'b01110,
        5'b10001,
        5'b10001,
        5'b10001,
        5'b10001,
        5'b10001,
        5'b01110
    };

    localparam logic [34:0] GLYPH_V = {
        5'b10001,
        5'b10001,
        5'b10001,
        5'b10001,
        5'b01010,
        5'b01010,
        5'b00100
    };

    localparam logic [34:0] GLYPH_R = {
        5'b11110,
        5'b10001,
        5'b10001,
        5'b11110,
        5'b10100,
        5'b10010,
        5'b10001
    };

    // =========================================================
    // Character → glyph mapping
    // - Given an ASCII character, return the corresponding 5x7 glyph
    // =========================================================
    function automatic logic [34:0] glyph_for_char(input logic [7:0] c);
        case (c)
            "G": glyph_for_char = GLYPH_G;
            "A": glyph_for_char = GLYPH_A;
            "M": glyph_for_char = GLYPH_M;
            "E": glyph_for_char = GLYPH_E;
            "O": glyph_for_char = GLYPH_O;
            "V": glyph_for_char = GLYPH_V;
            "R": glyph_for_char = GLYPH_R;
            default: glyph_for_char = GLYPH_SP; // Anything else → space
        endcase
    endfunction

    // ======================
    // Text: "GAME OVER"
    // ======================
    localparam int TITLE_LEN = 9;
    localparam logic [7:0] TITLE_CH [0:TITLE_LEN-1] =
        '{ "G","A","M","E"," ","O","V","E","R" };

    // ======================
    // Layout / scaling
    // ======================

    // SCALE: how many screen pixels per 1 font pixel.
    // SPACING: blank pixels between characters.
    localparam int SCALE   = 8;           // Character scale factor
    localparam int SPACING = 2;           // Pixels between characters

    // Width and height (in screen pixels) per character cell
    localparam int CHAR_W  = 5 * SCALE + SPACING; // Glyph width + spacing
    localparam int CHAR_H  = 7 * SCALE;           // Glyph height

    // Total text width in pixels (9 characters)
    localparam int TEXT_W  = TITLE_LEN * CHAR_W;

    // Top-left origin of text (centered horizontally)
    localparam int TEXT_X0 = (640 - TEXT_W) / 2; // Center on 640-wide screen
    localparam int TEXT_Y0 = 160;                // Vertical position of text

    // ======================
    // Main combinational logic
    // ======================
    always_comb begin
        integer rel_x, rel_y;    // Pixel position relative to text origin
        integer ch_idx;          // Character index in TITLE_CH
        integer x_in_ch, y_in_ch;// Position inside current character cell
        integer col, row;        // Column/row inside 5x7 glyph
        integer bit_index;       // Index into 35-bit glyph
        logic   [34:0] glyph;    // Selected character glyph

        // Default: fill screen with background color
        pixel_color = BLACK;

        // Only consider pixels inside the bounding box of "GAME OVER"
        if (x >= TEXT_X0 && x < TEXT_X0 + TEXT_W &&
            y >= TEXT_Y0 && y < TEXT_Y0 + CHAR_H) begin

            // Compute pixel position relative to text origin
            rel_x = x - TEXT_X0;
            rel_y = y - TEXT_Y0;

            // Find which character this pixel belongs to
            ch_idx  = rel_x / CHAR_W;   // 0..8
            x_in_ch = rel_x % CHAR_W;   // X inside that character cell
            y_in_ch = rel_y;            // Y inside that character cell

            // Only draw inside the glyph area (ignore gap region on the right)
            if (ch_idx >= 0 && ch_idx < TITLE_LEN &&
                x_in_ch < 5*SCALE &&
                y_in_ch < 7*SCALE) begin

                // Convert screen-pixel coordinates to glyph-pixel coordinates
                col   = x_in_ch / SCALE; // 0..4
                row   = y_in_ch / SCALE; // 0..6

                // Fetch the glyph for the current character
                glyph = glyph_for_char(TITLE_CH[ch_idx]);

                // Bit index in the 35-bit glyph (row-major)
                bit_index = row*5 + col;

                // If the glyph bit is 1 → draw white pixel
                if (glyph[34 - bit_index])
                    pixel_color = WHITE;
            end
        end
    end

endmodule
