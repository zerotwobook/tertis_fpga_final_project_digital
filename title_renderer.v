module title_renderer(
    input  logic [9:0] x,           // Current pixel x position (0..639)
    input  logic [9:0] y,           // Current pixel y position (0..479)
    output logic [11:0] pixel_color // Output pixel color (RGB 4:4:4)
);
    // ======================
    // Base colors
    // ======================
    localparam BG    = 12'h000; // Black background
    localparam WHITE = 12'hFFF; // White text color

    // ======================
    // 5x7 pixel font (35 bits = 7 rows × 5 columns)
    // Each glyph is a 5x7 bitmap encoded as 35 bits
    // ======================
    localparam logic [34:0] GLYPH_SP = 35'b0; // Space (blank)

    // Each row is 5 bits (left to right), top row first
    localparam logic [34:0] GLYPH_A = {
        5'b01110,
        5'b10001,
        5'b10001,
        5'b11111,
        5'b10001,
        5'b10001,
        5'b10001
    };

    localparam logic [34:0] GLYPH_C = {
        5'b01110,
        5'b10001,
        5'b10000,
        5'b10000,
        5'b10000,
        5'b10001,
        5'b01110
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

    localparam logic [34:0] GLYPH_F = {
        5'b11111,
        5'b10000,
        5'b10000,
        5'b11110,
        5'b10000,
        5'b10000,
        5'b10000
    };

    localparam logic [34:0] GLYPH_G = {
        5'b01110,
        5'b10001,
        5'b10000,
        5'b10111,
        5'b10001,
        5'b10001,
        5'b01110
    };

    localparam logic [34:0] GLYPH_H = {
        5'b10001,
        5'b10001,
        5'b10001,
        5'b11111,
        5'b10001,
        5'b10001,
        5'b10001
    };

    localparam logic [34:0] GLYPH_I = {
        5'b11111,
        5'b00100,
        5'b00100,
        5'b00100,
        5'b00100,
        5'b00100,
        5'b11111
    };

    localparam logic [34:0] GLYPH_J = {
        5'b11111,
        5'b00010,
        5'b00010,
        5'b00010,
        5'b10010,
        5'b10010,
        5'b01100
    };

    localparam logic [34:0] GLYPH_L = {
        5'b10000,
        5'b10000,
        5'b10000,
        5'b10000,
        5'b10000,
        5'b10000,
        5'b11111
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

    localparam logic [34:0] GLYPH_N = {
        5'b10001,
        5'b11001,
        5'b10101,
        5'b10011,
        5'b10001,
        5'b10001,
        5'b10001
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

    localparam logic [34:0] GLYPH_P = {
        5'b11110,
        5'b10001,
        5'b10001,
        5'b11110,
        5'b10000,
        5'b10000,
        5'b10000
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

    localparam logic [34:0] GLYPH_S = {
        5'b01111,
        5'b10000,
        5'b10000,
        5'b01110,
        5'b00001,
        5'b00001,
        5'b11110
    };

    localparam logic [34:0] GLYPH_T = {
        5'b11111,
        5'b00100,
        5'b00100,
        5'b00100,
        5'b00100,
        5'b00100,
        5'b00100
    };

    localparam logic [34:0] GLYPH_U = {
        5'b10001,
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

    localparam logic [34:0] GLYPH_W = {
        5'b10001,
        5'b10001,
        5'b10001,
        5'b10101,
        5'b10101,
        5'b11011,
        5'b10001
    };

    localparam logic [34:0] GLYPH_Y = {
        5'b10001,
        5'b10001,
        5'b01010,
        5'b00100,
        5'b00100,
        5'b00100,
        5'b00100
    };

    // Custom glyphs for digits 0 and 2 (different than 7-seg)
    localparam logic [34:0] GLYPH_G0 = { // digit "0"
        5'b01110,
        5'b10001,
        5'b10011,
        5'b10101,
        5'b11001,
        5'b10001,
        5'b01110
    };

    localparam logic [34:0] GLYPH_G2 = { // digit "2"
        5'b11110,
        5'b00001,
        5'b00001,
        5'b01110,
        5'b10000,
        5'b10000,
        5'b11111
    };

    // =========================================================
    // Map ASCII character to corresponding glyph bitmap
    // =========================================================
    function automatic logic [34:0] glyph_for_char(input byte ch);
        case (ch)
            "A": glyph_for_char = GLYPH_A;
            "C": glyph_for_char = GLYPH_C;
            "E": glyph_for_char = GLYPH_E;
            "F": glyph_for_char = GLYPH_F;
            "G": glyph_for_char = GLYPH_G;
            "H": glyph_for_char = GLYPH_H;
            "I": glyph_for_char = GLYPH_I;
            "J": glyph_for_char = GLYPH_J;
            "L": glyph_for_char = GLYPH_L;
            "M": glyph_for_char = GLYPH_M;
            "N": glyph_for_char = GLYPH_N;
            "O": glyph_for_char = GLYPH_O;
            "P": glyph_for_char = GLYPH_P;
            "R": glyph_for_char = GLYPH_R;
            "S": glyph_for_char = GLYPH_S;
            "T": glyph_for_char = GLYPH_T;
            "U": glyph_for_char = GLYPH_U;
            "V": glyph_for_char = GLYPH_V;
            "W": glyph_for_char = GLYPH_W;
            "Y": glyph_for_char = GLYPH_Y;
            "0": glyph_for_char = GLYPH_G0;
            "2": glyph_for_char = GLYPH_G2;
            default: glyph_for_char = GLYPH_SP; // Unknown → space
        endcase
    endfunction

    // =========================================================
    // Check if a scaled glyph pixel is ON at a given (x_in_ch,y_in_ch)
    // - ch      : character to draw
    // - x_in_ch : x position inside that character (in screen pixels)
    // - y_in_ch : y position inside that character
    // - scale   : scaling factor for font size
    // Returns 1 if that pixel should be drawn (white), else 0
    // =========================================================
    function automatic logic glyph_pixel_on(
        input byte ch,
        input int  x_in_ch,
        input int  y_in_ch,
        input int  scale
    );
        if (x_in_ch < 5*scale && y_in_ch < 7*scale) begin
            int col = x_in_ch / scale;    // Column index 0..4
            int row = y_in_ch / scale;    // Row index 0..6
            logic [34:0] glyph = glyph_for_char(ch);
            int bit_index = row*5 + col;  // Bit index in 35-bit glyph
            // MSB = top-left pixel, LSB = bottom-right
            glyph_pixel_on = glyph[34 - bit_index];
        end else begin
            glyph_pixel_on = 1'b0;
        end
    endfunction

    // ======================
    // Text content (3 lines)
    // ======================

    // Line 1: "TETRIS" (big title)
    localparam int  TITLE_LEN = 6;
    localparam byte TITLE_CH  [0:TITLE_LEN-1] = { "T","E","T","R","I","S" };

    // Line 2: "CPE222 FINAL PROJECT" (subtitle)
    localparam int  SUB_LEN = 20;
    localparam byte SUB_CH  [0:SUB_LEN-1] = {
        "C","P","E","2","2","2"," ",
        "F","I","N","A","L"," ",
        "P","R","O","J","E","C","T"
    };

    // Line 3: "TURN ON SW0 TO START THE GAME" (instruction)
    localparam int  MSG_LEN = 29;
    localparam byte MSG_CH  [0:MSG_LEN-1] = {
        "T","U","R","N"," ",
        "O","N"," ",
        "S","W","0"," ",
        "T","O"," ",
        "S","T","A","R","T"," ",
        "T","H","E"," ",
        "G","A","M","E"
    };

    // ======================
    // Layout parameters (position & scaling)
    // ======================

    // Spacing between characters in pixels
    localparam int SPACING = 2;

    // "TETRIS" - big title (scaled up)
    localparam int SCALE_BIG = 8;
    localparam int CHARW_BIG = 5 * SCALE_BIG + SPACING; // width per character
    localparam int CHARH_BIG = 7 * SCALE_BIG;           // height of font
    localparam int TITLE_W   = TITLE_LEN * CHARW_BIG;   // total width of title line
    localparam int TITLE_X0  = (640 - TITLE_W) / 2;     // center horizontally
    localparam int TITLE_Y0  = 80;                      // y position for title

    // "CPE222 FINAL PROJECT" - subtitle (medium size)
    localparam int SCALE_SUB = 3;
    localparam int CHARW_SUB = 5 * SCALE_SUB + SPACING;
    localparam int CHARH_SUB = 7 * SCALE_SUB;
    localparam int SUB_W     = SUB_LEN * CHARW_SUB;
    localparam int SUB_X0    = (640 - SUB_W) / 2;       // center horizontally
    localparam int SUB_Y0    = 160;                     // y position for subtitle

    // "TURN ON SW0 TO START THE GAME" - bottom message (smaller)
    localparam int SCALE_MSG = 2;
    localparam int CHARW_MSG = 5 * SCALE_MSG + SPACING;
    localparam int CHARH_MSG = 7 * SCALE_MSG;
    localparam int MSG_W     = MSG_LEN * CHARW_MSG;
    localparam int MSG_X0    = (640 - MSG_W) / 2;       // center horizontally
    localparam int MSG_Y0    = 343;                     // y position for message

    // ======================
    // Main combinational logic
    // ======================
    always_comb begin
        // Default: background color everywhere
        pixel_color = BG;

        // -------- Line 1: TETRIS title --------
        if (x >= TITLE_X0 && x < TITLE_X0 + TITLE_W &&
            y >= TITLE_Y0 && y < TITLE_Y0 + CHARH_BIG) begin

            int rel_x   = x - TITLE_X0;           // X position relative to title start
            int rel_y   = y - TITLE_Y0;           // Y position relative to title start
            int ch_idx  = rel_x / CHARW_BIG;      // Which character in the string
            int x_in_ch = rel_x % CHARW_BIG;      // X inside that character

            if (ch_idx >= 0 && ch_idx < TITLE_LEN &&
                glyph_pixel_on(TITLE_CH[ch_idx], x_in_ch, rel_y, SCALE_BIG)) begin
                pixel_color = WHITE;              // Draw title pixel
            end
        end

        // -------- Line 2: CPE222 FINAL PROJECT --------
        if (x >= SUB_X0 && x < SUB_X0 + SUB_W &&
            y >= SUB_Y0 && y < SUB_Y0 + CHARH_SUB) begin

            int rel_x   = x - SUB_X0;
            int rel_y   = y - SUB_Y0;
            int ch_idx  = rel_x / CHARW_SUB;
            int x_in_ch = rel_x % CHARW_SUB;

            if (ch_idx >= 0 && ch_idx < SUB_LEN &&
                glyph_pixel_on(SUB_CH[ch_idx], x_in_ch, rel_y, SCALE_SUB)) begin
                pixel_color = WHITE;              // Draw subtitle pixel
            end
        end

        // -------- Line 3: TURN ON SW0 TO START THE GAME --------
        if (x >= MSG_X0 && x < MSG_X0 + MSG_W &&
            y >= MSG_Y0 && y < MSG_Y0 + CHARH_MSG) begin

            int rel_x   = x - MSG_X0;
            int rel_y   = y - MSG_Y0;
            int ch_idx  = rel_x / CHARW_MSG;
            int x_in_ch = rel_x % CHARW_MSG;

            if (ch_idx >= 0 && ch_idx < MSG_LEN &&
                glyph_pixel_on(MSG_CH[ch_idx], x_in_ch, rel_y, SCALE_MSG)) begin
                pixel_color = WHITE;              // Draw bottom message pixel
            end
        end
    end

endmodule
