// top_tetris.v
// Top module สำหรับ Basys3 Tetris เวอร์ชันง่าย
// ใช้ modules:
//   - clock_divider
//   - button_input
//   - vga_controller
//   - board_memory
//   - game_controller

module top_tetris(
    input  wire CLK100MHZ,
    input  wire SW0,   // reset (active high)

    // Buttons
    input  wire BTNL,
    input  wire BTNR,
    input  wire BTNU,
    input  wire BTND,
    input  wire BTNC,

    // VGA
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire       VGA_HS,
    output wire       VGA_VS,

    // Seven-seg (ยังไม่ใช้ แสดง "0" ไว้เฉย ๆ)
    output wire [6:0] SEG,
    output wire [3:0] AN,

    // LED สถานะ
    output wire LED0
);

    wire reset = SW0;

    // ==========================
    // Clock divider
    // ==========================
    wire clk_25mhz;
    wire game_tick;

    clock_divider #(
        .CLK_FREQ_HZ(100_000_000),
        .GAME_TICK_HZ(1)   // 1 ช่องต่อวินาที ปรับเร็ว/ช้าได้
    ) u_clk (
        .clk       (CLK100MHZ),
        .reset     (reset),
        .clk_25mhz (clk_25mhz),
        .game_tick (game_tick)
    );

    // ==========================
    // Button input + debounce
    // ==========================
    wire move_left, move_right, rotate, soft_drop, hard_drop;

    button_input u_btn (
        .clk        (CLK100MHZ),
        .reset      (reset),
        .BTNL       (BTNL),
        .BTNR       (BTNR),
        .BTNU       (BTNU),
        .BTND       (BTND),
        .BTNC       (BTNC),
        .move_left  (move_left),
        .move_right (move_right),
        .rotate     (rotate),
        .soft_drop  (soft_drop),
        .hard_drop  (hard_drop)
    );

    // ==========================
    // VGA controller
    // ==========================
    wire [9:0] hcount, vcount;
    wire       video_on;

    vga_controller u_vga (
        .clk_25mhz (clk_25mhz),
        .reset     (reset),
        .hcount    (hcount),
        .vcount    (vcount),
        .hsync     (VGA_HS),
        .vsync     (VGA_VS),
        .video_on  (video_on),
        .pixel_tick()
    );

    // ==========================
    // Map pixel -> board cell
    // (ให้กระดานอยู่กลางจอเพียงชุดเดียว)
    // ==========================
    wire in_board_area;
    wire [9:0] local_x;
    wire [9:0] local_y;
    wire [4:0] board_row;
    wire [3:0] board_col;

    assign in_board_area = (hcount >= 240 && hcount < 400 &&
                            vcount >= 80  && vcount < 400);

    assign local_x = hcount - 240;
    assign local_y = vcount - 80;

    assign board_row = in_board_area ? local_y[8:4] : 5'd31; // นอกช่วง 0..19 จะโดนมองว่าไม่มีบล็อก
    assign board_col = in_board_area ? local_x[7:4] : 4'd15; // นอกช่วง 0..9 เหมือนกัน

    // ==========================
    // Board memory
    // ==========================
    wire        write_enable;
    wire [4:0]  write_row;
    wire [3:0]  write_col;
    wire [3:0]  write_color;
    wire        clear_lines;
    wire [19:0] row_clear_mask;
    wire [3:0]  cell_color;

    board_memory u_board (
        .clk            (CLK100MHZ),
        .reset          (reset),
        .write_enable   (write_enable),
        .write_row      (write_row),
        .write_col      (write_col),
        .write_color    (write_color),
        .row_clear_mask (row_clear_mask),
        .clear_lines    (clear_lines),
        .read_row       (board_row),
        .read_col       (board_col),
        .cell_color     (cell_color)
    );

    // ==========================
    // Game controller
    // ==========================
    wire [3:0] active_color;

    game_controller u_game (
        .clk          (CLK100MHZ),
        .reset        (reset),
        .game_tick    (game_tick),
        .move_left    (move_left),
        .move_right   (move_right),
        .rotate       (rotate),
        .soft_drop    (soft_drop),
        .hard_drop    (hard_drop),
        .write_enable (write_enable),
        .write_row    (write_row),
        .write_col    (write_col),
        .write_color  (write_color),
        .clear_lines  (clear_lines),
        .row_clear_mask (row_clear_mask),
        .query_row    (board_row),
        .query_col    (board_col),
        .active_color (active_color)
    );

    // ==========================
    // Color output
    // ==========================
    wire [3:0] final_color = (active_color != 4'h0) ? active_color : cell_color;

    reg [3:0] r_reg, g_reg, b_reg;

    always @(*) begin
        if (!video_on) begin
            r_reg = 4'h0;
            g_reg = 4'h0;
            b_reg = 4'h0;
        end else if (!in_board_area) begin
            // นอกกระดาน → สีพื้นหลังเทา/ดำ
            r_reg = 4'h1;
            g_reg = 4'h1;
            b_reg = 4'h1;
        end else begin
            // ในกระดาน แสดงสีตาม final_color แบบง่าย ๆ
            case (final_color)
                4'h0: begin r_reg = 4'h0; g_reg = 4'h0; b_reg = 4'h3; end // พื้นหลังบอร์ด
                4'hD: begin r_reg = 4'hF; g_reg = 4'h0; b_reg = 4'hF; end // T - magenta
                4'hE: begin r_reg = 4'hF; g_reg = 4'hF; b_reg = 4'h0; end // O - yellow
                4'hC: begin r_reg = 4'h0; g_reg = 4'hF; b_reg = 4'hF; end // I - cyan
                default: begin r_reg = 4'hF; g_reg = 4'hF; b_reg = 4'hF; end
            endcase
        end
    end

    assign VGA_R = r_reg;
    assign VGA_G = g_reg;
    assign VGA_B = b_reg;

    // ==========================
    // 7-seg แสดงเลข 0 ไว้เฉย ๆ
    // ==========================
    assign SEG = 7'b1000000; // "0"
    assign AN  = 4'b1110;    // ใช้ digit ขวาสุด

    // ==========================
    // LED0 เปิดค้าง (ไว้ดูว่า bitstream รันอยู่)
    // ==========================
    assign LED0 = 1'b1;

endmodule
