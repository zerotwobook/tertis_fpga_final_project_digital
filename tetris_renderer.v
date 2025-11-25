// tetris_renderer.v
// Simple renderer for Tetris project on Basys3
// - Draws a background and a visible board area (with grid) on VGA
// - Later this module can be extended to show active pieces and locked blocks.

module tetris_renderer (
    input  wire        clk_25mhz,
    input  wire        reset,
    input  wire [9:0]  hcount,
    input  wire [9:0]  vcount,
    input  wire        video_on,
    output reg  [3:0]  VGA_R,
    output reg  [3:0]  VGA_G,
    output reg  [3:0]  VGA_B
);

    // Visible resolution
    localparam integer H_VISIBLE = 640;
    localparam integer V_VISIBLE = 480;

    // Tetris board configuration (10x20 cells, each 16x16 pixels)
    localparam integer CELL_SIZE      = 16;
    localparam integer BOARD_COLS     = 10;
    localparam integer BOARD_ROWS     = 20;
    localparam integer BOARD_WIDTH_PX = BOARD_COLS * CELL_SIZE; // 160
    localparam integer BOARD_HEIGHT_PX= BOARD_ROWS * CELL_SIZE; // 320;

    // Center the board on the screen
    localparam integer BOARD_X_START = (H_VISIBLE - BOARD_WIDTH_PX)  / 2; // 240
    localparam integer BOARD_Y_START = (V_VISIBLE - BOARD_HEIGHT_PX) / 2; // 80
    localparam integer BOARD_X_END   = BOARD_X_START + BOARD_WIDTH_PX;
    localparam integer BOARD_Y_END   = BOARD_Y_START + BOARD_HEIGHT_PX;

    wire in_visible_area = video_on;

    // Determine if current pixel is inside the board region
    wire in_board = (hcount >= BOARD_X_START) && (hcount < BOARD_X_END) &&
                    (vcount >= BOARD_Y_START) && (vcount < BOARD_Y_END);

    // Local coordinates inside the board
    wire [9:0] local_x = hcount - BOARD_X_START;
    wire [9:0] local_y = vcount - BOARD_Y_START;

    // Grid lines every CELL_SIZE pixels (since CELL_SIZE = 16, check lower 4 bits == 0)
    wire on_vertical_grid   = (in_board && (local_x[3:0] == 4'b0000));
    wire on_horizontal_grid = (in_board && (local_y[3:0] == 4'b0000));

    // Board border (one-pixel wide around board)
    wire on_border = in_board &&
                     ( (hcount == BOARD_X_START) ||
                       (hcount == BOARD_X_END - 1) ||
                       (vcount == BOARD_Y_START) ||
                       (vcount == BOARD_Y_END - 1) );

    wire on_grid_or_border = on_border || on_vertical_grid || on_horizontal_grid;

    // Simple color scheme:
    //  - Outside visible area: black
    //  - Background: dark blue
    //  - Board region: slightly brighter blue
    //  - Grid & border: white
    always @(*) begin
        if (!in_visible_area) begin
            // Blanking
            VGA_R = 4'h0;
            VGA_G = 4'h0;
            VGA_B = 4'h0;
        end else if (on_grid_or_border) begin
            // Grid lines and border
            VGA_R = 4'hF;
            VGA_G = 4'hF;
            VGA_B = 4'hF;
        end else if (in_board) begin
            // Inside board area
            VGA_R = 4'h0;
            VGA_G = 4'h3;
            VGA_B = 4'h8;
        end else begin
            // Outside board area, background
            VGA_R = 4'h0;
            VGA_G = 4'h0;
            VGA_B = 4'h4;
        end
    end

endmodule
