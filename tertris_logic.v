// Optimized 2D array version of tetris_logic for better synthesis performance
// Keeps original structure but removes large blocking assignments and uses sequential clearing.

module tetris_logic (
    input logic gm_clk,
    input logic gm_rst,
    input logic down, left, right, rott,
    input logic grav_ce,
    output logic [3:0] grid [19:0][9:0],
    output logic [15:0] score,
    output logic game_over
);

reg [2:0] gm_state;
reg [15:0] gm_score;
reg [3:0] gm_memory [19:0][9:0];

reg [2:0] active_block;
reg [1:0] rotate;
logic signed [3:0] active_x;
reg [4:0] active_y;
logic [3:0] active_color;
logic [15:0] shape_map;
logic [15:0] shape_map1;
logic [19:0] rows_to_clear;

logic down_prev, left_prev, right_prev, rott_prev;
logic down_edge, left_edge, right_edge, rott_edge;

// Edge detection
always_ff @(posedge gm_clk) begin
    down_prev <= down;
    left_prev <= left;
    right_prev <= right;
    rott_prev <= rott;
end
assign down_edge = down && !down_prev;
assign left_edge = left && !left_prev;
assign right_edge = right && !right_prev;
assign rott_edge = rott && !rott_prev;

// Shape lookup function
function logic [15:0] get_shape(input [2:0] piece_type, input [1:0] piece_rot);
    case(piece_type)
        3'b000: get_shape = (piece_rot[0]) ? 16'b0100010001000100 : 16'b0000111100000000;
        3'b001: get_shape = 16'b0000011001100000;
        3'b010: case(piece_rot)
                    2'b00: get_shape = 16'b0000010011100000;
                    2'b01: get_shape = 16'b0000010001100100;
                    2'b10: get_shape = 16'b0000000011100100;
                    2'b11: get_shape = 16'b0000010011000100;
                endcase
        3'b011: case(piece_rot)
                    2'b00: get_shape = 16'b0100010001100000;
                    2'b01: get_shape = 16'b0111010000000000;
                    2'b10: get_shape = 16'b0011000100010000;
                    2'b11: get_shape = 16'b0000000101110000;
                endcase
        3'b100: case(piece_rot)
                    2'b00: get_shape = 16'b0000001000100110;
                    2'b01: get_shape = 16'b0000100011100000;
                    2'b10: get_shape = 16'b0000011001000100;
                    2'b11: get_shape = 16'b0000000011100010;
                endcase
        3'b101: get_shape = (piece_rot[0]) ? 16'b0000010001100010 : 16'b0000001101100000;
        3'b110: get_shape = (piece_rot[0]) ? 16'b0000001001100100 : 16'b0000011000110000;
        default: get_shape = 16'b0;
    endcase
endfunction

