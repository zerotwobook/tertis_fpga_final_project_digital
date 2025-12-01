module top_module (
    input logic clk,
    input logic rst,
    input logic btnL, btnU, btnD, btnR,
    input logic sw0,
    output logic vga_hsync,
    output logic vga_vsync,
    output logic [3:0] vga_red,
    output logic [3:0] vga_green,
    output logic [3:0] vga_blue,
    output logic [3:0] an,
    output logic [6:0] seg
);

// =====================================================
// Gravity clock divider (2 Hz fall tick from 25 MHz)
// =====================================================
parameter int CLK_HZ     = 25_000_000;
parameter int GRAVITY_HZ = 2; // adjust for faster/slower fall
localparam int DIV_N     = CLK_HZ / GRAVITY_HZ;

logic [$clog2(DIV_N)-1:0] grav_cnt;
logic grav_ce;
logic slw;

clock_divider #(.DIVIDE_BY(4)) vga_clk(
    .fast_clock(clk),
    .slow_clock(slw)
);

always_ff @(posedge slw or posedge rst) begin
    if (rst) begin
        grav_cnt <= '0;
        grav_ce  <= 1'b0;
    end else begin
        if (grav_cnt == DIV_N-1) begin
            grav_cnt <= '0;
            grav_ce  <= 1'b1;
        end else begin
            grav_cnt <= grav_cnt + 1;
            grav_ce  <= 1'b0;
        end
    end
end

logic clk_1khz;
logic up_clean, down_clean, left_clean, right_clean;
logic [9:0] x_pos;
logic [9:0] y_pos;
logic active_video;
logic [11:0] rgb;
logic [3:0] game_grid_array [19:0][9:0]; // Example grid array
logic [15:0] score;
logic [11:0] title_rgb;
logic [11:0] game_over_rgb;
logic game_over_signal;


// ============================
// Game state (Title / Play)
// ============================
typedef enum logic [1:0] {
    GAME_TITLE,
    GAME_PLAY,
    GAME_OVER
} game_state_t;

game_state_t game_state;

// ============================
// Game state controller
// ============================
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        game_state <= GAME_TITLE;

    else if (sw0 == 1 && game_state == GAME_TITLE)
        game_state <= GAME_PLAY;

    else if (game_over_signal == 1 && game_state == GAME_PLAY)
        game_state <= GAME_OVER;
end



clock_divider #(.DIVIDE_BY(100_000)) seg_clk(
    .fast_clock(clk),
    .slow_clock(clk_1khz)
);

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

vga_controller dsply(
    .clk(slw),
    .rst(rst),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .x_pos(x_pos),
    .y_pos(y_pos),
    .active(active_video)
);

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

title_renderer title(
    .x(x_pos),
    .y(y_pos),
    .pixel_color(title_rgb)
);

// ========================
// Game Renderer (existing)
// ========================
block_renderer renderer(
    .curr_pix_x(x_pos),
    .curr_pix_y(y_pos),
    .game_grid_array(game_grid_array),
    .pixel_color(rgb)
);

game_over_renderer go_rend(
    .x(x_pos),
    .y(y_pos),
    .pixel_color(game_over_rgb)
);

tetris_logic game(
    .gm_clk(slw),
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

always_comb begin
    if (active_video) begin
    case (game_state)
        GAME_TITLE: begin
            vga_red   = title_rgb[11:8];
            vga_green = title_rgb[7:4];
            vga_blue  = title_rgb[3:0];
        end
        GAME_PLAY: begin
            vga_red   = rgb[11:8];
            vga_green = rgb[7:4];
            vga_blue  = rgb[3:0];
        end
        GAME_OVER: begin
            vga_red   = game_over_rgb[11:8];
            vga_green = game_over_rgb[7:4];
            vga_blue  = game_over_rgb[3:0];
        end
        default: begin
            vga_red   = 4'h0;
            vga_green = 4'h0;
            vga_blue  = 4'h0;
        end
    endcase
end else begin
    vga_red   = 4'h0;
    vga_green = 4'h0;
    vga_blue  = 4'h0;
end


end

endmodule