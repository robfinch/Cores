-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
-- Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
--
-- This file modified to support 16 sprites 2016-08-06
-- Robert Finch  http://www.Finitron.ca
-- -----------------------------------------------------------------------
--
-- VIC-II - Video Interface Chip no 2
--
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

architecture rtl of video_vicii_656x_16 is
	type vicCycles is (
		cycleRefresh1, cycleRefresh2, cycleRefresh3, cycleRefresh4, cycleRefresh5,
		cycleIdle1,
		cycleChar,
		cycleCalcSprites, cycleSpriteBa1, cycleSpriteBa2, cycleSpriteBa3,
		cycleSpriteA, cycleSpriteA0, cycleSpriteA1, cycleSpriteA2, 
		cycleSpriteB, cycleSpriteC, cycleSpriteD
	);
	subtype ColorDef is unsigned(3 downto 0);
	type MFlags is array(0 to 15) of boolean;
	type MXdef is array(0 to 15) of unsigned(8 downto 0);
	type MYdef is array(0 to 15) of unsigned(7 downto 0);
	type MCntDef is array(0 to 15) of unsigned(5 downto 0);
	type MPixelsDef is array(0 to 15) of unsigned(23 downto 0);
	type MCurrentPixelDef is array(0 to 15) of unsigned(1 downto 0);
	type charStoreDef is array(38 downto 0) of unsigned(11 downto 0);
	type spriteColorsDef is array(15 downto 0) of unsigned(3 downto 0);
	type pixelColorStoreDef is array(7 downto 0) of unsigned(3 downto 0);

	signal cycleTypeReg : unsigned (1 downto 0);
-- State machine
	signal lastLineFlag : boolean; -- True for on last line of the frame.
	signal beyondFrameFlag : boolean; -- Y>frame lines
	signal nextVicCycle : vicCycles;
	signal vicCycle : vicCycles := cycleRefresh1;
	signal sprite : unsigned(3 downto 0) := "0000";
	signal shiftChars : boolean;
	signal idle: std_logic := '1';
	signal rasterIrqDone : std_logic; -- Only one interrupt each rasterLine
	signal rasterEnable: std_logic;

-- BA signal
	signal badLine : boolean; -- true if we have a badline condition
	signal baLoc : std_logic;
	signal baCnt : unsigned(2 downto 0);

	signal baChars : std_logic;
	signal baSprite : std_logic;

-- Memory refresh cycles
	signal refreshCounter : unsigned(7 downto 0);

-- User registers
  signal REGPG : std_logic := '0';
	signal MX : MXdef; -- Sprite X
	signal MY : MYdef; -- Sprite Y
	signal ME : unsigned(15 downto 0); -- Sprite enable
	signal MXE : unsigned(15 downto 0); -- Sprite X expansion
	signal MYE : unsigned(15 downto 0); -- Sprite Y expansion
	signal MPRIO : unsigned(15 downto 0); -- Sprite priority
	signal MC : unsigned(15 downto 0); -- sprite multi color

	-- !!! Krestage 3 hacks
	signal MCDelay : unsigned(15 downto 0); -- sprite multi color

	-- mode
	signal BMM: std_logic; -- Bitmap mode
	signal ECM: std_logic; -- Extended color mode
	signal MCM: std_logic; -- Multi color mode
	signal DEN: std_logic; -- DMA enable
	signal RSEL: std_logic; -- Visible rows selection (24/25)
	signal CSEL: std_logic; -- Visible columns selection (38/40)

	signal RES: std_logic;

	signal VM: unsigned(13 downto 10);
	signal CB: unsigned(13 downto 11);

	signal EC : ColorDef;  -- border color
	signal B0C : ColorDef; -- background color 0
	signal B1C : ColorDef; -- background color 1
	signal B2C : ColorDef; -- background color 2
	signal B3C : ColorDef; -- background color 3
	signal MM0 : ColorDef; -- sprite multicolor 0
	signal MM1 : ColorDef; -- sprite multicolor 1
	signal spriteColors: spriteColorsDef;

-- borders and blanking
	signal LRBorder: std_logic;
	signal TBBorder: std_logic;
	signal hBlack: std_logic;
	signal vBlanking : std_logic;
	signal hBlanking : std_logic;
	signal xscroll: unsigned(2 downto 0);
	signal yscroll: unsigned(2 downto 0);
	signal rasterCmp : unsigned(8 downto 0);

-- Address generator
	signal vicAddrReg : unsigned(13 downto 0);
	signal vicAddrLoc : unsigned(13 downto 0);

-- Address counters
	signal ColCounter: unsigned(9 downto 0) := (others => '0');
	signal ColRestart: unsigned(9 downto 0) := (others => '0');
	signal RowCounter: unsigned(2 downto 0) := (others => '0');

-- IRQ Registers
	signal IRST: std_logic := '0';
	signal ERST: std_logic := '0';
	signal IMBC: std_logic := '0';
	signal EMBC: std_logic := '0';
	signal IMMC: std_logic := '0';
	signal EMMC: std_logic := '0';
	signal ILP: std_logic := '0';
	signal ELP: std_logic := '0';
	signal IRQ: std_logic;

-- Collision detection registers
	signal M2M: unsigned(15 downto 0); -- Sprite to sprite collision
	signal M2D: unsigned(15 downto 0); -- Sprite to character collision
	signal M2Mhit : std_logic;
	signal M2Dhit : std_logic;

-- Raster counters
	signal rasterX : unsigned(9 downto 0) := (others => '0');
	signal rasterY : unsigned(8 downto 0) := (others => '0');

-- Light pen
	signal lightPenHit: std_logic;
	signal lpX : unsigned(7 downto 0);
	signal lpY : unsigned(7 downto 0);

-- IRQ Resets
	signal resetLightPenIrq: std_logic;
	signal resetIMMC : std_logic;
	signal resetIMBC : std_logic;
	signal resetRasterIrq : std_logic;

-- Character generation
	signal charStore: charStoreDef;
	signal nextChar : unsigned(11 downto 0);
	-- Char/Pixels just coming from memory
	signal readChar : unsigned(11 downto 0);
	signal readPixels : unsigned(7 downto 0);
	-- Char/Pixels pair waiting to be shifted
	signal waitingChar : unsigned(11 downto 0);
	signal waitingPixels : unsigned(7 downto 0);
	-- Stores colorinfo and the Pixels that are currently in shift register
	signal shiftingChar : unsigned(11 downto 0);
	signal shiftingPixels : unsigned(7 downto 0);
	signal shifting_ff : std_logic; -- Multicolor shift-regiter status bit.

