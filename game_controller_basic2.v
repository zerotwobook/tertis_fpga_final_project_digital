// game_controller.v
// Basic Tetris controller (T, O, I) + stacking (check collision with locked blocks)
// Fast-synthesis version (no big loops for hard drop)

module game_controller (
    input  wire        clk,
    input  wire        reset,
    input  wire        game_tick,

    // Controls
    input  wire        move_left,
    input  wire        move_right,
    input  wire        rotate,
    input  wire        soft_drop,
    input  wire        hard_drop,

    // Interface to board_memory.v
    output reg         write_enable,
    output reg  [4:0]  write_row,
    output reg  [3:0]  write_col,
    output reg  [3:0]  write_color,

    output reg         clear_lines,
    output reg [19:0]  row_clear_mask,

    // Query for current falling piece (for renderer)
    input  wire [4:0]  query_row,
    input  wire [3:0]  query_col,
    output reg  [3:0]  active_color
);

    // -------------------------------
    // State
    // -------------------------------
    localparam S_FALL   = 2'd0;
    localparam S_LOCK   = 2'd1;
    localparam S_HDROP  = 2'd2;   // hard drop ลงล่างสุดในหลาย clock

    reg [1:0] state;

    // piece info (ตัวที่กำลังตก)
    reg [1:0] piece_type;   // 0=T, 1=O, 2=I
    reg [1:0] rot;
    reg [4:0] pos_row;
    reg [3:0] pos_col;

    // board ที่ใช้เช็คชน (เก็บเฉพาะบล็อกที่ล็อกแล้ว)
    reg [3:0] board2 [0:19][0:9];   // 20x10, 4-bit color
    integer i, j;

    // ข้อมูลตอนเริ่ม lock (ล็อกที่ตำแหน่งไหน, ชิ้นอะไร)
    reg [4:0] lock_row_base;
    reg [3:0] lock_col_base;
    reg [1:0] lock_piece_type;
    reg [1:0] lock_rot;
    reg [15:0] lock_shape;

    // ตัววิ่งสำหรับ lock ทีละช่อง
    reg [1:0] lock_r;
    reg [1:0] lock_c;

    // สำหรับ active_color
    reg [15:0] shape_q;
    reg [4:0]  qrow_off;
    reg [3:0]  qcol_off;

    // -------------------------------
    // Shapes
    // -------------------------------
    // T piece
    localparam [15:0] T_R0 = 16'b0000_0111_0010_0000;
    localparam [15:0] T_R1 = 16'b0000_0100_0110_0100;
    localparam [15:0] T_R2 = 16'b0000_0010_0111_0000;
    localparam [15:0] T_R3 = 16'b0000_0100_1100_0100;

    // O piece
    localparam [15:0] O_R0 = 16'b0000_0110_0110_0000;

    // I piece
    localparam [15:0] I_R0 = 16'b0000_1111_0000_0000;
    localparam [15:0] I_R1 = 16'b0010_0010_0010_0010;

    // -------------------------------
    // Functions
    // -------------------------------
    function [3:0] color_for_piece;
        input [1:0] t;
        begin
            case(t)
                2'd0: color_for_piece = 4'hD; // T - magenta
                2'd1: color_for_piece = 4'hE; // O - yellow
                2'd2: color_for_piece = 4'hC; // I - cyan
                default: color_for_piece = 4'hF;
            endcase
        end
    endfunction

    function [15:0] get_shape;
        input [1:0] t;
        input [1:0] rsel;
        begin
            case(t)
                2'd0: begin // T
                    case(rsel)
                        2'd0: get_shape = T_R0;
                        2'd1: get_shape = T_R1;
                        2'd2: get_shape = T_R2;
                        2'd3: get_shape = T_R3;
                        default: get_shape = T_R0;
                    endcase
                end
                2'd1: begin // O
                    get_shape = O_R0;
                end
                2'd2: begin // I
                    case(rsel)
                        2'd0: get_shape = I_R0;
                        2'd1: get_shape = I_R1;
                        2'd2: get_shape = I_R0;
                        2'd3: get_shape = I_R1;
                        default: get_shape = I_R0;
                    endcase
                end
                default: get_shape = 16'h0000;
            endcase
        end
    endfunction

    function get_block;
        input [15:0] shape;
        input [1:0]  rr;
        input [1:0]  cc;
        begin
            get_block = shape[15 - (rr*4 + cc)];
        end
    endfunction

    // เช็คชนทั้งขอบ + บล็อกใน board2
    function collision_bounds;
        input [4:0] new_row;
        input [3:0] new_col;
        reg [15:0] s;
        integer rr, cc;
        reg [4:0] tr;
        reg [3:0] tc;
        begin
            collision_bounds = 0;
            s = get_shape(piece_type, rot);

            for (rr=0; rr<4; rr=rr+1) begin
                for (cc=0; cc<4; cc=cc+1) begin
                    if (get_block(s, rr[1:0], cc[1:0])) begin
                        tr = new_row + rr[4:0];
                        tc = new_col + cc[3:0];

                        // ขอบจอ
                        if (tc >= 10)
                            collision_bounds = 1;
                        else if (tr >= 20)
                            collision_bounds = 1;
                        else begin
                            // ชนบล็อกที่ล็อกแล้ว
                            if (board2[tr][tc] != 4'b0000)
                                collision_bounds = 1;
                        end
                    end
                end
            end
        end
    endfunction

    // -------------------------------
    // Spawn next piece
    // -------------------------------
    task spawn_piece;
        begin
            pos_row <= 0;
            pos_col <= 3;
            rot     <= 0;

            if (piece_type == 2)
                piece_type <= 0;
            else
                piece_type <= piece_type + 1;
        end
    endtask

    // -------------------------------
    // Main sequential logic (FSM)
    // -------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state         <= S_FALL;
            piece_type    <= 2'd0;
            rot           <= 2'd0;
            pos_row       <= 5'd0;
            pos_col       <= 4'd3;
            write_enable  <= 1'b0;
            clear_lines   <= 1'b0;
            row_clear_mask<= 20'd0;
            lock_r        <= 2'd0;
            lock_c        <= 2'd0;
            // เคลียร์ board2
            for (i=0; i<20; i=i+1)
                for (j=0; j<10; j=j+1)
                    board2[i][j] <= 4'b0000;
        end else begin
            write_enable   <= 1'b0;
            clear_lines    <= 1'b0;
            row_clear_mask <= 20'd0;

            case (state)
                // -----------------------
                // ช่วงปกติ: บล็อกกำลังตก
                // -----------------------
                S_FALL: begin
                    // ซ้าย/ขวา
                     if (move_left) begin
                        if (pos_col > 0 && !collision_bounds(pos_row, pos_col - 1))
                            pos_col <= pos_col - 1;
                    end

                    if (move_left && !collision_bounds(pos_row, pos_col - 1))
        pos_col <= pos_col - 1;

    if (move_right && !collision_bounds(pos_row, pos_col + 1))
        pos_col <= pos_col + 1;

    // หมุน
    if (rotate)
        rot <= rot + 1'b1;

                    // ตกเอง + soft drop
                    if (game_tick || soft_drop) begin
                        if (collision_bounds(pos_row + 1, pos_col)) begin
                            // เริ่ม lock
                            state          <= S_LOCK;
                            lock_row_base  <= pos_row;
                            lock_col_base  <= pos_col;
                            lock_piece_type<= piece_type;
                            lock_rot       <= rot;
                            lock_shape     <= get_shape(piece_type, rot);
                            lock_r         <= 2'd0;
                            lock_c         <= 2'd0;
                        end else begin
                            pos_row <= pos_row + 1;
                        end
                    end

                    // hard drop: เข้า state S_HDROP
                    if (hard_drop) begin
                        state <= S_HDROP;
                    end
                end

                // -----------------------
                // Hard drop: เคลื่อนลงเรื่อย ๆ จนชน แล้วค่อย lock
                // -----------------------
                S_HDROP: begin
                    if (collision_bounds(pos_row + 1, pos_col)) begin
                        // ถึงจุดต่ำสุดแล้ว → ไป lock
                        state          <= S_LOCK;
                        lock_row_base  <= pos_row;
                        lock_col_base  <= pos_col;
                        lock_piece_type<= piece_type;
                        lock_rot       <= rot;
                        lock_shape     <= get_shape(piece_type, rot);
                        lock_r         <= 2'd0;
                        lock_c         <= 2'd0;
                    end else begin
                        // ยังไปต่อได้ → ขยับลง 1 แถว
                        pos_row <= pos_row + 1;
                    end
                end

                // -----------------------
                // ช่วง lock: เขียนลง board ทีละช่อง
                // -----------------------
                S_LOCK: begin
                    // เขียนทีละช่องลง board_memory + board2
                    if (get_block(lock_shape, lock_r, lock_c)) begin
                        write_enable <= 1'b1;
                        write_row    <= lock_row_base + lock_r;
                        write_col    <= lock_col_base + lock_c;
                        write_color  <= color_for_piece(lock_piece_type);

                        if ((lock_row_base + lock_r) < 20 &&
                            (lock_col_base + lock_c) < 10)
                            board2[lock_row_base + lock_r]
                                  [lock_col_base + lock_c] <= color_for_piece(lock_piece_type);
                    end

                    // เดิน index 4x4
                    if (lock_c == 2'd3) begin
                        lock_c <= 2'd0;
                        if (lock_r == 2'd3) begin
                            // เขียนครบ 4x4 แล้ว → กลับไป FALL พร้อมชิ้นใหม่
                            state <= S_FALL;
                            spawn_piece();
                        end else begin
                            lock_r <= lock_r + 1'b1;
                        end
                    end else begin
                        lock_c <= lock_c + 1'b1;
                    end
                end

                default: begin
                    state <= S_FALL;
                end
            endcase
        end
    end

    // -------------------------------
    // Active color สำหรับ renderer
    // -------------------------------
    always @(*) begin
        shape_q      = get_shape(piece_type, rot);
        active_color = 4'h0;
        qrow_off     = query_row - pos_row;
        qcol_off     = query_col - pos_col;

        if (query_row >= pos_row && query_row < pos_row + 4 &&
            query_col >= pos_col && query_col < pos_col + 4) begin
            if (get_block(shape_q, qrow_off[1:0], qcol_off[1:0]))
                active_color = color_for_piece(piece_type);
        end
    end

endmodule
