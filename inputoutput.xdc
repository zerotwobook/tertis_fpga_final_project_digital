##========================================================
## Clock 100 MHz
##========================================================
set_property PACKAGE_PIN W5 [get_ports {CLK100MHZ}]
set_property IOSTANDARD LVCMOS33 [get_ports {CLK100MHZ}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK100MHZ}]

##========================================================
## Switches (SW0 used as reset)
##========================================================
set_property PACKAGE_PIN V17 [get_ports {SW0}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW0}]

##========================================================
## Buttons (BTNL/BTNR/BTNU/BTND/BTNC)
## Basys3 mapping:
##   btnL -> W19
##   btnR -> T17
##   btnU -> T18
##   btnD -> U17
##   btnC -> U18
##========================================================
set_property PACKAGE_PIN W19 [get_ports {BTNL}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTNL}]

set_property PACKAGE_PIN T17 [get_ports {BTNR}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTNR}]

set_property PACKAGE_PIN T18 [get_ports {BTNU}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTNU}]

set_property PACKAGE_PIN U17 [get_ports {BTND}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTND}]

set_property PACKAGE_PIN U18 [get_ports {BTNC}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTNC}]

##========================================================
## VGA Connector
## Basys3 mapping:
##   vgaRed[0..3]   -> G19 H19 J19 N19
##   vgaGreen[0..3] -> J17 H17 G17 D17
##   vgaBlue[0..3]  -> N18 L18 K18 J18
##   Hsync          -> P19
##   Vsync          -> R19
##========================================================

## Red
set_property PACKAGE_PIN G19 [get_ports {VGA_R[0]}]
set_property PACKAGE_PIN H19 [get_ports {VGA_R[1]}]
set_property PACKAGE_PIN J19 [get_ports {VGA_R[2]}]
set_property PACKAGE_PIN N19 [get_ports {VGA_R[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[*]}]

## Green
set_property PACKAGE_PIN J17 [get_ports {VGA_G[0]}]
set_property PACKAGE_PIN H17 [get_ports {VGA_G[1]}]
set_property PACKAGE_PIN G17 [get_ports {VGA_G[2]}]
set_property PACKAGE_PIN D17 [get_ports {VGA_G[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[*]}]

## Blue
set_property PACKAGE_PIN N18 [get_ports {VGA_B[0]}]
set_property PACKAGE_PIN L18 [get_ports {VGA_B[1]}]
set_property PACKAGE_PIN K18 [get_ports {VGA_B[2]}]
set_property PACKAGE_PIN J18 [get_ports {VGA_B[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[*]}]

## Sync
set_property PACKAGE_PIN P19 [get_ports {VGA_HS}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_HS}]

set_property PACKAGE_PIN R19 [get_ports {VGA_VS}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_VS}]

##========================================================
## Seven Segment Display
## Basys3 mapping (common anode):
##   seg[0..6] -> W7 W6 U8 V8 U5 V5 U7
##   dp        -> V7   (ไม่ได้ใช้ในโปรเจกต์นี้)
##   an[0..3]  -> U2 U4 V4 W4
##========================================================

## Segments a–g
set_property PACKAGE_PIN W7 [get_ports {SEG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[0]}]

set_property PACKAGE_PIN W6 [get_ports {SEG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[1]}]

set_property PACKAGE_PIN U8 [get_ports {SEG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[2]}]

set_property PACKAGE_PIN V8 [get_ports {SEG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[3]}]

set_property PACKAGE_PIN U5 [get_ports {SEG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[4]}]

set_property PACKAGE_PIN V5 [get_ports {SEG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[5]}]

set_property PACKAGE_PIN U7 [get_ports {SEG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[6]}]

## Anodes
set_property PACKAGE_PIN U2 [get_ports {AN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]

set_property PACKAGE_PIN U4 [get_ports {AN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]

set_property PACKAGE_PIN V4 [get_ports {AN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]

set_property PACKAGE_PIN W4 [get_ports {AN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]

##========================================================
## LED0 (optional status LED)
## Basys3 mapping: led[0] -> U16
##========================================================
set_property PACKAGE_PIN U16 [get_ports {LED0}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED0}]
