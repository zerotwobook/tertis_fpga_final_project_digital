module block_renderer (
    input logic [9:0] curr_pix_x,
    input logic [9:0] curr_pix_y,
    input logic [3:0] game_grid_array [19:0][9:0],
    output logic [11:0] pixel_color
);

parameter BLOCK_SIZE = 24;
parameter GRID_START_X = 200;
parameter GRID_WIDTH = 240;
parameter GRID_HEIGHT = 480;
parameter GRID_BORDER = 4;

logic [3:0] cell_x;
assign cell_x = (curr_pix_x - GRID_START_X) / BLOCK_SIZE;
logic [4:0] cell_y;
assign cell_y = curr_pix_y / BLOCK_SIZE;
logic [3:0] cell_color;

always_comb begin
    if((curr_pix_x >= GRID_START_X - GRID_BORDER && curr_pix_x < GRID_START_X) || (curr_pix_x >= GRID_START_X + GRID_WIDTH && curr_pix_x < GRID_START_X + GRID_WIDTH + GRID_BORDER) || (curr_pix_y >= 0 && curr_pix_y < GRID_BORDER) || (curr_pix_y >= GRID_HEIGHT && curr_pix_y < GRID_HEIGHT + GRID_BORDER)) begin
            pixel_color = 12'h000; // Border color
    end else if (curr_pix_x >= GRID_START_X && curr_pix_x < GRID_START_X + GRID_WIDTH) begin
        cell_color = game_grid_array[cell_y][cell_x];
        case(cell_color)
    4'h0: pixel_color = 12'hFFF; 
    4'h1: pixel_color = 12'h000; 
    4'h2: pixel_color = 12'h000; 
    4'h3: pixel_color = 12'h000;
    4'h4: pixel_color = 12'h000;
    4'h5: pixel_color = 12'h000;
    4'h6: pixel_color = 12'h000;
    4'h7: pixel_color = 12'h000;
    default: pixel_color = 12'hFFF;
endcase

    end else begin
        pixel_color = 12'hFFF; // Outside grid area color
    end
end

endmodule