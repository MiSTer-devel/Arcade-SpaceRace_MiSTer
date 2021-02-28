//============================================================================
//  Arcade "Space Race" (Arari, 1973) for MiSTer.
//  Based on Rev.F schematics
//
//  Copyright (c) 2021 bellwood420
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
  //Master input clock
  input         CLK_50M,

  //Async reset from top-level module.
  //Can be used as initial reset.
  input         RESET,

  //Must be passed to hps_io module
  inout  [45:0] HPS_BUS,

  //Base video clock. Usually equals to CLK_SYS.
  output        CLK_VIDEO,

  //Multiple resolutions are supported using different CE_PIXEL rates.
  //Must be based on CLK_VIDEO
  output        CE_PIXEL,

  //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
  //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
  output [12:0] VIDEO_ARX,
  output [12:0] VIDEO_ARY,

  output  [7:0] VGA_R,
  output  [7:0] VGA_G,
  output  [7:0] VGA_B,
  output        VGA_HS,
  output        VGA_VS,
  output        VGA_DE,    // = ~(VBlank | HBlank)
  output        VGA_F1,
  output [1:0]  VGA_SL,
  output        VGA_SCALER, // Force VGA scaler

  input  [11:0] HDMI_WIDTH,
  input  [11:0] HDMI_HEIGHT,

`ifdef USE_FB
  // Use framebuffer in DDRAM (USE_FB=1 in qsf)
  // FB_FORMAT:
  //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
  //    [3]   : 0=16bits 565 1=16bits 1555
  //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
  //
  // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
  output        FB_EN,
  output  [4:0] FB_FORMAT,
  output [11:0] FB_WIDTH,
  output [11:0] FB_HEIGHT,
  output [31:0] FB_BASE,
  output [13:0] FB_STRIDE,
  input         FB_VBL,
  input         FB_LL,
  output        FB_FORCE_BLANK,

  // Palette control for 8bit modes.
  // Ignored for other video modes.
  output        FB_PAL_CLK,
  output  [7:0] FB_PAL_ADDR,
  output [23:0] FB_PAL_DOUT,
  input  [23:0] FB_PAL_DIN,
  output        FB_PAL_WR,
`endif

  output        LED_USER,  // 1 - ON, 0 - OFF.

  // b[1]: 0 - LED status is system status OR'd with b[0]
  //       1 - LED status is controled solely by b[0]
  // hint: supply 2'b00 to let the system control the LED.
  output  [1:0] LED_POWER,
  output  [1:0] LED_DISK,

  // I/O board button press simulation (active high)
  // b[1]: user button
  // b[0]: osd button
  output  [1:0] BUTTONS,

  input         CLK_AUDIO, // 24.576 MHz
  output [15:0] AUDIO_L,
  output [15:0] AUDIO_R,
  output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
  output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

  //ADC
  inout   [3:0] ADC_BUS,

  //SD-SPI
  output        SD_SCK,
  output        SD_MOSI,
  input         SD_MISO,
  output        SD_CS,
  input         SD_CD,

`ifdef USE_DDRAM
  //High latency DDR3 RAM interface
  //Use for non-critical time purposes
  output        DDRAM_CLK,
  input         DDRAM_BUSY,
  output  [7:0] DDRAM_BURSTCNT,
  output [28:0] DDRAM_ADDR,
  input  [63:0] DDRAM_DOUT,
  input         DDRAM_DOUT_READY,
  output        DDRAM_RD,
  output [63:0] DDRAM_DIN,
  output  [7:0] DDRAM_BE,
  output        DDRAM_WE,
`endif

`ifdef USE_SDRAM
  //SDRAM interface with lower latency
  output        SDRAM_CLK,
  output        SDRAM_CKE,
  output [12:0] SDRAM_A,
  output  [1:0] SDRAM_BA,
  inout  [15:0] SDRAM_DQ,
  output        SDRAM_DQML,
  output        SDRAM_DQMH,
  output        SDRAM_nCS,
  output        SDRAM_nCAS,
  output        SDRAM_nRAS,
  output        SDRAM_nWE,
`endif

`ifdef DUAL_SDRAM
  //Secondary SDRAM
  input         SDRAM2_EN,
  output        SDRAM2_CLK,
  output [12:0] SDRAM2_A,
  output  [1:0] SDRAM2_BA,
  inout  [15:0] SDRAM2_DQ,
  output        SDRAM2_nCS,
  output        SDRAM2_nCAS,
  output        SDRAM2_nRAS,
  output        SDRAM2_nWE,
`endif

  input         UART_CTS,
  output        UART_RTS,
  input         UART_RXD,
  output        UART_TXD,
  output        UART_DTR,
  input         UART_DSR,

  // Open-drain User port.
  // 0 - D+/RX
  // 1 - D-/TX
  // 2..6 - USR2..USR6
  // Set USER_OUT to 1 to read from USER_IN.
  input   [6:0] USER_IN,
  output  [6:0] USER_OUT,

  input         OSD_STATUS
);

///////////////////////////////////////////////////////////////////////////////////////////
//    Default values for ports not used in this core
//////////////////////////////////////////////////////////////////////////////////////////
assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
//assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign LED_DISK = 0;
assign LED_POWER = 0;
//assign LED_USER = 0;
assign BUTTONS = 0;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;

///////////////////////////////////////////////////////////////////////////////////////////
//    CONF STR
///////////////////////////////////////////////////////////////////////////////////////////
`include "build_id.v"
localparam CONF_STR = {
  "A.SPACERACE;;",
  "-;",
  "H0O23,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
  "O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
  "-;",
  "DIP;",
  "-;",
  "R0,Reset;",
  "J1,Coin,Start;",
  "jn,R,Start;",
  "V,v",`BUILD_DATE
};