-- Sprite work registers
	signal MPtr : unsigned(7 downto 0); -- sprite base pointer
	signal MPixels : MPixelsDef; -- Sprite 504 bit shift register
	signal MActive : MFlags; -- Sprite is active (derived from MCnt)
	signal MCnt : MCntDef;
	signal MXE_ff : unsigned(15 downto 0); -- Sprite X expansion flipflop
	signal MYE_ff : unsigned(15 downto 0); -- Sprite Y expansion flipflop
	signal MC_ff : unsigned(15 downto 0); -- controls sprite shift-register in multicolor
	signal MShift : MFlags; -- Sprite is shifting
	signal MCurrentPixel : MCurrentPixelDef;

-- Current colors and pixels
	signal pixelColor: ColorDef;
	signal pixelBgFlag: std_logic; -- For collision detection
	signal pixelDelay: pixelColorStoreDef;

-- Read/Write lines
	signal myWr : std_logic;
	signal myRd : std_logic;

begin
-- -----------------------------------------------------------------------
-- Ouput signals
-- -----------------------------------------------------------------------
	ba <= baLoc;
	vicAddr <= vicAddrReg when registeredAddress else vicAddrLoc;
	cycleType <= cycleTypeReg;
	hSync <= hBlanking;
	vSync <= vBlanking;
	irq_n <= not IRQ;

-- -----------------------------------------------------------------------
-- -----------------------------------------------------------------------
  process(nextVicCycle,sprite)
  begin
    case nextVicCycle is
    when cycleRefresh1 | cycleRefresh2 | cycleRefresh3 | cycleRefresh4 | cycleRefresh5 =>
      cycleTypeReg <= to_unsigned(3,2);
    when cycleChar =>
      cycleTypeReg <= to_unsigned(2,2);
    when cycleSpriteA =>
       if MActive(to_integer(sprite)) then
        cycleTypeReg <= to_unsigned(1,2);
      else
        cycleTypeReg <= to_unsigned(0,2);
      end if;
    when others =>
      cycleTypeReg <= to_unsigned(0,2);
    end case;
  end process;

-- -----------------------------------------------------------------------
-- chip-select signals
-- -----------------------------------------------------------------------
	myWr <= cs and we;
	myRd <= cs and rd;

-- -----------------------------------------------------------------------
-- debug signals
-- -----------------------------------------------------------------------
	debugX <= rasterX;
	debugY <= rasterY;

-- -----------------------------------------------------------------------
-- Badline condition
-- -----------------------------------------------------------------------
	process(rasterY, yscroll, rasterEnable)
	begin
		badLine <= false;
		if (rasterY(2 downto 0) = yscroll)
		and (rasterEnable = '1') then
			badLine <= true;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- BA=low counter
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if baLoc = '0' then
				if phi = '0'
				and enaData = '1'
				and baCnt(2) = '0' then
					baCnt <= baCnt + 1;
				end if;
			else
				baCnt <= (others => '0');
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Calculate lastLineFlag
-- -----------------------------------------------------------------------
	process(clk)
		variable rasterLines : integer range 0 to 312;
	begin
		if rising_edge(clk) then
			lastLineFlag <= false;

			rasterLines := 311; -- PAL
			if mode6567old = '1' then
				rasterLines := 261; -- NTSC (R7 and earlier have 262 lines)
			end if;
			if mode6567R8 = '1' then
				rasterLines := 262; -- NTSC (R8 and newer have 263 lines)
			end if;
			if rasterY = rasterLines then
				lastLineFlag <= true;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- State machine
-- -----------------------------------------------------------------------
vicStateMachine: process (phi, vicCycle, rasterX, sprite, mode6569, mode6567old, mode6567R8, mode6572)
	begin
    if phi = '0' then
      case vicCycle is
      when cycleRefresh1 =>
        nextVicCycle <= cycleRefresh2;
        if ((mode6567old or mode6567R8) = '1') then
          nextVicCycle <= cycleIdle1;
        end if;
      when cycleIdle1 => nextVicCycle <= cycleRefresh2;
      when cycleRefresh2 => nextVicCycle <= cycleRefresh3;
      when cycleRefresh3 => nextVicCycle <= cycleRefresh4;
      when cycleRefresh4 => nextVicCycle <= cycleRefresh5;  -- X=0..7 on this cycle
      when cycleRefresh5 => nextVicCycle <= cycleChar;
      when cycleChar =>
        if ((mode6569  = '1') and rasterX(9 downto 3) = "0100111") -- PAL
        or ((mode6567old  = '1') and rasterX(9 downto 3) = "0100111") -- Old NTSC
        or ((mode6567R8  = '1') and rasterX(9 downto 3) = "0101000") -- New NTSC
        or ((mode6572  = '1') and rasterX(9 downto 3) = "0101000") then -- PAL-N
          nextVicCycle <= cycleCalcSprites;
        end if;
      when cycleCalcSprites => nextVicCycle <= cycleSpriteBa1;
      when cycleSpriteBa1 => nextVicCycle <= cycleSpriteBa2;
      when cycleSpriteBa2 => nextVicCycle <= cycleSpriteBa3;
      when others =>
        nextVicCycle <= vicCycle;
      end case;
    else
      case vicCycle is
      when cycleSpriteBa3 => nextVicCycle <= cycleSpriteA;
      when cycleSpriteA =>
        nextVicCycle <= cycleSpriteA;
        if sprite = 15 then
          nextVicCycle <= cycleRefresh1;
        end if;
      when others =>
        nextVicCycle <= vicCycle; -- when this was set to null the states didn't progress properly
      end case;
    end if;
  end process;

vicStateMachineClk: process(clk)
	begin
    if rising_edge(clk) then
      if enaData = '1'
      and baSync = '0' then
        vicCycle <= nextVicCycle;
      end if;
    end if;
  end process;

-- -----------------------------------------------------------------------
-- Iterate through all sprites.
-- Only used when state-machine above is in any sprite cycles.
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
		  if phi = '1'
			and enaData = '1'
			and vicCycle = cycleSpriteA
			and baSync = '0' then
				sprite <= sprite + 1;
			end if;
		end if;			
	end process;

