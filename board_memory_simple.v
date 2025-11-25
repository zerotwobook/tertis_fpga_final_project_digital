// board_memory.v (simplified, Vivado-friendly)
// Stores the 10x20 Tetris board (locked blocks)
// Each cell stores a 4-bit color value (0 = empty)

module board_memory (
    input  wire        clk,
    input  wire        reset,

    // Write interface
    input  wire        write_enable,
    input  wire [4:0]  write_row,   // 0..19
    input  wire [3:0]  write_col,   // 0..9
    input  wire [3:0]  write_color, // 4-bit color

    // Row clearing interface (not used yet, kept for compatibility)
    input  wire [19:0] row_clear_mask,
    input  wire        clear_lines,

    // Read interface
    input  wire [4:0]  read_row,
    input  wire [3:0]  read_col,
    output reg  [3:0]  cell_color
);

    // 20 rows, 10 columns
    reg [3:0] board [0:19][0:9];

    integer r, c;

    always @(posedge clk) begin
        if (reset) begin
            for (r = 0; r < 20; r = r + 1)
                for (c = 0; c < 10; c = c + 1)
                    board[r][c] <= 4'b0000;
        end else begin
            // write cell
            if (write_enable) begin
                if (write_row < 20 && write_col < 10)
                    board[write_row][write_col] <= write_color;
            end

            // clear_lines not implemented in this simple version;
            // signals are ignored but kept in interface so that
            // future versions can add real line clearing.
        end
    end

    always @(*) begin
        if (read_row < 20 && read_col < 10)
            cell_color = board[read_row][read_col];
        else
            cell_color = 4'b0000;
    end

endmodule
