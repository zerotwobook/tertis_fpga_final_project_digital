module top_module (
    input logic clk,                     // Main input clock (from board, e.g., 100 MHz or 25 MHz depending on design)
    input logic rst,                     // Asynchronous reset signal (active high)
    input logic btnL, btnU, btnD, btnR,  // Push buttons for left, up (rotate), down, right controls
    input logic sw0,                     // Switch used to start the game from title screen
    output logic vga_hsync,              // VGA horizontal sync output
    output logic vga_vsync,              // VGA vertical sync output
    output logic [3:0] vga_red,          // VGA red color (4-bit)
    output logic [3:0] vga_green,        // VGA green color (4-bit)
    output logic [3:0] vga_blue,         // VGA blue color (4-bit)
    output logic [3:0] an,               // 4-digit 7-segment display anode control
    output logic [6:0] seg               // 7-segment segment control
);

// =====================================================
// Gravity clock divider (generate "fall" ticks for Tetris)
// =====================================================
// These parameters are used to generate a slow tick (grav_ce)
// from a faster pixel/game clock (25 MHz). This tick controls
// how fast the Tetris blocks fall.
parameter int CLK_HZ     = 25_000_000;   // Frequency of the 'slw' clock used for game logic
parameter int GRAVITY_HZ = 2;            // Number of fall steps per second (adjust for speed)
localparam int DIV_N     = CLK_HZ / GRAVITY_HZ; // Number of cycles between gravity ticks

// Counter and enable for gravity tick
logic [$clog2(DIV_N)-1:0] grav_cnt;      // Counter for gravity divider
logic grav_ce;                           // 1-clock-cycle pulse when gravity event occurs
logic slw;                               // Slower clock generated for VGA/game (e.g., 25 MHz)

// -----------------------------------------------------
// Clock divider for VGA / game logic
// -----------------------------------------------------
// This clock_divider module creates a slower clock 'slw' from 'clk'.
// Here DIVIDE_BY=4 is just an example; it depends on the input clock
// and desired output frequency.
clock_divider #(.DIVIDE_BY(4)) vga_clk(
    .fast_clock(clk),
    .slow_clock(slw)
);

// -----------------------------------------------------
// Gravity tick generation
// -----------------------------------------------------
// This always block uses 'slw' as the clock. It counts up to DIV_N-1,
// then asserts grav_ce for 1 cycle to tell the game logic that it's
// time for the piece to fall down one step.
always_ff @(posedge slw or posedge rst) begin
    if (rst) begin
        grav_cnt <= '0;      // Reset gravity counter
        grav_ce  <= 1'b0;    // No gravity tick during reset
    end else begin
        if (grav_cnt == DIV_N-1) begin
            grav_cnt <= '0;  // Reset counter
            grav_ce  <= 1'b1;// Generate gravity enable pulse
        end else begin
            grav_cnt <= grav_cnt + 1; // Increment counter
            grav_ce  <= 1'b0;         // No tick on other cycles
        end
    end
end

// -----------------------------------------------------
// Signals for debouncing, VGA, score, and rendering
// -----------------------------------------------------
logic clk_1khz;                          // ~1 kHz clock for debouncing & 7-segment refresh
logic up_clean, down_clean, left_clean, right_clean; // Debounced button signals
logic [9:0] x_pos;                       // Current pixel X position from VGA controller
logic [9:0] y_pos;                       // Current pixel Y position from VGA controller
logic active_video;                      // High when current pixel is inside visible area
logic [11:0] rgb;                        // 12-bit RGB from main game renderer
logic [3:0] game_grid_array [19:0][9:0]; // 20x10 Tetris game grid, each cell 4-bit color/ID
logic [15:0] score;                      // Current score
logic [11:0] title_rgb;                  // 12-bit RGB from title screen renderer
logic [11:0] game_over_rgb;              // 12-bit RGB from game-over screen renderer
logic game_over_signal;                  // Signal from game logic when the game is over

// ============================
// Game state (Title / Play / Game Over)
// ============================
// Enumeration type for the current overall game state.
typedef enum logic [1:0] {
    GAME_TITLE,  // Show title screen
    GAME_PLAY,   // Playing Tetris
    GAME_OVER    // Show game over screen
} game_state_t;

game_state_t game_state; // Register holding current game state

// ============================
// Game state controller (FSM)
// ============================
// This always block updates the game_state based on reset,
// switch input, and game_over signal.
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        // On reset, always go back to the title screen
        game_state <= GAME_TITLE;

    // When on title screen, pressing sw0 starts the game
    else if (sw0 == 1 && game_state == GAME_TITLE)
        game_state <= GAME_PLAY;

    // When playing and game_over_signal becomes 1, go to GAME_OVER
    else if (game_over_signal == 1 && game_state == GAME_PLAY)
        game_state <= GAME_OVER;