-- -----------------------------------------------------------------------
-- Address generator
-- -----------------------------------------------------------------------
	process(phi, phis, vicCycle, sprite, shiftChars, idle,
			VM, CB, ECM, BMM, nextChar, colCounter, rowCounter, MPtr, MCnt)
	begin
		--
		-- Default case ($3FFF fetches)
		vicAddrLoc <= (others => '1');
		if (idle = '0')
		and shiftChars then
			if BMM = '1' then
				vicAddrLoc <= CB(13) & colCounter & rowCounter;
			else
				vicAddrLoc <= CB & nextChar(7 downto 0) & rowCounter;
			end if;
		end if;
		if ECM = '1' then
			vicAddrLoc(10 downto 9) <= "00";
		end if;

		case vicCycle is
		when cycleRefresh1 | cycleRefresh2 | cycleRefresh3 | cycleRefresh4 | cycleRefresh5 =>
			if emulateRefresh then
				vicAddrLoc <= "111111" & refreshCounter;
			else
				vicAddrLoc <= (others => '-');
			end if;
		when cycleSpriteBa1 | cycleSpriteBa2 | cycleSpriteBa3 =>
			vicAddrLoc <= (others => '1');
		when cycleSpriteA =>
			vicAddrLoc <= VM & "111111" & not sprite(3) & sprite(2 downto 0);
			if phis = '1' then
        vicAddrLoc <= MPtr & MCnt(to_integer(sprite));
			end if;
		when others =>
			if phi = '1' then
				vicAddrLoc <= VM & colCounter;
			end if;
		end case;
	end process;

	-- Registered address
	process(clk)
	begin
		if rising_edge(clk) then
			vicAddrReg <= vicAddrLoc;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Character storage
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if enaData = '1'
			and shiftChars
			and phi = '1' then
				if badLine then
					nextChar(7 downto 0) <= di;
					nextChar(11 downto 8) <= diColor;
				else
					nextChar <= charStore(38);
				end if;
				charStore <= charStore(37 downto 0) & nextChar;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Sprite base pointer (MPtr)
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
		  if phis = '0'
			and enaSData = '1'
			and vicCycle = cycleSpriteA then
				MPtr <= (others => '1');
				if MActive(to_integer(sprite)) then
					MPtr <= di;
				end if;

				-- If refresh counter is not emulated we don't care about
				-- MPtr having the correct value in idle state.
				if not emulateRefresh then
					MPtr <= di;
				end if;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Refresh counter
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
		  if rst = '1' then
		    refreshCounter <= (others => '1');
		  end if;
			vicRefresh <= '0';
			case vicCycle is
			when cycleRefresh1 | cycleRefresh2 | cycleRefresh3 | cycleRefresh4 | cycleRefresh5 =>
				vicRefresh <= '1';
				if phi = '0'
				and enaData = '1'
				and baSync = '0' then
					refreshCounter <= refreshCounter - 1;
				end if;
			when others =>
				null;
			end case;
			if lastLineFlag then
				refreshCounter <= (others => '1');
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Generate Raster Enable
-- -----------------------------------------------------------------------
	process(clk)
	begin
	  if rst = '1' then
	    rasterEnable <= '0';
	  end if;
		-- Enable screen and character display.
		-- This is only possible in line 48 on the VIC-II.
		-- On other lines any DEN changes are ignored.
		if rising_edge(clk) then
			if (rasterY = simRasterEnable) and (DEN = '1') then
				rasterEnable <= '1';
			end if;
			if (rasterY = 248) then
				rasterEnable <= '0';
			end if;
		end if;
	end process;


-- -----------------------------------------------------------------------
-- BA generator (Text/Bitmap)
-- -----------------------------------------------------------------------
--
-- For Text/Bitmap BA goes low 3 cycles before real access. So BA starts
-- going low during refresh2 state. See diagram below for timing:
--
-- X               0  0  0  0  0
--                 0  0  0  0  1
--                 0  4  8  C  0
--
-- phi ___   ___   ___   ___   ___   ___   ___   ___...
--        ___   ___   ___   ___   ___   ___   ___   ...
--
--          |     |     |     |     |     |     |...
--     rfr2  rfr3  rfr4  rfr5  char1 char2 char3
--
-- BA _______
--        \\\_______________________________________
--          |  1  |  2  |  3  |
--
-- BACnt 000  001 | 010 | 011 | 100   100   100  ...
--
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if phi = '0' then
				baChars <= '1';
				case vicCycle is
				when cycleRefresh2 | cycleRefresh3 | cycleRefresh4 | cycleRefresh5 =>
					if badLine then
						baChars <= '0';
					end if;
				when others =>
					if rasterX(9 downto 3) < "0101000"
					and badLine then
						baChars <= '0';
					end if;
				end case;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- BA generator (Sprites)
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
-- handy for simulation
		  if rst = '1' then
		    baSprite <= '1';
		  end if;
			if phi = '0' then
        baSprite <= '1';				
				if ((MActive(0)) and (vicCycle = cycleCalcSprites))
				or ((MActive(0) or MActive(1)) and (vicCycle = cycleSpriteBa1))
				or ((MActive(0) or MActive(1) or MActive(2)) and (vicCycle = cycleSpriteBa2))
				or ((MActive(0) or MActive(1) or MActive(2) or Mactive(3)) and (vicCycle = cycleSpriteBa3))
				or ((MActive(0) or MActive(1) or MActive(2) or MActive(3)) and (vicCycle = cycleSpriteA) and (sprite = 0))
				or ((MActive(1) or MActive(2) or MActive(3) or MActive(4)) and (vicCycle = cycleSpriteA) and (sprite = 1))
				or ((MActive(2) or MActive(3) or MActive(4) or MActive(5)) and (vicCycle = cycleSpriteA) and (sprite = 2))
				or ((MActive(3) or MActive(4) or MActive(5) or MActive(6)) and (vicCycle = cycleSpriteA) and (sprite = 3))
				or ((MActive(4) or MActive(5) or MActive(6) or MActive(7)) and (vicCycle = cycleSpriteA) and (sprite = 4))
				or ((MActive(5) or MActive(6) or MActive(7) or MActive(8)) and (vicCycle = cycleSpriteA) and (sprite = 5))
				or ((MActive(6) or MActive(7) or MActive(8) or MActive(9)) and (vicCycle = cycleSpriteA) and (sprite = 6))
				or ((MActive(7) or MActive(8) or MActive(9) or MActive(10)) and (vicCycle = cycleSpriteA) and (sprite = 7))
				or ((MActive(8) or MActive(9) or MActive(10) or MActive(11)) and (vicCycle = cycleSpriteA) and (sprite = 8))
				or ((MActive(9) or MActive(10) or MActive(11) or MActive(12)) and (vicCycle = cycleSpriteA) and (sprite = 9))
				or ((MActive(10) or MActive(11) or MActive(12) or MActive(13)) and (vicCycle = cycleSpriteA) and (sprite = 10))
				or ((MActive(11) or MActive(12) or MActive(13) or MActive(14)) and (vicCycle = cycleSpriteA) and (sprite = 11))
				or ((MActive(12) or MActive(13) or MActive(14) or MActive(15)) and (vicCycle = cycleSpriteA) and (sprite = 12))
				or ((MActive(13) or MActive(14) or MActive(15)) and (vicCycle = cycleSpriteA) and (sprite = 13))
				or ((MActive(14) or MActive(15)) and (vicCycle = cycleSpriteA) and (sprite = 14))
				or (MActive(15) and (vicCycle = cycleSpriteA) and (sprite = 15)) then
          baSprite <= '0';
        end if;
		  end if;
		end if;
	end process;
	baLoc <= baChars and baSprite;

