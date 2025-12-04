//============================================================
// VGA Controller (640x480 @ 60Hz)
//------------------------------------------------------------
// Generates:
//  - hsync, vsync timing signals
//  - current pixel coordinates (x_pos, y_pos)
//  - active region flag for visible drawing area
//
// Uses standard VGA timings:
//   Horizontal: 640 visible, 16 front porch, 96 sync, 48 back porch
//   Vertical:   480 visible, 10 front porch, 2 sync, 33 back porch
//
// Pixel clock required: 25.175 MHz (approx 25 MHz acceptable on FPGA)
//============================================================
module vga_controller(
    input  wire clk,            // Pixel clock (usually 25 MHz)
    input  wire rst,            // Asynchronous reset
    output reg  hsync,          // Horizontal sync signal
    output reg  vsync,          // Vertical sync signal
    output reg [9:0] x_pos,     // X coordinate (0–639)
    output reg [9:0] y_pos,     // Y coordinate (0–479)
    output reg  active          // HIGH when pixel is in visible area
);

// ------------------------------------------------------------
// VGA timing parameters for 640x480 resolution
// ------------------------------------------------------------

// Horizontal timing
parameter H_VIS   = 640;                      // Visible region
parameter H_FRONT = 16;                       // Front porch
parameter H_SYNC  = 96;                       // Sync pulse
parameter H_BACK  = 48;                       // Back porch
parameter H_TOTAL = H_VIS + H_FRONT + H_SYNC + H_BACK; // Total pixels per line = 800

// Vertical timing
parameter V_VIS   = 480;                      // Visible region
parameter V_FRONT = 10;                       // Front porch
parameter V_SYNC  = 2;                        // Sync pulse
parameter V_BACK  = 33;                       // Back porch
parameter V_TOTAL = V_VIS + V_FRONT + V_SYNC + V_BACK; // Total lines per frame = 525

// ------------------------------------------------------------
// Counters for horizontal and vertical scanning
// ------------------------------------------------------------
logic [9:0] h_count;    // Horizontal pixel counter   (0–799)
logic [9:0] v_count;    // Vertical line counter      (0–524)

// ------------------------------------------------------------
// Horizontal & Vertical scan counters
// ------------------------------------------------------------
// On every pixel clock:
//  - h_count increments each cycle
//  - When h_count wraps, v_count increments
//  - When v_count wraps, new frame begins
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset both counters to 0
        h_count <= 0;
        v_count <= 0;
    end 
    else begin
        // End of one horizontal line?
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;

            // End of frame?
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end 
        
        // Normal horizontal pixel increment
        else begin
            h_count <= h_count + 1;
        end
    end
end

// ------------------------------------------------------------
// Generate HSYNC and VSYNC signals
// - Sync polarity: Active LOW
// ------------------------------------------------------------

// HSYNC active when h_count is inside sync region
assign hsync = !((h_count >= H_VIS + H_FRONT) &&
                 (h_count <  H_VIS + H_FRONT + H_SYNC));

// VSYNC active when v_count is inside sync region
assign vsync = !((v_count >= V_VIS + V_FRONT) &&
                 (v_count <  V_VIS + V_FRONT + V_SYNC));

// ------------------------------------------------------------
// Visible pixel coordinates
// ------------------------------------------------------------
// If within visible area → output real X/Y
// If in porch or sync area → output 0 (ignored by renderer)
assign x_pos = (h_count < H_VIS) ? h_count : 0;
assign y_pos = (v_count < V_VIS) ? v_count : 0;

// ------------------------------------------------------------
// Active pixel region (HIGH only in visible area)
// ------------------------------------------------------------
assign active = (h_count < H_VIS) && (v_count < V_VIS);

endmodule
