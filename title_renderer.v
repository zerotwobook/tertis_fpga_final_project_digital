module title_renderer(
    input  logic [9:0] x,           // current pixel x (0..639)
    input  logic [9:0] y,           // current pixel y (0..479)
    output logic [11:0] pixel_color // RGB 4:4:4
);
    // ======================
    // สีหลัก
    // ======================
    localparam BG      = 12'h000; // พื้นหลังดำ
    localparam WHITE   = 12'hFFF; // สีตัวอักษร
    localparam GRAY    = 12'h666; // ปุ่มเทา
    localparam GRAY_DK = 12'h444; // ขอบปุ่ม

    // ======================
    // ฟอนต์ 5x7 แบบพิกเซล
    // ======================
    // 35 บิต = 7 แถว × 5 คอลัมน์ (row0 = แถวบนสุด)
    localparam logic [34:0] GLYPH_SP = 35'b0;

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

    localparam logic [34:0] GLYPH_G0 = { // digit 0
        5'b01110,
        5'b10001,
        5'b10011,
        5'b10101,
        5'b11001,
        5'b10001,
        5'b01110
    };

    localparam logic [34:0] GLYPH_G2 = { // digit 2
        5'b11110,
        5'b00001,
        5'b00001,
        5'b01110,
        5'b10000,
        5'b10000,
        5'b11111
    };

    // คืน glyph ตาม "ตัวอักษร" ที่เราใช้จริง
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
            default: glyph_for_char = GLYPH_SP;
        endcase
    endfunction

    // ======================
    // ข้อความแต่ละแถว
    // ======================

    // TETRIS (6 ตัว) - ใช้ฟอนต์ใหญ่
    localparam int TITLE_LEN  = 6;
    localparam byte TITLE_CH [0:TITLE_LEN-1] = { "T","E","T","R","I","S" };

    // CPE222 FINAL PROJECT (20 ตัว)
    localparam int SUB_LEN = 20;
    localparam byte SUB_CH [0:SUB_LEN-1] = {
        "C","P","E","2","2","2"," ",
        "F","I","N","A","L"," ",
        "P","R","O","J","E","C","T"
    };

    // TURN ON SW0 TO START THE GAME (29 ตัว)
    localparam int MSG_LEN = 29;
    localparam byte MSG_CH [0:MSG_LEN-1] = {
        "T","U","R","N"," ",
        "O","N"," ",
        "S","W","0"," ",
        "T","O"," ",
        "S","T","A","R","T"," ",
        "T","H","E"," ",
        "G","A","M","E"
    };

    // ======================
    // พารามิเตอร์ layout
    // ======================

    // โลโก้ใหญ่ (ใช้ SCALE = 8)
    localparam int SCALE_BIG   = 8;
    localparam int CHARW_BIG   = 5 * SCALE_BIG;      // 40 px
    localparam int CHARH_BIG   = 7 * SCALE_BIG;      // 56 px
    localparam int TITLE_W     = TITLE_LEN * CHARW_BIG; // 240 px
    localparam int TITLE_X0    = (640 - TITLE_W) / 2;
    localparam int TITLE_Y0    = 80;

    // แถว "CPE222 FINAL PROJECT" (ใช้ SCALE = 3)
    localparam int SCALE_SUB   = 3;
    localparam int CHARW_SUB   = 5 * SCALE_SUB;      // 15
    localparam int CHARH_SUB   = 7 * SCALE_SUB;      // 21
    localparam int SUB_W       = SUB_LEN * CHARW_SUB;
    localparam int SUB_X0      = (640 - SUB_W) / 2;
    localparam int SUB_Y0      = 160;

    // ปุ่มด้านล่าง
    localparam int BTN_X0 = 100;
    localparam int BTN_X1 = 540;
    localparam int BTN_Y0 = 330;
    localparam int BTN_Y1 = 380;

    // ช่องสี่เหลี่ยมซ้าย (แทน SW0)
    localparam int SQ_SIZE = 32;
    localparam int SQ_X0   = BTN_X0 + 30;
    localparam int SQ_Y0   = BTN_Y0 + 14;
    localparam int SQ_X1   = SQ_X0 + SQ_SIZE;
    localparam int SQ_Y1   = SQ_Y0 + SQ_SIZE;

    // ข้อความบนปุ่ม (ใช้ SCALE = 2)
    localparam int SCALE_MSG  = 2;
    localparam int CHARW_MSG  = 5 * SCALE_MSG;       // 10
    localparam int CHARH_MSG  = 7 * SCALE_MSG;       // 14
    localparam int MSG_W      = MSG_LEN * CHARW_MSG; // 290
    localparam int MSG_X0     = (640 - MSG_W) / 2;
    localparam int MSG_Y0     = 343;

    // ======================
    // main combinational
    // ======================
    always_comb begin
        // พื้นหลัง
        pixel_color = BG;

        // ----------------------
        // ปุ่มยาวสีเทาด้านล่าง
        // ----------------------
        if (x >= BTN_X0 && x < BTN_X1 &&
            y >= BTN_Y0 && y < BTN_Y1) begin
            pixel_color = GRAY;
            // ขอบปุ่ม หนา 2 พิกเซล
            if (x < BTN_X0+2 || x >= BTN_X1-2 ||
                y < BTN_Y0+2 || y >= BTN_Y1-2)
                pixel_color = GRAY_DK;
        end

        // สี่เหลี่ยมซ้าย (ช่อง SW0)
        if (x >= SQ_X0 && x < SQ_X1 &&
            y >= SQ_Y0 && y < SQ_Y1) begin
            pixel_color = WHITE;
        end

        // ----------------------
        // โลโก้ TETRIS ตัวใหญ่
        // ----------------------
        if (x >= TITLE_X0 && x < TITLE_X0 + TITLE_W &&
            y >= TITLE_Y0 && y < TITLE_Y0 + CHARH_BIG) begin

            int rel_x = x - TITLE_X0;
            int rel_y = y - TITLE_Y0;

            int ch_idx  = rel_x / CHARW_BIG;          // 0..5
            int x_in_ch = rel_x % CHARW_BIG;
            int y_in_ch = rel_y;

            if (ch_idx >= 0 && ch_idx < TITLE_LEN &&
                x_in_ch < 5*SCALE_BIG &&
                y_in_ch < 7*SCALE_BIG) begin

                int col = x_in_ch / SCALE_BIG;        // 0..4
                int row = y_in_ch / SCALE_BIG;        // 0..6
                logic [34:0] glyph = glyph_for_char(TITLE_CH[ch_idx]);
                int bit_index = row*5 + col;          // 0..34

                if (glyph[34 - bit_index])
                    pixel_color = WHITE;
            end
        end

        // ----------------------
        // ข้อความ CPE222 FINAL PROJECT
        // ----------------------
        if (x >= SUB_X0 && x < SUB_X0 + SUB_W &&
            y >= SUB_Y0 && y < SUB_Y0 + CHARH_SUB) begin

            int rel_x = x - SUB_X0;
            int rel_y = y - SUB_Y0;

            int ch_idx  = rel_x / CHARW_SUB;
            int x_in_ch = rel_x % CHARW_SUB;
            int y_in_ch = rel_y;

            if (ch_idx >= 0 && ch_idx < SUB_LEN &&
                x_in_ch < 5*SCALE_SUB &&
                y_in_ch < 7*SCALE_SUB) begin

                int col = x_in_ch / SCALE_SUB;
                int row = y_in_ch / SCALE_SUB;
                logic [34:0] glyph = glyph_for_char(SUB_CH[ch_idx]);
                int bit_index = row*5 + col;

                if (glyph[34 - bit_index])
                    pixel_color = WHITE;
            end
        end

        // ----------------------
        // ข้อความบนปุ่ม:
        // TURN ON SW0 TO START THE GAME
        // ----------------------
        if (x >= MSG_X0 && x < MSG_X0 + MSG_W &&
            y >= MSG_Y0 && y < MSG_Y0 + CHARH_MSG) begin

            int rel_x = x - MSG_X0;
            int rel_y = y - MSG_Y0;

            int ch_idx  = rel_x / CHARW_MSG;
            int x_in_ch = rel_x % CHARW_MSG;
            int y_in_ch = rel_y;

            if (ch_idx >= 0 && ch_idx < MSG_LEN &&
                x_in_ch < 5*SCALE_MSG &&
                y_in_ch < 7*SCALE_MSG) begin

                int col = x_in_ch / SCALE_MSG;
                int row = y_in_ch / SCALE_MSG;
                logic [34:0] glyph = glyph_for_char(MSG_CH[ch_idx]);
                int bit_index = row*5 + col;

                if (glyph[34 - bit_index])
                    pixel_color = WHITE;
            end
        end
    end

endmodule