-- -----------------------------------------------------------------------
-- Address valid?
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			addrValid <= '0';
			if phi = '0'
			or baCnt(2) = '1' then
				addrValid <= '1';
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Generate ShiftChars flag
-- -----------------------------------------------------------------------
	process(rasterX)
	begin
		shiftChars <= false;
		if rasterX(9 downto 3) > "0000000"
		and rasterX(9 downto 3) < "0101001" then
			shiftChars <= true;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- RowCounter and ColCounter
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if phi = '0'
			and enaData = '1'
			and baSync = '0' then
				if shiftChars
				and idle = '0' then
					colCounter <= colCounter + 1;
				end if;
				case vicCycle is
				when cycleRefresh4 =>
					colCounter <= colRestart;
					if badline then
						rowCounter <= (others => '0');
					end if;
				when cycleSpriteA =>
					if sprite = "000" then
						if rowCounter = 7 then
							colRestart <= colCounter;
							idle <= '1';
						else
							rowCounter <= rowCounter + 1;
						end if;
						if badline then
							rowCounter <= rowCounter + 1;
						end if;
					end if;
				when others =>
					null;					
				end case;
				if lastLineFlag then
					-- Reset column counter outside visible range.
					colRestart <= (others => '0');
				end if;

				-- Set display mode (leave idle-mode) as soon as
				-- there is a badline condition.
				if badline then
					idle <= '0';
				end if;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- X/Y Raster counter
-- -----------------------------------------------------------------------
rasterCounters: process(clk)
	begin
		if rising_edge(clk) then
			if enaPixel = '1' then
				rasterX(2 downto 0) <= rasterX(2 downto 0) + 1;
			end if;
			if phi = '0'
			and enaData = '1'
			and baSync = '0' then
				rasterX(9 downto 3) <= rasterX(9 downto 3) + 1;
				rasterX(2 downto 0) <= (others => '0');
				if vicCycle = cycleRefresh4 then
					rasterX <= (others => '0');
				end if;
			end if;
			if phi = '1'
			and enaData = '1'
			and baSync = '0' then
				beyondFrameFlag <= false;
				if (vicCycle = cycleSpriteA)
				and (sprite = 2) then
					rasterY <= rasterY + 1;
					beyondFrameFlag <= lastLineFlag;
				end if;
				if beyondFrameFlag then
					rasterY <= (others => '0');
				end if;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Raster IRQ
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if phi = '1'
			and enaData = '1'
			and baSync = '0'
			and (vicCycle = cycleSpriteA)
			and (sprite = 2) then
				rasterIrqDone <= '0';
			end if;
			if resetRasterIrq = '1' then
				IRST <= '0';
			end if;
			if (rasterIrqDone = '0')
			and (rasterY = rasterCmp) then
				rasterIrqDone <= '1';
				IRST <= '1';
			end if;
		end if;
	end process;


-- -----------------------------------------------------------------------
-- Light pen
-- -----------------------------------------------------------------------
-- On a negative edge on the LP input, the current position of the raster beam
-- is latched in the registers LPX ($d013) and LPY ($d014). LPX contains the
-- upper 8 bits (of 9) of the X position and LPY the lower 8 bits (likewise of
-- 9) of the Y position. So the horizontal resolution of the light pen is
-- limited to 2 pixels.

-- Only one negative edge on LP is recognized per frame. If multiple edges
-- occur on LP, all following ones are ignored. The trigger is not released
-- until the next vertical blanking interval.
-- -----------------------------------------------------------------------
lightPen: process(clk)
	begin
		if rising_edge(clk) then
			if emulateLightpen then
				if resetLightPenIrq = '1' then
					-- Reset light pen interrupt
					ILP <= '0';
				end if;			
				if lastLineFlag then
					-- Reset lightpen state at beginning of frame
					lightPenHit <= '0';
				elsif (lightPenHit = '0') and (lp_n = '0') then
					-- One hit/frame
					lightPenHit <= '1'; 
					-- Toggle Interrupt
					ILP <= '1'; 
					-- Store position of beam
					lpx <= rasterX(8 downto 1);
					lpy <= rasterY(7 downto 0);
				end if;
			else
				ILP <= '0';
				lpx <= (others => '1');
				lpy <= (others => '1');
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- VSync
-- -----------------------------------------------------------------------
doVBlanking: process(clk, mode6569, mode6567old, mode6567R8)
		variable rasterBlank : integer range 0 to 300;
	begin
		rasterBlank := 300;
		if (mode6567old or mode6567R8) = '1' then
			rasterBlank := 12;
		end if;
		if rising_edge(clk) then
			vBlanking <= '0';
			if rasterY = rasterBlank then
				vBlanking <= '1';
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- HSync
-- -----------------------------------------------------------------------
doHBlanking: process(clk)
	begin
		if rising_edge(clk) then
			if sprite = 3 then
				hBlack <= '1';
			end if;
			if vicCycle = cycleRefresh1 then
				hBlack <= '0';
			end if;
			if sprite = 5 then
				hBlanking <= '1';
			else
				hBlanking <= '0';
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Borders
-- -----------------------------------------------------------------------
calcBorders: process(clk)
		variable newTBBorder: std_logic;
	begin
		if rising_edge(clk) then
			if enaPixel = '1' then
				--
				-- Calc top/bottom border
				newTBBorder := TBBorder;