end

// -----------------------------------------------------
// Clock divider for 7-seg refresh & debouncing
// -----------------------------------------------------
// This clock_divider creates an ~1 kHz clock from the main 'clk'.
// It is used for button debouncing and 7-segment multiplexing.
clock_divider #(.DIVIDE_BY(100_000)) seg_clk(
    .fast_clock(clk),
    .slow_clock(clk_1khz)
);

// -----------------------------------------------------
// Debounce modules for push buttons
// -----------------------------------------------------
// Each debounce instance filters the mechanical noise of a button
// so we get a clean one-bit signal without glitches.
debounce db_up(
    .clk(clk_1khz),
    .noisy(btnU),
    .clean(up_clean)
);
debounce db_down(
    .clk(clk_1khz),
    .noisy(btnD),
    .clean(down_clean)
);
debounce db_left(
    .clk(clk_1khz),
    .noisy(btnL),
    .clean(left_clean)
);
debounce db_right(
    .clk(clk_1khz),
    .noisy(btnR),
    .clean(right_clean)
);

// -----------------------------------------------------
// VGA controller
// -----------------------------------------------------
// Generates the VGA sync signals and provides the current pixel
// coordinates (x_pos, y_pos). 'active' indicates whether the current
// pixel is inside the visible region of the screen.
vga_controller dsply(
    .clk(slw),
    .rst(rst),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .x_pos(x_pos),
    .y_pos(y_pos),
    .active(active_video)
);

// -----------------------------------------------------
// 7-segment score display
// -----------------------------------------------------
// Shows the current score on the 4-digit 7-segment display using
// the 1 kHz refresh clock.
score_display score_dsp(
    .slw_clk(clk_1khz),
    .rst(rst),
    .score(score),
    .an_cntrl(an),
    .seg_cntrl(seg)
);

// ========================
// Title Screen Renderer
// ========================
// Generates RGB color for the title screen based on x,y.
title_renderer title(
    .x(x_pos),
    .y(y_pos),
    .pixel_color(title_rgb)
);

// ========================
// Game Renderer
// ========================
// Renders the Tetris board and active piece based on the game grid
// and current pixel position.
block_renderer renderer(
    .curr_pix_x(x_pos),
    .curr_pix_y(y_pos),
    .game_grid_array(game_grid_array),
    .pixel_color(rgb)
);

// ========================
// Game Over Screen Renderer
// ========================
// Generates RGB color for the game over screen based on x,y.
game_over_renderer go_rend(
    .x(x_pos),
    .y(y_pos),
    .pixel_color(game_over_rgb)
);

// ========================
// Tetris Game Logic Core
// ========================
// This module handles all Tetris logic: piece movement, rotation,
// collision detection, line clearing, scoring, and game over.
// - gm_clk: main game clock
// - gm_rst: reset for the game logic (forced high in TITLE state)
// - left/right/down/rott: player controls
// - grav_ce: fall tick from gravity divider
// - grid: 2D array representing the current game board
// - score: current score output
// - game_over: high when losing condition is met
tetris_logic game(
    .gm_clk(slw),
    // While on title screen, force game logic into reset
    .gm_rst( (game_state == GAME_TITLE) ? 1'b1 : rst ),
    .left(left_clean),
    .right(right_clean),
    .down(down_clean),
    .rott(up_clean),
    .grav_ce(grav_ce),
    .grid(game_grid_array),
    .score(score),
    .game_over(game_over_signal) 
);

// ========================
// Top-level VGA color mux
// ========================
// Choose which screen to show (title, game, or game over)
// based on the game_state. If outside active_video, output black.
// Each RGB source is 12 bits, so we split it into 4-bit R/G/B.
always_comb begin
    if (active_video) begin
        case (game_state)
            GAME_TITLE: begin
                // Show title screen colors
                vga_red   = title_rgb[11:8];
                vga_green = title_rgb[7:4];
                vga_blue  = title_rgb[3:0];
            end
            GAME_PLAY: begin
                // Show main game rendering
                vga_red   = rgb[11:8];
                vga_green = rgb[7:4];
                vga_blue  = rgb[3:0];
            end
            GAME_OVER: begin
                // Show game over screen
                vga_red   = game_over_rgb[11:8];
                vga_green = game_over_rgb[7:4];
                vga_blue  = game_over_rgb[3:0];
            end
            default: begin
                // Safety default: black screen
                vga_red   = 4'h0;
                vga_green = 4'h0;
                vga_blue  = 4'h0;
            end
        endcase
    end else begin
        // During blanking intervals, output black
        vga_red   = 4'h0;
        vga_green = 4'h0;
        vga_blue  = 4'h0;
    end
end

endmodule
