/*
ORSoC GFX accelerator core
Copyright 2012, ORSoC, Per Lenander, Anton Fosselius.

Parameter file

 This file is part of orgfx.

 orgfx is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version. 

 orgfx is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License
 along with orgfx.  If not, see <http://www.gnu.org/licenses/>.

*/

  // Declarations of register addresses:
  parameter GFX_CONTROL        = 9'h000;
  parameter GFX_STATUS         = 9'h008;
  parameter GFX_ALPHA          = 9'h010;
  parameter GFX_COLORKEY       = 9'h018;

  parameter GFX_TARGET_BASE    = 9'h020;
  parameter GFX_TARGET_SIZE_X  = 9'h028;
  parameter GFX_TARGET_SIZE_Y  = 9'h030;

  parameter GFX_TEX0_BASE      = 9'h038;
  parameter GFX_TEX0_SIZE_X    = 9'h040;
  parameter GFX_TEX0_SIZE_Y    = 9'h048;

  parameter GFX_SRC_PIXEL0_X   = 9'h050;
  parameter GFX_SRC_PIXEL0_Y   = 9'h058;
  parameter GFX_SRC_PIXEL1_X   = 9'h060;
  parameter GFX_SRC_PIXEL1_Y   = 9'h068;

  parameter GFX_DEST_PIXEL_X   = 9'h070;
  parameter GFX_DEST_PIXEL_Y   = 9'h078;
  parameter GFX_DEST_PIXEL_Z   = 9'h080;

  parameter GFX_AA             = 9'h088;
  parameter GFX_AB             = 9'h090;
  parameter GFX_AC             = 9'h098;
  parameter GFX_TX             = 9'h0A0;
  parameter GFX_BA             = 9'h0A8;
  parameter GFX_BB             = 9'h0B0;
  parameter GFX_BC             = 9'h0B8;
  parameter GFX_TY             = 9'h0C0;
  parameter GFX_CA             = 9'h0C8;
  parameter GFX_CB             = 9'h0D0;
  parameter GFX_CC             = 9'h0D8;
  parameter GFX_TZ             = 9'h0E0;

  parameter GFX_CLIP_PIXEL0_X  = 9'h0E8;
  parameter GFX_CLIP_PIXEL0_Y  = 9'h0F0;
  parameter GFX_CLIP_PIXEL1_X  = 9'h0F8;
  parameter GFX_CLIP_PIXEL1_Y  = 9'h100;

  parameter GFX_COLOR0         = 9'h108;
  parameter GFX_COLOR1         = 9'h110;
  parameter GFX_COLOR2         = 9'h118;

  parameter GFX_U0             = 9'h120;
  parameter GFX_V0             = 9'h128;
  parameter GFX_U1             = 9'h130;
  parameter GFX_V1             = 9'h138;
  parameter GFX_U2             = 9'h140;
  parameter GFX_V2             = 9'h148;

  parameter GFX_ZBUFFER_BASE   = 9'h150;

  parameter GFX_TARGET_X0			 = 9'h160;
  parameter GFX_TARGET_Y0			 = 9'h168;
  parameter GFX_TARGET_X1			 = 9'h170;
  parameter GFX_TARGET_Y1			 = 9'h178;
  parameter GFX_FONT_TABLE_BASE= 9'h180;
  parameter GFX_FONT_ID				 = 9'h188;
  parameter GFX_CHAR_CODE			 = 9'h190;

  // Declare control register bits
  parameter GFX_CTRL_CHAR		  = 0;
	parameter GFX_CTRL_TEXTURE  = 2;
  parameter GFX_CTRL_BLENDING = 3;
  parameter GFX_CTRL_COLORKEY = 4;
  parameter GFX_CTRL_CLIPPING = 5;
  parameter GFX_CTRL_ZBUFFER  = 6;
  
  parameter GFX_CTRL_RECT     = 8;
  parameter GFX_CTRL_LINE     = 9;
  parameter GFX_CTRL_TRI      = 10;
  parameter GFX_CTRL_CURVE    = 11;
  parameter GFX_CTRL_INTERP   = 12;
  parameter GFX_CTRL_INSIDE   = 13;
  
  parameter GFX_CTRL_ACTIVE_POINT    = 16;
  parameter GFX_CTRL_FORWARD_POINT   = 18;
  parameter GFX_CTRL_TRANSFORM_POINT = 19;

  parameter GFX_CTRL_COLOR_DEPTH = 20;

  // Declare status register bits
  parameter GFX_STAT_BUSY     = 0;