--				if (rasterY = 55) and (RSEL = '0') and (rasterEnable = '1') then
				if (rasterY = 55) and (rasterEnable = '1') then
					newTBBorder := '0';
				end if;
				if (rasterY = 51) and (RSEL = '1') and (rasterEnable = '1') then
					newTBBorder := '0';
				end if;
				if (rasterY = 247) and (RSEL = '0') then
					newTBBorder := '1';
				end if;
				if (rasterY = 251) and (RSEL = '1') then
					newTBBorder := '1';
				end if;

				--
				-- Calc left/right border
				if (rasterX = (31+1)) and (CSEL = '0') then
					LRBorder <= newTBBorder;
					TBBorder <= newTBBorder;
				end if;
				if (rasterX = (24+1)) and (CSEL = '1') then
					LRBorder <= newTBBorder;
					TBBorder <= newTBBorder;
				end if;
				if (rasterX = (335+1)) and (CSEL = '0') then
					LRBorder <= '1';
				end if;
				if (rasterX = (344+1)) and (CSEL = '1') then
					LRBorder <= '1';
				end if;
			end if;
		end if;
	end process;


-- -----------------------------------------------------------------------
-- Pixel generator for Text/Bitmap screen
-- -----------------------------------------------------------------------
calcBitmap: process(clk)
		variable multiColor : std_logic;
	begin
		if rising_edge(clk) then
			if enaPixel = '1' then
				--
				-- Toggle flipflop for multicolor 2-bits shift.
				shifting_ff <= not shifting_ff;
				
				--
				-- Multicolor mode is active with MCM, but for character
				-- mode it depends on bit3 of color ram too.
				multiColor := MCM and (BMM or ECM or shiftingChar(11));

				--
				-- Reload shift register when xscroll=rasterX
				-- otherwise shift pixels
				if xscroll = rasterX(2 downto 0) then
					shifting_ff <= '0';
					shiftingChar <= waitingChar;
					shiftingPixels <= waitingPixels;
				elsif multiColor = '0' then
					shiftingPixels <= shiftingPixels(6 downto 0) & '0';
				elsif shifting_ff = '1' then
					shiftingPixels <= shiftingPixels(5 downto 0) & "00";
				end if;

				--
				-- Calculate if pixel is in foreground or background
				pixelBgFlag <= shiftingPixels(7);

				--
				-- Calculate color of next pixel				
				pixelColor <= B0C;
				if (BMM = '0') and (ECM='0') then
					if (multiColor = '0') then
						-- normal character mode
						if shiftingPixels(7) = '1' then
							pixelColor <= shiftingChar(11 downto 8);
						end if;
					else
						-- multi-color character mode
						case shiftingPixels(7 downto 6) is
						when "01" => pixelColor <= B1C;
						when "10" => pixelColor <= B2C;
						when "11" => pixelColor <= '0' & shiftingChar(10 downto 8);
						when others => null;
						end case;
					end if;
				elsif (MCM = '0') and (BMM = '0') and (ECM='1') then
					-- extended-color character mode
					-- multiple background colors but only 64 characters
					if shiftingPixels(7) = '1' then
						pixelColor <= shiftingChar(11 downto 8);
					else
						case shiftingChar(7 downto 6) is
						when "01" => pixelColor <= B1C;
						when "10" => pixelColor <= B2C;
						when "11" => pixelColor <= B3C;
						when others	=> null;
						end case;
					end if;
				elsif emulateGraphics and (MCM = '0') and (BMM = '1') and (ECM='0') then
					-- highres bitmap mode
					if shiftingPixels(7) = '1' then
						pixelColor <= shiftingChar(7 downto 4);
					else
						pixelColor <= shiftingChar(3 downto 0);
					end if;
				elsif emulateGraphics and (MCM = '1') and (BMM = '1') and (ECM='0') then
					-- Multi-color bitmap mode
					case shiftingPixels(7 downto 6) is
					when "01" => pixelColor <= shiftingChar(7 downto 4);
					when "10" => pixelColor <= shiftingChar(3 downto 0);
					when "11" => pixelColor <= shiftingChar(11 downto 8);
					when others => null;
					end case;
				else
					-- illegal display mode, the output is black
					pixelColor <= "0000";
				end if;
			end if;

			--
			-- Store fetched pixels, until current pixels are displayed
			-- and shift-register is empty.
			if enaData = '1'
			and phi = '0' then
				readPixels <= (others => '0');
				if shiftChars then
					readPixels <= di;
					readChar <= (others => '0');
					if idle = '0' then
						readChar <= nextChar;
					end if;
				end if;
				-- Store the characters until shiftregister is empty
				waitingPixels <= readPixels;
				waitingChar <= readChar;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Which sprites are active?
-- -----------------------------------------------------------------------
	process(MCnt)
	begin
		for i in 0 to 15 loop
			MActive(i) <= false;
			if MCnt(i) /= 63 then
				MActive(i) <= true;
			end if;
		end loop;
	end process;

-- -----------------------------------------------------------------------
-- Sprite byte counter
-- Y expansion flipflop
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
		  if rst = '1' then
		    for i in 0 to 15 loop
		      MCnt(i) <= to_unsigned(63,6);
		    end loop;
		  end if;
			if phi = '0'
			and enaData = '1' then
				case vicCycle is
				when cycleRefresh5 =>
					for i in 0 to 15 loop
						MYE_ff(i) <= not MYE_ff(i);
						if MActive(i) then
							if MYE_ff(i) = MYE(i) then
								MCnt(i) <= MCnt(i) + 1;
							else
								MCnt(i) <= MCnt(i) - 2;
							end if;
						end if;
					end loop;
				when others =>
					null;
				end case;
			end if;
			for i in 0 to 15 loop
				if MYE(i) = '0'
				or not MActive(i) then
					MYE_ff(i) <= '0';
				end if;
			end loop;
			
			--
			-- On cycleCalcSprite check for each inactive sprite if
			-- there is a Y match. Reset MCnt if this is so.
			--
			-- The RasterX counter is used here to multiplex the compare logic.
			-- This saves a few logic cells in the FPGA.
