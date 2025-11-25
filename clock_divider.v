// clock_divider.v
// Clock divider for Basys3 Tetris project
// - Input:  100 MHz system clock (CLK100MHZ)
// - Output: 25 MHz pixel clock for VGA
// - Output: game_tick pulse at a low rate for game updates
//
// You can adjust GAME_TICK_HZ to make the Tetris piece fall faster/slower.

module clock_divider #(
    parameter integer CLK_FREQ_HZ  = 100_000_000, // Basys3 main clock
    parameter integer GAME_TICK_HZ = 2           // how many game ticks per second
)(
    input  wire clk,          // 100 MHz clock
    input  wire reset,        // active-high synchronous reset from SW0
    output wire clk_25mhz,    // 25 MHz pixel clock for VGA
    output reg  game_tick     // 1-cycle pulse for game logic
);

    // ============================================================
    // 25 MHz pixel clock (100 MHz / 4)
    // ============================================================
    reg [1:0] pix_div_cnt = 2'b00;

    always @(posedge clk) begin
        if (reset) begin
            pix_div_cnt <= 2'b00;
        end else begin
            pix_div_cnt <= pix_div_cnt + 2'b01;
        end
    end

    assign clk_25mhz = pix_div_cnt[1]; // divide by 4 -> 25 MHz

    // ============================================================
    // Game tick generator
    // Generates a 1-clock-cycle pulse "game_tick" at GAME_TICK_HZ
    // ============================================================
    localparam integer GAME_CNT_MAX = CLK_FREQ_HZ / GAME_TICK_HZ;

    reg [31:0] game_cnt = 32'd0;

    always @(posedge clk) begin
        if (reset) begin
            game_cnt  <= 32'd0;
            game_tick <= 1'b0;
        end else begin
            if (game_cnt == GAME_CNT_MAX - 1) begin
                game_cnt  <= 32'd0;
                game_tick <= 1'b1;  // generate pulse
            end else begin
                game_cnt  <= game_cnt + 32'd1;
                game_tick <= 1'b0;
            end
        end
    end

endmodule
