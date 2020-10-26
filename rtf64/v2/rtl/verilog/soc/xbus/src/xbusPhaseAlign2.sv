module xbusPhaseAlign();
endmodule

entity xbusPhaseAlign is
   Generic (
      kParallelWidth : natural := 14;
      kUseFastAlgorithm : boolean := true;
      kCtlTknCount : natural := 3; -- was 128 how many subsequent control tokens make a valid blank detection
      kIDLY_TapValuePs : natural := 78; --delay in ps per tap
      kIDLY_TapWidth : natural := 5); --number of bits for IDELAYE2 tap counter
   Port (
      pRst : in STD_LOGIC;
      pTimeoutOvf : in std_logic;   --50ms timeout expired
      pTimeoutRst : out std_logic;  --reset timeout
      PixelClk : in STD_LOGIC;
      pData : in STD_LOGIC_VECTOR (kParallelWidth-1 downto 0);
      pIDLY_CE : out STD_LOGIC;
      pIDLY_INC : out STD_LOGIC;
      pIDLY_CNT : in STD_LOGIC_VECTOR (kIDLY_TapWidth-1 downto 0);
      pIDLY_LD : out STD_LOGIC; --load default tap value 
      pAligned : out STD_LOGIC;
      pError : out STD_LOGIC;
      pEyeSize : out STD_LOGIC_VECTOR(kIDLY_TapWidth-1 downto 0));
end xbusPhaseAlign;