--			if vicCycle = cycleCalcSprites then
--				if (not MActive(to_integer(RasterX(2 downto 0))))
--				and (ME(to_integer(RasterX(2 downto 0))) = '1')
--				and (rasterY(7 downto 0) = MY(to_integer(RasterX(2 downto 0)))) then
--					MCnt(to_integer(RasterX(2 downto 0))) <= (others => '0');
--				end if;
--			end if;
			--
			-- Original non-multiplexed version
				if vicCycle = cycleCalcSprites then
					for i in 0 to 15 loop
						if (not MActive(i))
						and (ME(i) = '1')
						and (rasterY(7 downto 0) = MY(i)) then
							MCnt(i) <= (others => '0');
						end if;
					end loop;						
				end if;
			
			--
			-- Increment MCnt after fetching data.
			if phis = '1' and enaSData = '1' and vicCycle = cycleSpriteA then
        if MActive(to_integer(sprite)) then
          MCnt(to_integer(sprite)) <= MCnt(to_integer(sprite)) + 1;
        end if;
      end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Sprite pixel Shift register
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			-- Enable sprites on the correct X position
      for i in 0 to 15 loop
        if rasterX = 10 then
          MShift(i) <= false;
        else if rasterX = MX(i) then
          MShift(i) <= true;
          end if;
        end if;
      end loop;

			if enaPixel = '1' then
				-- Shift one pixel of the sprite from the shift register.
				for i in 0 to 15 loop
					if MShift(i) then
						MXE_ff(i) <= (not MXE_ff(i)) and MXE(i);
						if MXE_ff(i) = '0' then
							MC_ff(i) <= (not MC_ff(i)) and MC(i);
							if MC_ff(i) = '0' then
								MCurrentPixel(i) <= MPixels(i)(23 downto 22);
							end if;
							MPixels(i) <= MPixels(i)(22 downto 0) & '0';
						end if;
					else
						MXE_ff(i) <= '0';
						MC_ff(i) <= '0';
						MCurrentPixel(i) <= "00";
					end if;
				end loop;
			end if;

      if phis = '1' and enaSData = '1' and vicCycle = cycleSpriteA then
				if Mactive(to_integer(sprite)) then
					MPixels(to_integer(sprite)) <= MPixels(to_integer(sprite))(15 downto 0) & di;
				end if;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Video output
-- -----------------------------------------------------------------------
	process(clk)
		variable myColor: unsigned(3 downto 0);
		variable muxSprite : unsigned(2 downto 0);
		variable muxColor : unsigned(1 downto 0);
		-- 00 = pixels
		-- 01 = MM0
		-- 10 = Sprite
		-- 11 = MM1
	begin
		if rising_edge(clk) then
			muxColor := "00";
			muxSprite := (others => '-');
			for i in 15 downto 0 loop
				if (MPRIO(i) = '0') or (pixelBgFlag = '0') then
					if MC(i) = '1' then
						if MCurrentPixel(i) /= "00" then
							muxColor := MCurrentPixel(i);
							muxSprite := to_unsigned(i, 3);
						end if;
					elsif MCurrentPixel(i)(1) = '1' then
						muxColor := "10";
						muxSprite := to_unsigned(i, 3);
					end if;
				end if;
			end loop;

			myColor := pixelColor;
			case muxColor is
			when "01" => myColor := MM0;
			when "10" => myColor := spriteColors(to_integer(muxSprite));
			when "11" => myColor := MM1;
			when others =>
				null;
			end case;
		
		
--			myColor := pixelColor;
--			for i in 7 downto 0 loop
--				if (MPRIO(i) = '0') or (pixelBgFlag = '0') then
--					if MC(i) = '1' then
--						case MCurrentPixel(i) is
--						when "01" => myColor := MM0;
--						when "10" => myColor := spriteColors(i);
--						when "11" => myColor := MM1;
--						when others => null;
--						end case;
--					elsif MCurrentPixel(i)(1) = '1' then
--						myColor := spriteColors(i);
--					end if;
--				end if;
--			end loop;
			
			if enaPixel = '1' then
				colorIndex <= myColor;

-- Krestage 3 debugging routine
--				if (cs = '1' and aRegisters = "011100") then
--					colorIndex <= "1111";
--				end if;
				if (LRBorder = '1') or (TBBorder = '1') then
					colorIndex <= EC;
				end if;
				if (hBlack = '1') then
					colorIndex <= (others => '0');
				end if;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Sprite to sprite collision
-- -----------------------------------------------------------------------
spriteSpriteCollision: process(clk)
		variable collision : unsigned(15 downto 0);
	begin
		if rising_edge(clk) then			
			if resetIMMC = '1' then
				IMMC <= '0';
			end if;

			if (myRd = '1')
			and	(aRegisters = "011110") then
				M2M <= (others => '0');
				M2Mhit <= '0';
			end if;

			for i in 0 to 15 loop
				collision(i) := MCurrentPixel(i)(1);
			end loop;
			if (collision /= "0000000000000000")
			and (collision /= "0000000000000001")
			and (collision /= "0000000000000010")
			and (collision /= "0000000000000100")
			and (collision /= "0000000000001000")
			and (collision /= "0000000000010000")
			and (collision /= "0000000000100000")
			and (collision /= "0000000001000000")
			and (collision /= "0000000010000000")
			and (collision /= "0000000100000000")
			and (collision /= "0000001000000000")
			and (collision /= "0000010000000000")
			and (collision /= "0000100000000000")
			and (collision /= "0001000000000000")
			and (collision /= "0010000000000000")
			and (collision /= "0100000000000000")
			and (collision /= "1000000000000000")
			and (TBBorder = '0') then
				M2M <= M2M or collision;
				
				-- Give collision interrupt but only once until clear of register
				if M2Mhit = '0' then
					IMMC <= '1';
					M2Mhit <= '1';
				end if;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Sprite to background collision
-- -----------------------------------------------------------------------
spriteBackgroundCollision: process(clk)
	begin
		if rising_edge(clk) then			
			if resetIMBC = '1' then
				IMBC <= '0';
			end if;

			if (myRd = '1')
			and	(aRegisters = "011111") then
				M2D <= (others => '0');
				M2Dhit <= '0';
			end if;

			for i in 0 to 15 loop
				if MCurrentPixel(i)(1) = '1'
				and pixelBgFlag = '1'
				and (TBBorder = '0') then
					M2D(i) <= '1';
					
					-- Give collision interrupt but only once until clear of register
					if M2Dhit = '0' then
						IMBC <= '1';
						M2Dhit <= '1';
					end if;
				end if;
			end loop;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Generate IRQ signal
