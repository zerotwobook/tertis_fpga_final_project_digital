// button_input.v
// Reads raw Basys3 buttons, debounces them, and generates
// one-clock-cycle pulses for game control signals.
//
// Mapping (suggested):
//   BTNL -> move_left
//   BTNR -> move_right
//   BTNU -> rotate
//   BTND -> soft_drop
//   BTNC -> hard_drop
//
// All pulses are 1 cycle wide on rising edge of the debounced button.

module button_input #(
    parameter integer DEBOUNCE_CNT_MAX = 1_000_000  // ~10ms at 100MHz
)(
    input  wire clk,     // use 100 MHz system clock
    input  wire reset,   // active-high reset (from SW0)
    input  wire BTNL,
    input  wire BTNR,
    input  wire BTNU,
    input  wire BTND,
    input  wire BTNC,

    output reg  move_left,
    output reg  move_right,
    output reg  rotate,
    output reg  soft_drop,
    output reg  hard_drop
);

    // Debounced signals
    wire BTNL_d;
    wire BTNR_d;
    wire BTNU_d;
    wire BTND_d;
    wire BTNC_d;

    // Instantiate debouncers for each button
    debounce #(.CNT_MAX(DEBOUNCE_CNT_MAX)) u_db_L (
        .clk   (clk),
        .reset (reset),
        .noisy (BTNL),
        .clean (BTNL_d)
    );

    debounce #(.CNT_MAX(DEBOUNCE_CNT_MAX)) u_db_R (
        .clk   (clk),
        .reset (reset),
        .noisy (BTNR),
        .clean (BTNR_d)
    );

    debounce #(.CNT_MAX(DEBOUNCE_CNT_MAX)) u_db_U (
        .clk   (clk),
        .reset (reset),
        .noisy (BTNU),
        .clean (BTNU_d)
    );

    debounce #(.CNT_MAX(DEBOUNCE_CNT_MAX)) u_db_D (
        .clk   (clk),
        .reset (reset),
        .noisy (BTND),
        .clean (BTND_d)
    );

    debounce #(.CNT_MAX(DEBOUNCE_CNT_MAX)) u_db_C (
        .clk   (clk),
        .reset (reset),
        .noisy (BTNC),
        .clean (BTNC_d)
    );

    // Previous state for edge detection
    reg BTNL_prev;
    reg BTNR_prev;
    reg BTNU_prev;
    reg BTND_prev;
    reg BTNC_prev;

    // Generate 1-cycle pulses on rising edge of debounced button
    always @(posedge clk) begin
        if (reset) begin
            BTNL_prev  <= 1'b0;
            BTNR_prev  <= 1'b0;
            BTNU_prev  <= 1'b0;
            BTND_prev  <= 1'b0;
            BTNC_prev  <= 1'b0;

            move_left  <= 1'b0;
            move_right <= 1'b0;
            rotate     <= 1'b0;
            soft_drop  <= 1'b0;
            hard_drop  <= 1'b0;
        end else begin
            // rising edge detection
            move_left  <= BTNL_d & ~BTNL_prev;
            move_right <= BTNR_d & ~BTNR_prev;
            rotate     <= BTNU_d & ~BTNU_prev;
            soft_drop  <= BTND_d & ~BTND_prev;
            hard_drop  <= BTNC_d & ~BTNC_prev;

            // store previous state
            BTNL_prev <= BTNL_d;
            BTNR_prev <= BTNR_d;
            BTNU_prev <= BTNU_d;
            BTND_prev <= BTND_d;
            BTNC_prev <= BTNC_d;
        end
    end

endmodule
