# tertis_fpga_final_project_digital
This github for share my project with my friend
Using broad basys 3 (XC7A35TICPG236C-1l)

#  Tetris Game — How to Play (FPGA/Basys3 Version)

This document explains how to start, play, restart, and exit the FPGA-based Tetris game on the Basys3 board.  
Everything runs fully in hardware using Verilog modules (no CPU or software).

---

## Starting the Game

1. Power on the **Basys3 board**.
2. Connect the board to a **VGA monitor**.
3. After programming the bitstream, the VGA screen shows the **Title Screen**:

- **TETRIS**
- **CPE222 FINAL PROJECT**
- **TURN ON SW0 TO START THE GAME**

4. To begin:
   - Flip **SW0 → ON**  
   → The game enters PLAY mode immediately.

---

## Controls

| Action | Input (Basys3) |
|--------|----------------|
| Move left | BTN **L** |
| Move right | BTN **R** |
| Rotate piece | BTN **U** |
| Soft drop | BTN **D** |
| Start game (from title screen) | **SW0 ON** |
| Restart after Game Over | **SW0 OFF → ON** or **BTNC** (if available) |
| Exit game | **SW0 + BTNC** (if exit version is used) |

All button inputs pass through a hardware debouncer for clean and accurate control.

---

## Gameplay Rules

### 1. Falling Tetrominoes
- A random piece appears at the **top center** of the playfield.
- It falls automatically due to the gravity clock.
- Use the buttons to move or rotate the piece.

### 2. Locking a Piece
A piece stops and becomes part of the board when:
- It cannot move downward anymore.

### 3. Line Clearing
If a horizontal row is completely filled:
- That row clears.
- All above rows drop down.
- You gain points.

### 4. Scoring System


| Lines Cleared | Points |
|---------------|--------|
| 1 | 100 |
| 2 | 400 |
| 3 | 900 |
| 4 | 1600 |

Your current score is shown on the **7-segment display**.

---

## Game Over

The game ends when:
- A new tetromino **cannot be placed** at the spawn position.

When this happens:
- The screen shows **GAME OVER** in the center.
- The board freezes.
- The game waits for a restart command.

### Restart Options

####  Option A — Restart using SW0  
1. Flip **SW0 OFF**  
2. Flip **SW0 ON**  
→ Game restarts from INIT state.

####  Option B — Restart using BTNC  
If your version supports BTNC as restart:
- Press **BTNC**  
→ Game returns to the SPAWN state.

---

## Exiting the Game (QUIT)

Depending on your Tetris version, EXIT may be supported.

###  Exit Method 1 — SW0 + BTNC (if implemented)
If your rendered screen shows something like:
- `"SW0 + BTNC EXIT"`

Then your game supports:


This command:
- Stops the game logic  
- Clears the board  
- Returns to a blank/idle display  

###  Exit Method 2 — Power switch (always works)
You can always leave the game by:
- Turning off the **Basys3 power switch**

###  Exit Method 3 — Reprogramming the FPGA
Uploading a new bitstream immediately exits the game.

---

##  Display Information

- VGA Resolution: **640 × 480**
- Playfield Grid: **10 × 20** blocks
- Block Size: **24 × 24 pixels**
- Grid rendering uses the `block_renderer` module.
- Title and Game Over text uses custom **5×7 bitmap fonts**.

---

##  Internal Architecture (Short Summary)

The game uses a hardware FSM with the following states:


### Major Modules:

| Module | Description |
|--------|-------------|
| `tetris_logic` | The entire game engine (movement, gravity, collision, scoring, FSM) |
| `vga_controller` | Generates sync signals & pixel counters |
| `block_renderer` | Draws the blocks onto the VGA screen |
| `title_renderer` | Displays the title screen text |
| `game_over_renderer` | Displays “GAME OVER” |
| `score_display` | Shows score on 7-segment display |
| `debounce` | Cleans button input noise |
| `clock_divider` | Generates slow clocks for gravity, input, and VGA |