-- -----------------------------------------------------------------------
	IRQ <= (ILP and ELP) or (IMMC and EMMC) or (IMBC and EMBC) or (IRST and ERST);

-- -----------------------------------------------------------------------
-- Krestage 3 hack
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if phi = '1'
			and enaData = '1' then
				MC <= MCDelay;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Write registers
-- -----------------------------------------------------------------------
writeRegisters: process(clk)
	begin
		if rising_edge(clk) then
		  if rst = '1' then
		    for i in 0 to 15 loop
          MX(i) <= to_unsigned(200,9);
          MY(i) <= to_unsigned(5,8);
		    end loop;
		    ME <= to_unsigned(0,16);
		  end if;
			resetLightPenIrq <= '0';
			resetIMMC <= '0';
			resetIMBC <= '0';
			resetRasterIrq <= '0';
		
			--
			-- write to registers
			if (myWr = '1') then
				case (REGPG & aRegisters) is
				when "0000000" => MX(0)(7 downto 0) <= diRegisters;
				when "0000001" => MY(0) <= diRegisters;
				when "0000010" => MX(1)(7 downto 0) <= diRegisters;
				when "0000011" => MY(1) <= diRegisters;
				when "0000100" => MX(2)(7 downto 0) <= diRegisters;
				when "0000101" => MY(2) <= diRegisters;
				when "0000110" => MX(3)(7 downto 0) <= diRegisters;
				when "0000111" => MY(3) <= diRegisters;
				when "0001000" => MX(4)(7 downto 0) <= diRegisters;
				when "0001001" => MY(4) <= diRegisters;
				when "0001010" => MX(5)(7 downto 0) <= diRegisters;
				when "0001011" => MY(5) <= diRegisters;
				when "0001100" => MX(6)(7 downto 0) <= diRegisters;
				when "0001101" => MY(6) <= diRegisters;
				when "0001110" => MX(7)(7 downto 0) <= diRegisters;
				when "0001111" => MY(7) <= diRegisters;
				when "1000000" => MX(8)(7 downto 0) <= diRegisters;
        when "1000001" => MY(8) <= diRegisters;
        when "1000010" => MX(9)(7 downto 0) <= diRegisters;
        when "1000011" => MY(9) <= diRegisters;
        when "1000100" => MX(10)(7 downto 0) <= diRegisters;
        when "1000101" => MY(10) <= diRegisters;
        when "1000110" => MX(11)(7 downto 0) <= diRegisters;
        when "1000111" => MY(11) <= diRegisters;
        when "1001000" => MX(12)(7 downto 0) <= diRegisters;
        when "1001001" => MY(12) <= diRegisters;
        when "1001010" => MX(13)(7 downto 0) <= diRegisters;
        when "1001011" => MY(13) <= diRegisters;
        when "1001100" => MX(14)(7 downto 0) <= diRegisters;
        when "1001101" => MY(14) <= diRegisters;
        when "1001110" => MX(15)(7 downto 0) <= diRegisters;
        when "1001111" => MY(15) <= diRegisters;
				when "0010000" =>
					MX(0)(8) <= diRegisters(0);
					MX(1)(8) <= diRegisters(1);
					MX(2)(8) <= diRegisters(2);
					MX(3)(8) <= diRegisters(3);
					MX(4)(8) <= diRegisters(4);
					MX(5)(8) <= diRegisters(5);
					MX(6)(8) <= diRegisters(6);
					MX(7)(8) <= diRegisters(7);
				when "1010000" =>
            MX(8)(8) <= diRegisters(0);
            MX(9)(8) <= diRegisters(1);
            MX(10)(8) <= diRegisters(2);
            MX(11)(8) <= diRegisters(3);
            MX(12)(8) <= diRegisters(4);
            MX(13)(8) <= diRegisters(5);
            MX(14)(8) <= diRegisters(6);
            MX(15)(8) <= diRegisters(7);
				when "0010001" =>
					rasterCmp(8) <= diRegisters(7);
					ECM <= diRegisters(6);
					BMM <= diRegisters(5);
					DEN <= diRegisters(4);
					RSEL <= diRegisters(3);
					yscroll <= diRegisters(2 downto 0);
				when "0010010" =>
					rasterCmp(7 downto 0) <= diRegisters;
				when "0010101" =>
					ME(7 downto 0) <= diRegisters;
				when "1010101" =>
          ME(15 downto 8) <= diRegisters;
				when "0010110" =>
					RES <= diRegisters(5);
					MCM <= diRegisters(4);
					CSEL <= diRegisters(3);
					xscroll <= diRegisters(2 downto 0);

				when "0010111" => MYE(7 downto 0) <= diRegisters;
				when "1010111" => MYE(15 downto 8) <= diRegisters;
				when "0011000" =>
					VM <= diRegisters(7 downto 4);
					CB <= diRegisters(3 downto 1);
				when "0011001" =>
					resetLightPenIrq <= diRegisters(3);
					resetIMMC <= diRegisters(2);
					resetIMBC <= diRegisters(1);
					resetRasterIrq <= diRegisters(0);
				when "0011010" =>
					ELP <= diRegisters(3);
					EMMC <= diRegisters(2);
					EMBC <= diRegisters(1);
					ERST <= diRegisters(0);
				when "0011011" => MPRIO(7 downto 0) <= diRegisters;
				when "1011011" => MPRIO(15 downto 8) <= diRegisters;
				when "0011100" =>
					-- MC <= diRegisters;
					MCDelay(7 downto 0) <= diRegisters; -- !!! Krestage 3 hack
				when "1011100" =>
            -- MC <= diRegisters;
            MCDelay(15 downto 8) <= diRegisters; -- !!! Krestage 3 hack
				when "0011101" => MXE(7 downto 0) <= diRegisters;
				when "1011101" => MXE(15 downto 8) <= diRegisters;
				when "0100000" => EC <= diRegisters(3 downto 0);
				when "0100001" => B0C <= diRegisters(3 downto 0);
				when "0100010" => B1C <= diRegisters(3 downto 0);
				when "0100011" => B2C <= diRegisters(3 downto 0);
				when "0100100" => B3C <= diRegisters(3 downto 0);
				when "0100101" => MM0 <= diRegisters(3 downto 0);
				when "0100110" => MM1 <= diRegisters(3 downto 0);
				when "0100111" => spriteColors(0) <= diRegisters(3 downto 0);
				when "0101000" => spriteColors(1) <= diRegisters(3 downto 0);
				when "0101001" => spriteColors(2) <= diRegisters(3 downto 0);
				when "0101010" => spriteColors(3) <= diRegisters(3 downto 0);
				when "0101011" => spriteColors(4) <= diRegisters(3 downto 0);
				when "0101100" => spriteColors(5) <= diRegisters(3 downto 0);
				when "0101101" => spriteColors(6) <= diRegisters(3 downto 0);
				when "0101110" => spriteColors(7) <= diRegisters(3 downto 0);
				when "1100111" => spriteColors(8) <= diRegisters(3 downto 0);
        when "1101000" => spriteColors(9) <= diRegisters(3 downto 0);
        when "1101001" => spriteColors(10) <= diRegisters(3 downto 0);
        when "1101010" => spriteColors(11) <= diRegisters(3 downto 0);
        when "1101011" => spriteColors(12) <= diRegisters(3 downto 0);
        when "1101100" => spriteColors(13) <= diRegisters(3 downto 0);
        when "1101101" => spriteColors(14) <= diRegisters(3 downto 0);
        when "1101110" => spriteColors(15) <= diRegisters(3 downto 0);
        when "0110011" => REGPG <= diRegisters(0); 
        when "1110011" => REGPG <= diRegisters(0); 
				when others => null;
				end case;
			end if;
		end if;
	end process;

