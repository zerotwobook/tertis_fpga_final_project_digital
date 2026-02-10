//============================================================
// Optimized 2D array version of tetris_logic for better
// synthesis performance.
// - Uses a 20x10 2D array gm_memory as the main board storage
// - Separate FSM states: INIT, SPAWN, FALLING, LANDED, CLEAR, GAME_OVER
// - Active piece is drawn on top of gm_memory in always_comb
//============================================================
module tetris_logic (
    input  logic gm_clk,                         // Game clock
    input  logic gm_rst,                         // Game reset (active high)
    input  logic down, left, right, rott,        // Player inputs: drop, move left/right, rotate
    input  logic grav_ce,                        // Gravity tick (from clock divider)
    output logic [3:0] grid  [19:0][9:0],        // Output game grid (for renderer)
    output logic [15:0] score,                   // Current score
    output logic game_over                       // Game over flag
);

    // --------------------------------------------------------
    // Game state machine and storage
    // --------------------------------------------------------
    reg [2:0]  gm_state;                         // FSM state
    reg [15:0] gm_score;                         // Score register
    reg [3:0]  gm_memory [19:0][9:0];            // 20x10 board: 0 = empty, >0 = block color/type

    // Active piece info
    reg  [2:0] active_block;                     // Piece type (0..6)
    reg  [1:0] rotate;                           // Rotation state (0..3)
    logic signed [3:0] active_x;                 // X position of piece (can be negative temporarily)
    reg [4:0]   active_y;                        // Y position (0..19)
    logic [3:0] active_color;                    // Color code for active piece
    logic [15:0] shape_map;                      // 4x4 bit pattern for shape in collision
    logic [15:0] shape_map1;                     // 4x4 bit pattern for drawing
    logic [19:0] rows_to_clear;                  // Unused here, but placeholder for line clear flags

    // Input edge detection registers
    logic down_prev, left_prev, right_prev, rott_prev;
    logic down_edge, left_edge, right_edge, rott_edge;

    //========================================================
    // Edge detection for button presses
    // - Detects rising edges (press events) of down/left/right/rott
    //========================================================
    always_ff @(posedge gm_clk) begin
        down_prev  <= down;
        left_prev  <= left;
        right_prev <= right;
        rott_prev  <= rott;
    end

    assign down_edge  = down  && !down_prev;
    assign left_edge  = left  && !left_prev;
    assign right_edge = right && !right_prev;
    assign rott_edge  = rott  && !rott_prev;

    //========================================================
    // Shape lookup function (Tetromino definitions)
    //--------------------------------------------------------
    // get_shape returns a 4x4 bitmap (16 bits) representing
    // the tetromino shape in a given rotation.
    //
    // piece_type: 0..6 for 7 tetromino types
    // piece_rot : 0..3 for rotation states
    //
    // Bit layout (row-major, 4x4):
    //   [15 14 13 12]
    //   [11 10  9  8]
    //   [ 7  6  5  4]
    //   [ 3  2  1  0]
    //========================================================
    function logic [15:0] get_shape(input [2:0] piece_type, input [1:0] piece_rot);
        case(piece_type)
            // I piece
            3'b000: get_shape = (piece_rot[0]) ?
                                16'b0100010001000100 :  // vertical
                                16'b0000111100000000;   // horizontal
            // O piece (square)
            3'b001: get_shape = 16'b0000011001100000;
            // T piece
            3'b010: case(piece_rot)
                        2'b00: get_shape = 16'b0000010011100000;
                        2'b01: get_shape = 16'b0000010001100100;
                        2'b10: get_shape = 16'b0000000011100100;
                        2'b11: get_shape = 16'b0000010011000100;
                    endcase
            // J piece
            3'b011: case(piece_rot)
                        2'b00: get_shape = 16'b0100010001100000;
                        2'b01: get_shape = 16'b0111010000000000;
                        2'b10: get_shape = 16'b0011000100010000;
                        2'b11: get_shape = 16'b0000000101110000;
                    endcase
            // L piece
            3'b100: case(piece_rot)
                        2'b00: get_shape = 16'b0000001000100110;
                        2'b01: get_shape = 16'b0000100011100000;
                        2'b10: get_shape = 16'b0000011001000100;
                        2'b11: get_shape = 16'b0000000011100010;
                    endcase
            // S piece
            3'b101: get_shape = (piece_rot[0]) ?
                                16'b0000010001100010 :
                                16'b0000001101100000;
            // Z piece
            3'b110: get_shape = (piece_rot[0]) ?
                                16'b0000001001100100 :
                                16'b0000011000110000;
            default: get_shape = 16'b0;
        endcase
    endfunction

    //========================================================
    // Collision check function
    //--------------------------------------------------------
    // Returns 1 (true) if a piece at (piece_x, piece_y) with
    // given type/rotation would collide:
    //  - with walls (x out of 0..9)
    //  - with floor (y > 19)
    //  - with existing blocks in gm_memory
    // Otherwise returns 0 (no collision).
    //========================================================
    function logic check_collision(
        input [2:0] piece_type,
        input [1:0] piece_rot,
        input logic signed [3:0] piece_x,
        input [4:0] piece_y
    );
        shape_map = get_shape(piece_type, piece_rot);
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                if (shape_map[15 - (i*4 + j)]) begin
                    automatic int grid_x = piece_x + j;
                    automatic int grid_y = piece_y + i;

                    // Out of horizontal or vertical bounds
                    if (grid_x < 0 || grid_x > 9 || grid_y > 19)
                        return 1;

                    // Collision with existing block in board memory
                    if (grid_y >= 0 && gm_memory[grid_y][grid_x] != 4'b0)
                        return 1;
                end
            end
        end
        return 0;
    endfunction

    //========================================================
    // Game logic FSM
    //--------------------------------------------------------
    // States (gm_state):
    //  000: INIT       - Clear board and reset score
    //  001: SPAWN      - Spawn a new piece
    //  010: FALLING    - Handle player moves & gravity
    //  011: LANDED     - Lock piece into board
    //  100: CLEAR      - Clear full lines & update score
    //  101: GAME_OVER  - Game over state
    //========================================================
    always_ff @(posedge gm_clk) begin
        if (gm_rst) begin
            gm_state  <= 3'b000;
            game_over <= 1'b0;
        end else begin
            // Default: game_over low except in GAME_OVER state
            game_over <= 1'b0;

            case (gm_state)
                // --------------------------------------------
                // INIT: Clear the entire gm_memory and reset score
                // --------------------------------------------
                3'b000: begin
                    // Clear full board
                    for (int i = 0; i < 20; i++)
                        for (int j = 0; j < 10; j++)
                            gm_memory[i][j] <= 4'b0;

                    gm_score     <= 16'b0;
                    active_block <= 3'b000;
                    gm_state     <= 3'b001; // Go to SPAWN
                end

                // --------------------------------------------
                // SPAWN: Select next piece and place at top
                // --------------------------------------------
                3'b001: begin
                    // Simple cycling piece generator (0..6)
                    if (active_block >= 3'b110)
                        active_block <= 3'b000;
                    else
                        active_block <= active_block + 1;

                    rotate   <= 2'b00;  // Reset rotation
                    active_x <= 4'd4;  // Spawn near center
                    active_y <= 5'd0;  // Top row

                    // If collision at spawn → GAME OVER
                    if (check_collision(active_block, 2'b00, 4'd4, 5'd0))
                        gm_state <= 3'b101;
                    else
                        gm_state <= 3'b010; // Go to FALLING
                end

                // --------------------------------------------
                // FALLING: Player movement + gravity drop
                // --------------------------------------------
                3'b010: begin
                    automatic logic signed [3:0] next_x   = active_x;
                    automatic logic [4:0]        next_y   = active_y;
                    automatic logic [1:0]        next_rot = rotate;
                    automatic logic              moved_by_player = 1'b0;

                    // Step 1: handle player inputs (left/right/rotate)
                    if (left_edge) begin
                        next_x          = active_x - 1;
                        moved_by_player = 1'b1;
                    end else if (right_edge) begin
                        next_x          = active_x + 1;
                        moved_by_player = 1'b1;
                    end else if (rott_edge) begin
                        next_rot        = rotate + 1;
                        moved_by_player = 1'b1;
                    end

                    // Step 2: if player's move is valid, apply it
                    if (moved_by_player &&
                       !check_collision(active_block, next_rot, next_x, active_y)) begin
                        active_x <= next_x;
                        rotate   <= next_rot;
                    end

                    // Step 3: handle downward movement (gravity or soft drop)
                    if (grav_ce || down_edge) begin
                        next_y = active_y + 1;
                        if (!check_collision(active_block, rotate, active_x, next_y)) begin
                            // Move piece down by one row
                            active_y <= next_y;
                        end else begin
                            // Can't move further down → lock piece
                            gm_state <= 3'b011; // LANDED
                        end
                    end
                end

                // --------------------------------------------
                // LANDED: Write piece into gm_memory
                // --------------------------------------------
                3'b011: begin
                    automatic logic [15:0] landed_shape = get_shape(active_block, rotate);

                    for (int i = 0; i < 4; i++) begin
                        for (int j = 0; j < 4; j++) begin
                            automatic int gx = $signed(active_x) + j;
                            automatic int gy = active_y + i;

                            if (landed_shape[15 - (i*4 + j)] &&
                                gy >= 0 && gy < 20 &&
                                gx >= 0 && gx < 10) begin
                                // Store piece ID+1 into the board cell
                                gm_memory[gy][gx] <= active_block + 1;
                            end
                        end
                    end

                    gm_state <= 3'b100; // Go to CLEAR lines
                end

                // --------------------------------------------
                // CLEAR: Remove full lines and update score
                // --------------------------------------------
                3'b100: begin
                    automatic int   write_row     = 19;          // Next row to write from bottom
                    automatic int   lines_cleared = 0;
                    automatic logic [3:0] new_grid [19:0][9:0]; // Temporary cleaned grid

                    // Pass 1: Initialize new_grid to empty
                    for (int i = 0; i < 20; i++) begin
                        for (int j = 0; j < 10; j++) begin
                            new_grid[i][j] = 4'h0;
                        end
                    end

                    // Pass 2: Copy non-full rows from gm_memory to new_grid
                    for (int read_row = 19; read_row >= 0; read_row--) begin
                        automatic bit line_is_full = 1'b1;

                        // Check if this row is full (no zeros)
                        for (int col = 0; col < 10; col++) begin
                            if (gm_memory[read_row][col] == 4'h0)
                                line_is_full = 1'b0;
                        end

                        if (!line_is_full) begin
                            // Copy non-full row to current write_row
                            for (int col = 0; col < 10; col++) begin
                                new_grid[write_row][col] = gm_memory[read_row][col];
                            end
                            write_row = write_row - 1;
                        end else begin
                            // Full row: skip copying and count as cleared
                            lines_cleared = lines_cleared + 1;
                        end
                    end

                    // If any lines cleared, copy new_grid into gm_memory and update score
                    if (lines_cleared > 0) begin
                        gm_memory <= new_grid; // Replace board with collapsed board
                        gm_score  <= gm_score + (lines_cleared * lines_cleared * 100);
                    end

                    // Go back to SPAWN for next piece
                    gm_state <= 3'b001;
                end

                // --------------------------------------------
                // GAME_OVER: Set flag, wait for reset
                // --------------------------------------------
                3'b101: begin
                    game_over <= 1'b1;
                    // Stay here until gm_rst asserted again
                    if (gm_rst) begin
                        gm_state <= 3'b000;
                    end
                end

                // --------------------------------------------
                // Default: fall back to INIT
                // --------------------------------------------
                default: begin
                    gm_state <= 3'b000;
                end
            endcase
        end
    end

    //========================================================
    // Display output composition (grid + active piece overlay)
    //--------------------------------------------------------
    // - Start from gm_memory (locked blocks)
    // - Overlay the current active piece in the correct color
    //   when state is FALLING or SPAWN (preview at spawn)
    // - Drive outputs: grid (to renderer) and score
    //========================================================
    always_comb begin
        // Start from the permanent board state
        automatic logic [3:0] temp_grid [19:0][9:0] = gm_memory;

        // Map active_block type to a color code
        case (active_block)
            3'b000: active_color = 4'b0001;
            3'b001: active_color = 4'b0010;
            3'b010: active_color = 4'b0011;
            3'b011: active_color = 4'b0100;
            3'b100: active_color = 4'b0101;
            3'b101: active_color = 4'b0110;
            3'b110: active_color = 4'b0111;
            default: active_color = 4'b0000;
        endcase

        // Get shape bits for active piece
        shape_map1 = get_shape(active_block, rotate);

        // Overlay active piece on top of board when FALLING or SPAWN
        if (gm_state == 3'b010 || gm_state == 3'b001) begin
            for (int i = 0; i < 4; i++)
                for (int j = 0; j < 4; j++)
                    if (shape_map1[15 - (i*4 + j)] &&
                        active_y + i < 20 &&
                        $signed(active_x) + j >= 0 &&
                        $signed(active_x) + j < 10) begin
                        temp_grid[active_y + i][$signed(active_x) + j] = active_color;
                    end
        end

        // Drive outputs
        grid  = temp_grid;
        score = gm_score;
    end

endmodule
