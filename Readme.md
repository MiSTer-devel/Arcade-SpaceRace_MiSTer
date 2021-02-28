# Arcade Space Race for MiSTer

+ FPGA implementation of Arcade _Space Race_ (Atari, 1973) for MiSTer.
+ Based on Rev.F schematics.

## Inputs
+ Joypad (Default)
```
   Coin          : R
   Start         : Start
   Move forward  : DPAD UP
   Move backward : DPAD DOWN
```

## ROMs
+ No ROMs needed.
+ Arcade _Space Race_ is made up of discrete logic circuits, that is, there is no CPU and ROM.

## Placement
+ Please put release files (mra + rbf) as follows.
+ Otherwise DIP-switch settings on OSD will not work.
```
   /_Arcade/<game name>.mra
   /_Arcade/cores/<game rbf>.rbf
```

## USER LED
+ USER LED on IO board indicates **CREDIT LIGHT** on the original cabinet. 