-- -----------------------------------------------------------------------
-- Read registers
-- -----------------------------------------------------------------------
readRegisters: process(clk)
	begin
		if rising_edge(clk) then
			case (REGPG & aRegisters) is
			when "0000000" => do <= MX(0)(7 downto 0);
			when "0000001" => do <= MY(0);
			when "0000010" => do <= MX(1)(7 downto 0);
			when "0000011" => do <= MY(1);
			when "0000100" => do <= MX(2)(7 downto 0);
			when "0000101" => do <= MY(2);
			when "0000110" => do <= MX(3)(7 downto 0);
			when "0000111" => do <= MY(3);
			when "0001000" => do <= MX(4)(7 downto 0);
			when "0001001" => do <= MY(4);
			when "0001010" => do <= MX(5)(7 downto 0);
			when "0001011" => do <= MY(5);
			when "0001100" => do <= MX(6)(7 downto 0);
			when "0001101" => do <= MY(6);
			when "0001110" => do <= MX(7)(7 downto 0);
			when "0001111" => do <= MY(7);
			when "1000000" => do <= MX(8)(7 downto 0);
      when "1000001" => do <= MY(8);
      when "1000010" => do <= MX(9)(7 downto 0);
      when "1000011" => do <= MY(9);
      when "1000100" => do <= MX(10)(7 downto 0);
      when "1000101" => do <= MY(10);
      when "1000110" => do <= MX(11)(7 downto 0);
      when "1000111" => do <= MY(11);
      when "1001000" => do <= MX(12)(7 downto 0);
      when "1001001" => do <= MY(12);
      when "1001010" => do <= MX(13)(7 downto 0);
      when "1001011" => do <= MY(13);
      when "1001100" => do <= MX(14)(7 downto 0);
      when "1001101" => do <= MY(14);
      when "1001110" => do <= MX(15)(7 downto 0);
      when "1001111" => do <= MY(15);
			when "0010000" =>
				do <= MX(7)(8) & MX(6)(8) & MX(5)(8) & MX(4)(8)
				& MX(3)(8) & MX(2)(8) & MX(1)(8) & MX(0)(8);
			when "1010000" =>
          do <= MX(15)(8) & MX(14)(8) & MX(13)(8) & MX(12)(8)
          & MX(11)(8) & MX(10)(8) & MX(9)(8) & MX(8)(8);
			when "0010001" => do <= rasterY(8) & ECM & BMM & DEN & RSEL & yscroll;
			when "0010010" => do <= rasterY(7 downto 0);
			when "0010011" => do <= lpX;
			when "0010100" => do <= lpY;
			when "0010101" => do <= ME(7 downto 0);
			when "1010101" => do <= ME(15 downto 8);
			when "0010110" => do <= "11" & RES & MCM & CSEL & xscroll;
			when "0010111" => do <= MYE(7 downto 0);
			when "1010111" => do <= MYE(15 downto 8);
			when "0011000" => do <= VM & CB & '1';
			when "0011001" => do <= IRQ & "111" & ILP & IMMC & IMBC & IRST;
			when "0011010" => do <= "1111" & ELP & EMMC & EMBC & ERST;
			when "0011011" => do <= MPRIO(7 downto 0);
			when "1011011" => do <= MPRIO(15 downto 8);
			when "0011100" => do <= MC(7 downto 0);
			when "1011100" => do <= MC(15 downto 8);
			when "0011101" => do <= MXE(7 downto 0);
			when "1011101" => do <= MXE(15 downto 8);
			when "0011110" => do <= M2M(7 downto 0);
			when "1011110" => do <= M2M(15 downto 8);
			when "0011111" => do <= M2D(7 downto 0);
			when "1011111" => do <= M2D(15 downto 8);
			when "0100000" => do <= "1111" & EC;
			when "0100001" => do <= "1111" & B0C;
			when "0100010" => do <= "1111" & B1C;
			when "0100011" => do <= "1111" & B2C;
			when "0100100" => do <= "1111" & B3C;
			when "0100101" => do <= "1111" & MM0;
			when "0100110" => do <= "1111" & MM1;
			when "0100111" => do <= "1111" & spriteColors(0);
			when "0101000" => do <= "1111" & spriteColors(1);
			when "0101001" => do <= "1111" & spriteColors(2);
			when "0101010" => do <= "1111" & spriteColors(3);
			when "0101011" => do <= "1111" & spriteColors(4);
			when "0101100" => do <= "1111" & spriteColors(5);
			when "0101101" => do <= "1111" & spriteColors(6);
			when "0101110" => do <= "1111" & spriteColors(7);
			when "1100111" => do <= "1111" & spriteColors(8);
      when "1101000" => do <= "1111" & spriteColors(9);
      when "1101001" => do <= "1111" & spriteColors(10);
      when "1101010" => do <= "1111" & spriteColors(11);
      when "1101011" => do <= "1111" & spriteColors(12);
      when "1101100" => do <= "1111" & spriteColors(13);
      when "1101101" => do <= "1111" & spriteColors(14);
      when "1101110" => do <= "1111" & spriteColors(15);
			when others => do <= (others => '1');
			end case;
		end if;
	end process;
end architecture;
