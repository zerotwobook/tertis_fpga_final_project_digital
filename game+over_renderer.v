// game_over_renderer.sv
// แสดงคำว่า "GAME OVER" ตัวใหญ่กลางจอ พื้นหลังดำ

module game_over_renderer(
    input  logic [9:0] x,           // current pixel x (0..639)
    input  logic [9:0] y,           // current pixel y (0..479)
    output logic [11:0] pixel_color // RGB 4:4:4
);
    // สี
    localparam BLACK = 12'h000;
    localparam WHITE = 12'hFFF;

    // ===== ฟอนต์ 5x7 =====
    localparam logic [34:0] GLYPH_SP = 35'b0;

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

    // map char → glyph
    function logic [34:0] glyph_for_char(input logic [7:0] c);
        case (c)
            "G": glyph_for_char = GLYPH_G;
            "A": glyph_for_char = GLYPH_A;
            "M": glyph_for_char = GLYPH_M;
            "E": glyph_for_char = GLYPH_E;
            "O": glyph_for_char = GLYPH_O;
            "V": glyph_for_char = GLYPH_V;
            "R": glyph_for_char = GLYPH_R;
            default: glyph_for_char = GLYPH_SP;
        endcase
    endfunction

    // ===== ข้อความ GAME OVER =====
    localparam int TITLE_LEN = 9;
    localparam logic [7:0] TITLE_CH [0:TITLE_LEN-1] =
        '{ "G","A","M","E"," ","O","V","E","R" };

    // ===== layout / scaling =====
    localparam int SCALE   = 14;          // ปรับขนาดตัวใหญ่
    localparam int CHAR_W  = 5 * SCALE;
    localparam int CHAR_H  = 7 * SCALE;
    localparam int TEXT_W  = TITLE_LEN * CHAR_W;

    localparam int TEXT_X0 = (640 - TEXT_W) / 2; // ตรงกลางจอแนวนอน
    localparam int TEXT_Y0 = 140;                // ตำแหน่งแนวตั้ง (กลาง ๆ)

    // ===== main combinational =====
    always_comb begin
        // ต้องใช้ integer (ไม่ใช่ int) ให้ Vivado ไม่งอแง
        integer rel_x, rel_y;
        integer ch_idx, x_in_ch, y_in_ch;
        integer col, row, bit_index;
        logic [34:0] glyph;

        // พื้นหลังดำ
        pixel_color = BLACK;

        // เฉพาะบริเวณที่มีตัวหนังสือ
        if (x >= TEXT_X0 && x < TEXT_X0 + TEXT_W &&
            y >= TEXT_Y0 && y < TEXT_Y0 + CHAR_H) begin

            rel_x = x - TEXT_X0;
            rel_y = y - TEXT_Y0;

            ch_idx  = rel_x / CHAR_W;  // index ของตัวอักษรในคำ
            x_in_ch = rel_x % CHAR_W;  // ตำแหน่งภายในตัว
            y_in_ch = rel_y;

            if (ch_idx >= 0 && ch_idx < TITLE_LEN &&
                x_in_ch < 5*SCALE &&
                y_in_ch < 7*SCALE) begin

                col   = x_in_ch / SCALE; // 0..4
                row   = y_in_ch / SCALE; // 0..6
                glyph = glyph_for_char(TITLE_CH[ch_idx]);
                bit_index = row*5 + col;

                if (glyph[34 - bit_index])
                    pixel_color = WHITE;
            end
        end
    end

endmodule
