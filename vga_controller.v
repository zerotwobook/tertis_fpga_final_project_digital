// vga_controller.v
// VGA 640x480 @ 60Hz timing generator for Basys3 Tetris project
//
// Outputs:
//  - hcount, vcount : current pixel position
//  - hsync, vsync   : sync pulses
//  - video_on       : high when in visible area
//  - pixel_tick     : 1 tick per pixel (same as 25 MHz clock)

module vga_controller(
    input  wire clk_25mhz,   // 25 MHz pixel clock
    input  wire reset,       // active-high reset
    output reg  [9:0] hcount, // 0-799
    output reg  [9:0] vcount, // 0-524
    output wire hsync,
    output wire vsync,
    output wire video_on,
    output wire pixel_tick
);

    assign pixel_tick = 1'b1; // always tick every 25MHz cycle

    // VGA 640x480 @ 60Hz timing
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_MAX     = H_VISIBLE + H_FRONT + H_SYNC + H_BACK - 1; // 799

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_MAX     = V_VISIBLE + V_FRONT + V_SYNC + V_BACK - 1; // 524

    // Horizontal counter
    always @(posedge clk_25mhz) begin
        if (reset) begin
            hcount <= 0;
        end else begin
            if (hcount == H_MAX)
                hcount <= 0;
            else
                hcount <= hcount + 1;
        end
    end

    // Vertical counter
    always @(posedge clk_25mhz) begin
        if (reset) begin
            vcount <= 0;
        end else begin
            if (hcount == H_MAX) begin
                if (vcount == V_MAX)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end
        end
    end

    // Sync signals (active low)
    assign hsync = ~((hcount >= (H_VISIBLE + H_FRONT)) &&
                     (hcount <  (H_VISIBLE + H_FRONT + H_SYNC)));

    assign vsync = ~((vcount >= (V_VISIBLE + V_FRONT)) &&
                     (vcount <  (V_VISIBLE + V_FRONT + V_SYNC)));

    // Video on when inside visible region
    assign video_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);

endmodule
