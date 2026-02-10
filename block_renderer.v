//============================================================
// Block Renderer for Tetris Grid
//------------------------------------------------------------
// - Draws the playfield (10 x 20 cells) based on game_grid_array
// - Each cell is BLOCK_SIZE x BLOCK_SIZE pixels
// - Adds a border around the grid
// - Outputs 12-bit RGB color for each pixel
//============================================================
module block_renderer (
    input  logic [9:0] curr_pix_x,                 // Current pixel X coordinate (0..639)
    input  logic [9:0] curr_pix_y,                 // Current pixel Y coordinate (0..479)
    input  logic [3:0] game_grid_array [19:0][9:0],// 20 rows x 10 columns game grid (each cell = 4-bit code)
    output logic [11:0] pixel_color                // Output pixel color (RGB 4:4:4)
);

    // --------------------------------------------------------
    // Grid layout parameters
    // --------------------------------------------------------
    parameter BLOCK_SIZE   = 24;   // Size of each block in pixels (width & height)
    parameter GRID_START_X = 200;  // X coordinate where grid starts on the screen
    parameter GRID_WIDTH   = 240;  // Total grid width in pixels (10 * 24)
    parameter GRID_HEIGHT  = 480;  // Total grid height in pixels (20 * 24)
    parameter GRID_BORDER  = 4;    // Border thickness around the grid (in pixels)

    // --------------------------------------------------------
    // Compute cell indices from current pixel position
    // --------------------------------------------------------
    // Column index (0–9), only valid when inside grid X range
    logic [3:0] cell_x;
    assign cell_x = (curr_pix_x - GRID_START_X) / BLOCK_SIZE;

    // Row index (0–19), only valid when inside grid Y range
    logic [4:0] cell_y;
    assign cell_y = curr_pix_y / BLOCK_SIZE;

    // 4-bit value representing the cell content (piece type / empty)
    logic [3:0] cell_color;

    // --------------------------------------------------------
    // Main rendering logic
    // --------------------------------------------------------
    always_comb begin
        // First, check if the pixel is inside the border around the grid
        if (
            // Left border: just before GRID_START_X
            (curr_pix_x >= GRID_START_X - GRID_BORDER && curr_pix_x < GRID_START_X) ||
            // Right border: just after the grid's right edge
            (curr_pix_x >= GRID_START_X + GRID_WIDTH &&
             curr_pix_x <  GRID_START_X + GRID_WIDTH + GRID_BORDER) ||
            // Top border: just above the grid (y = 0 .. GRID_BORDER-1)
            (curr_pix_y >= 0 && curr_pix_y < GRID_BORDER) ||
            // Bottom border: just below the grid
            (curr_pix_y >= GRID_HEIGHT &&
             curr_pix_y <  GRID_HEIGHT + GRID_BORDER)
        ) begin
            pixel_color = 12'h000;        // Border color (black)
        end 

        // Next, check if we are inside the grid area horizontally
        else if (curr_pix_x >= GRID_START_X &&
                 curr_pix_x <  GRID_START_X + GRID_WIDTH) begin

            // Select the current cell from the game grid
            cell_color = game_grid_array[cell_y][cell_x];

            // Map cell_color codes to actual RGB colors
            case (cell_color)
                4'h0: pixel_color = 12'hFFF; // Empty cell → white background
                4'h1: pixel_color = 12'h000; // Block type 1 → black (placeholder)
                4'h2: pixel_color = 12'h000; // Block type 2 → black (placeholder)
                4'h3: pixel_color = 12'h000; // Block type 3 → black
                4'h4: pixel_color = 12'h000; // Block type 4 → black
                4'h5: pixel_color = 12'h000; // Block type 5 → black
                4'h6: pixel_color = 12'h000; // Block type 6 → black
                4'h7: pixel_color = 12'h000; // Block type 7 → black
                default: pixel_color = 12'hFFF; // Default → white
            endcase
        end 

        // Any pixel outside the grid area and not in the border
        else begin
            pixel_color = 12'hFFF;        // Background outside grid → white
        end
    end

endmodule