/////////////////////////////////////////////////////////////////////////
//      CLOCKS
/////////////////////////////////////////////////////////////////////////
wire clk_sys;
pll pll
(
  .refclk(CLK_50M),
  .rst(0),
  .outclk_0(clk_sys) // System clock - 57.272 MHz
);

// Source clock - 14.318 MHz for source of main clock
reg CLK_SRC;
always @(posedge clk_sys) begin
  reg [1:0]  div;
  div <= div + 2'd1;
  CLK_SRC <= div[1];
end

// Reset signal
wire reset = RESET | status[0] | buttons[1];

/////////////////////////////////////////////////////////////////////////
//      HPS IO
/////////////////////////////////////////////////////////////////////////
wire [31:0] joystick_0, joystick_1;
wire  [1:0] buttons;
wire [63:0] status;
wire [21:0] gamma_bus;
wire        ioctl_wr;
wire [26:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire [15:0] ioctl_index;
wire        direct_video;
wire        forced_scandoubler;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
  .clk_sys,
  .HPS_BUS(HPS_BUS),
  .EXT_BUS(),
  .gamma_bus,

  .conf_str(CONF_STR),

  .forced_scandoubler,
  .direct_video,
  .status_menumask(direct_video),

  .ioctl_wr,
  .ioctl_addr,
  .ioctl_dout,
  .ioctl_index,

  .joystick_0,
  .joystick_1,

  .buttons,
  .status
);

// Load DIP-SW
reg [7:0] dipsw[8];
always @(posedge clk_sys) begin
  if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3])
    dipsw[ioctl_addr[2:0]] <= ioctl_dout;
end
wire [7:0] sw = dipsw[0];

/////////////////////////////////////////////////////////////////////////
//      VIDEO
/////////////////////////////////////////////////////////////////////////

// Aspect ratio
wire [1:0] ar = status[3:2];
assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

// Monochrome video
wire VIDEO, SCORE;
wire HSYNC, VSYNC, HBLANK, VBLANK;
wire [3:0]  video = VIDEO ? 4'hF : SCORE ? 4'hB: 4'h0;
wire [11:0] rgb   = {3{video}};

// ce_pix is on positive edge of video clock (from core)
wire CLK_CORE_VIDEO;
reg  CLK_CORE_VIDEO_q;
wire ce_pix = ~CLK_CORE_VIDEO_q & CLK_CORE_VIDEO;
always_ff @(posedge clk_sys) CLK_CORE_VIDEO_q <= CLK_CORE_VIDEO;

wire [2:0] fx = status[6:4];

arcade_video #(.WIDTH(375), .DW(12)) arcade_video
(
  .*,

  .clk_video(clk_sys),
  .ce_pix(ce_pix),

  .RGB_in(rgb),
  .HBlank(HBLANK),
  .VBlank(VBLANK),
  .HSync(HSYNC),
  .VSync(VSYNC),

  .fx,
  .forced_scandoubler,
  .gamma_bus
);

/////////////////////////////////////////////////////////////////////////
//      SOUND
/////////////////////////////////////////////////////////////////////////
wire [15:0] SOUND;
assign AUDIO_L = SOUND;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;
assign AUDIO_MIX = 3;

/////////////////////////////////////////////////////////////////////////
//      CONTROL
/////////////////////////////////////////////////////////////////////////
wire UP1_N   = ~joystick_0[3];
wire DOWN1_N = ~joystick_0[2];
wire UP2_N   = ~joystick_1[3];
wire DOWN2_N = ~joystick_1[2];

// Holding down COIN_SW longer than necessary will corrupt or freeze
// the screen, so limit COIN_SW period to the minimum necessary.
wire coin_sw_raw = joystick_0[4] | joystick_1[4];
reg  coin_sw_raw_q;
wire coin_sw_rise = coin_sw_raw & ~coin_sw_raw_q;
always_ff @(posedge clk_sys) coin_sw_raw_q <= coin_sw_raw;

localparam COIN_SW_CNT   = 600000; // 0.0105 s (shoud be longer than 0.01 s)
localparam COIN_SW_CNT_W = $clog2(COIN_SW_CNT);
reg [COIN_SW_CNT_W-1:0] coin_sw_counter = 0;
reg COIN_SW = 1'b0;
always_ff @(posedge clk_sys) begin
  // COIN_SW will corrupt the screen while playing,
  // so disable it if there is credit left.
  if (coin_sw_rise && CREDIT_LIGHT_N) begin
    coin_sw_counter = 0;
    COIN_SW = 1'b1;
  end else if (coin_sw_counter == COIN_SW_CNT - 1) begin
    COIN_SW = 1'b0;
  end else begin
    coin_sw_counter = coin_sw_counter + 1'd1;
  end
end

wire START_GAME = joystick_0[5] | joystick_1[5];

/////////////////////////////////////////////////////////////////////////
//      GAME INSTANCE
/////////////////////////////////////////////////////////////////////////
wire       COINAGE  = sw[0];
wire [3:0] PLAYTIME = sw[4:1];
wire       CREDIT_LIGHT_N;

space_race_top space_race_top(
  .CLK_DRV(clk_sys),
  .CLK_SRC,
  .CLK_AUDIO,
  .RESET(reset),
  .COINAGE,
  .PLAYTIME,
  .COIN_SW,
  .START_GAME,
  .UP1_N, .DOWN1_N,
  .UP2_N, .DOWN2_N,
  .CLK_VIDEO(CLK_CORE_VIDEO),
  .VIDEO,  .SCORE,
  .HSYNC,  .VSYNC,
  .HBLANK, .VBLANK,
  .SOUND,
  .CREDIT_LIGHT_N
);

assign LED_USER = ~CREDIT_LIGHT_N;

endmodule