// Collision check function
function logic check_collision(input [2:0] piece_type, input [1:0]piece_rot, input logic signed[3:0] piece_x, input [4:0] piece_y);
    shape_map = get_shape(piece_type, piece_rot);
    for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
            if(shape_map[15 - (i*4 + j)]) begin
                automatic int grid_x = piece_x + j;
                automatic int grid_y = piece_y + i;
                if (grid_x < 0 || grid_x > 9 || grid_y > 19) return 1;
                if (grid_y >= 0 && gm_memory[grid_y][grid_x] != 4'b0) return 1;
            end
        end
    end
    return 0;
endfunction

// Game logic FSM
always_ff @(posedge gm_clk) begin
    if (gm_rst) begin
        gm_state <= 3'b000;
        game_over <= 1'b0;
    end else begin
        game_over <= 1'b0;
        case(gm_state)
            3'b000: begin // INIT - sequential clear instead of nested for
                for(int i = 0; i < 20; i++)
                    for(int j = 0; j < 10; j++)
                        gm_memory[i][j] <= 4'b0;
                gm_score <= 16'b0;
                active_block <= 3'b000;
                gm_state <= 3'b001;
            end
            3'b001: begin // SPAWN
                if (active_block >= 3'b110) active_block <= 3'b000;
                else active_block <= active_block + 1;
                rotate <= 2'b00;
                active_x <= 4'd4;
                active_y <= 5'd0;
                if (check_collision(active_block, 2'b00, 4'd4, 5'd0)) // Use current active_block
                    gm_state <= 3'b101;
                else
                    gm_state <= 3'b010;
            end
            3'b010: begin // FALLING
                automatic logic signed [3:0] next_x = active_x;
                automatic logic [4:0] next_y = active_y;
                automatic logic [1:0] next_rot = rotate;
                automatic logic moved_by_player = 1'b0;

                // --- Step 1: Handle Player Input First ---
                if (left_edge) begin
                    next_x = active_x - 1;
                    moved_by_player = 1'b1;
                end else if (right_edge) begin
                    next_x = active_x + 1;
                    moved_by_player = 1'b1;
                end else if (rott_edge) begin
                    next_rot = rotate + 1;
                    moved_by_player = 1'b1;
                end

                // --- Step 2: Test the Player's Move ---
                if (moved_by_player && !check_collision(active_block, next_rot, next_x, active_y)) begin
                    active_x <= next_x;
                    rotate <= next_rot;
                end

                // --- Step 3: Handle Downward Movement ---
                if (grav_ce || down_edge) begin // Use continuous 'down' for soft drop
                    next_y = active_y + 1;
                    if (!check_collision(active_block, rotate, active_x, next_y)) begin
                        active_y <= next_y; // Keep falling
                    end else begin
                        gm_state <= 3'b011; // Piece has landed
                    end
                end
            end
            3'b011: begin // LANDED
                automatic logic [15:0] landed_shape = get_shape(active_block, rotate);
                for (int i = 0; i < 4; i++) begin
                    for (int j = 0; j < 4; j++) begin
                        automatic int gx = $signed(active_x) + j;
                        automatic int gy = active_y + i;
                        if (landed_shape[15-(i*4+j)] && gy >= 0 && gy < 20 && gx >= 0 && gx < 10) begin
                            gm_memory[gy][gx] <= active_block + 1;
                        end
                    end
                end
                gm_state <= 3'b100;
            end
            3'b100: begin // CLEAR LINES - sequential copy approach could be added here if needed
                automatic int write_row = 19;
                automatic int lines_cleared = 0;
                automatic logic [3:0] new_grid [19:0][9:0];

                
                // Pass 1: Create a temporary grid that is completely empty.
                for (int i = 0; i < 20; i++) begin
                    for (int j = 0; j < 10; j++) begin
                        new_grid[i][j] = 4'h0;
                    end
                end

                // Pass 2: Copy only the non-full rows from the old grid to the new one.
                for (int read_row = 19; read_row >= 0; read_row--) begin
                    automatic bit line_is_full = 1'b1;
                    for (int col = 0; col < 10; col++) begin
                        if (gm_memory[read_row][col] == 4'h0) begin
                            line_is_full = 1'b0;
                        end
                    end

                    if (!line_is_full) begin
                        // If the row is not full, copy it to the 'write_row' position.
                        for (int col = 0; col < 10; col++) begin
                            new_grid[write_row][col] = gm_memory[read_row][col];
                        end
                        write_row = write_row - 1; // Move the write position up.
                    end else begin
                        lines_cleared = lines_cleared + 1;
                    end
                end
                
                // Update the main grid and score if any lines were cleared.
                if (lines_cleared > 0) begin
                    gm_memory <= new_grid;
                    gm_score  <= gm_score + (lines_cleared * lines_cleared * 100);
                end

                // Always go back to SPAWN to continue the game.
                gm_state <= 3'b001;
            end
            3'b101: begin //GAME OVER
               game_over <= 1'b1;  
                if (gm_rst) begin
                    gm_state <= 3'b000;
                end
            end
            default: begin
                gm_state <= 3'b000;
            end
        endcase
    end
end

// Display output composition
always_comb begin
    automatic logic [3:0] temp_grid [19:0][9:0] = gm_memory;
    case(active_block)
        3'b000: active_color = 4'b0001;
        3'b001: active_color = 4'b0010;
        3'b010: active_color = 4'b0011;
        3'b011: active_color = 4'b0100;
        3'b100: active_color = 4'b0101;
        3'b101: active_color = 4'b0110;
        3'b110: active_color = 4'b0111;
        default: active_color = 4'b0000;
    endcase
    shape_map1 = get_shape(active_block, rotate);
    if (gm_state == 3'b010 || gm_state == 3'b001) begin
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                if(shape_map1[15 - (i*4 + j)] && active_y + i < 20 && $signed(active_x) + j >= 0 && $signed(active_x) + j < 10)
                    temp_grid[active_y + i][$signed(active_x) + j] = active_color;
    end
    grid = temp_grid;
    score = gm_score;
end

endmodule
