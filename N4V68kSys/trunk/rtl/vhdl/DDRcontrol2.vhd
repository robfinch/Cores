-- ============================================================================
--        __
--   \\__/ o\    (C) 2017  Robert Finch, Waterloo
--    \  __ /    All rights reserved.
--     \/_//     robfinch<remove>@finitron.ca
--       ||
--
--	DDRcontrol2.v
--  - this controller adapted from originally a controller supplied by
--    Digilent. I've mostly re-written it to use a WISHBONE bus interface
--    and to use cached data on reads.
--
-- This source file is free software: you can redistribute it and/or modify 
-- it under the terms of the GNU Lesser General Public License as published 
-- by the Free Software Foundation, either version 3 of the License, or     
-- (at your option) any later version.                                      
--                                                                          
-- This source file is distributed in the hope that it will be useful,      
-- but WITHOUT ANY WARRANTY; without even the implied warranty of           
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
-- GNU General Public License for more details.                             
--                                                                          
-- You should have received a copy of the GNU General Public License        
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.    
--
-- ============================================================================
--
library ieee;
use ieee.std_logic_1164.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity DDRcontrol2 is
   port (
      -- Common
      clk_200MHz_i         : in    std_logic; -- 200 MHz system clock
      cpu_clk              : in    std_logic;
      rst_i                : in    std_logic; -- active high system reset
      
      -- RAM interface
      cs_i              : in    std_logic;
      cyc_i				: in    std_logic;
      stb_i				: in	std_logic;
      sel_i				: in   std_logic_vector(1 downto 0);
      we_i              : in    std_logic;
      adr_i             : in    std_logic_vector(27 downto 0);
      dat_i             : in    std_logic_vector(15 downto 0);
      dat_o             : out   std_logic_vector(15 downto 0);
      ack_o				   : out   std_logic;
      
      -- DDR3 interface
      ddr3_addr            : out   std_logic_vector(14 downto 0);
      ddr3_ba              : out   std_logic_vector(2 downto 0);
      ddr3_ras_n           : out   std_logic;
      ddr3_cas_n           : out   std_logic;
      ddr3_reset_n         : out   std_logic;
      ddr3_we_n            : out   std_logic;
      ddr3_ck_p            : out   std_logic_vector(0 downto 0);
      ddr3_ck_n            : out   std_logic_vector(0 downto 0);
      ddr3_cke             : out   std_logic_vector(0 downto 0);
      ddr3_dm              : out   std_logic_vector(1 downto 0);
      ddr3_odt             : out   std_logic_vector(0 downto 0);
      ddr3_dq              : inout std_logic_vector(15 downto 0);
      ddr3_dqs_p           : inout std_logic_vector(1 downto 0);
      ddr3_dqs_n           : inout std_logic_vector(1 downto 0)
   );
end DDRcontrol2;

architecture Behavioral of DDRcontrol2 is

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
component mig_7series_0
port (
   -- Inouts
   ddr3_dq              : inout std_logic_vector(15 downto 0);
   ddr3_dqs_p           : inout std_logic_vector(1 downto 0);
   ddr3_dqs_n           : inout std_logic_vector(1 downto 0);
   -- Outputs
   ddr3_addr            : out   std_logic_vector(14 downto 0);
   ddr3_ba              : out   std_logic_vector(2 downto 0);
   ddr3_ras_n           : out   std_logic;
   ddr3_cas_n           : out   std_logic;
   ddr3_we_n            : out   std_logic;
   ddr3_ck_p            : out   std_logic_vector(0 downto 0);
   ddr3_ck_n            : out   std_logic_vector(0 downto 0);
   ddr3_cke             : out   std_logic_vector(0 downto 0);
   ddr3_dm              : out   std_logic_vector(1 downto 0);
   ddr3_odt             : out   std_logic_vector(0 downto 0);
   ddr3_reset_n         : out   std_logic;
   -- Inputs
   sys_clk_i            : in    std_logic;
   sys_rst              : in    std_logic;
   
   -- user interface signals
   app_addr             : in    std_logic_vector(28 downto 0);
   app_cmd              : in    std_logic_vector(2 downto 0);
   app_en               : in    std_logic;
   app_wdf_data         : in    std_logic_vector(127 downto 0);
   app_wdf_end          : in    std_logic;
   app_wdf_mask         : in    std_logic_vector(15 downto 0);
   app_wdf_wren         : in    std_logic;
   app_rd_data          : out   std_logic_vector(127 downto 0);
   app_rd_data_end      : out   std_logic;
   app_rd_data_valid    : out   std_logic;
   app_rdy              : out   std_logic;
   app_wdf_rdy          : out   std_logic;
   app_sr_req           : in    std_logic;
   app_sr_active        : out   std_logic;
   app_ref_req          : in    std_logic;
   app_ref_ack          : out   std_logic;
   app_zq_req           : in    std_logic;
   app_zq_ack           : out   std_logic;
   ui_clk               : out   std_logic;
   ui_clk_sync_rst      : out   std_logic;
   init_calib_complete  : out   std_logic);
end component;

------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------
-- FSM
type state_type is (stIdle, stPreset, stSendData, stSetCmdRd, stSetCmdWr,
                    stWaitCen, stReRead);

------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------------
-- ddr commands
constant CMD_WRITE         : std_logic_vector(2 downto 0) := "000";
constant CMD_READ          : std_logic_vector(2 downto 0) := "001";

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- state machine
signal cState, nState      : state_type; 

-- global signals
signal mem_ui_clk          : std_logic;
signal mem_ui_rst          : std_logic;
signal rst                 : std_logic;
signal rstn                : std_logic;
signal sreg                : std_logic_vector(1 downto 0);

-- WB internal signals
signal cyc_i_int			: std_logic;
signal stb_i_int			: std_logic;
signal adr_i_int           : std_logic_vector(27 downto 0);
signal dat_i_int        : std_logic_vector(15 downto 0);
signal cs_i_int         : std_logic;
signal we_i_int         : std_logic;
signal sel_i_int            : std_logic_vector(1 downto 0);

signal last_read_adr        : std_logic_vector(27 downto 0);
signal last_read_adr_valid : std_logic;
signal last_data           : std_logic_vector(127 downto 0);
signal dtack_int           : std_logic;
signal ack                 : std_logic;

-- ddr user interface signals
signal mem_addr            : std_logic_vector(28 downto 0); -- address for current request
signal mem_cmd             : std_logic_vector(2 downto 0); -- command for current request
signal mem_en              : std_logic; -- active-high strobe for 'cmd' and 'addr'
signal mem_rdy             : std_logic;
signal mem_wdf_rdy         : std_logic; -- write data FIFO is ready to receive data (wdf_rdy = 1 & wdf_wren = 1)
signal mem_wdf_data        : std_logic_vector(127 downto 0);
signal mem_wdf_end         : std_logic; -- active-high last 'wdf_data'
signal mem_wdf_mask        : std_logic_vector(15 downto 0);
signal mem_wdf_wren        : std_logic;
signal mem_rd_data         : std_logic_vector(127 downto 0);
signal mem_rd_data_end     : std_logic; -- active-high last 'rd_data'
signal mem_rd_data_valid   : std_logic; -- active-high 'rd_data' valid
signal calib_complete      : std_logic; -- active-high calibration complete

------------------------------------------------------------------------
-- Signal attributes (debugging)
------------------------------------------------------------------------
attribute FSM_ENCODING              : string;
attribute FSM_ENCODING of cState    : signal is "GRAY";

attribute ASYNC_REG                 : string;
attribute ASYNC_REG of sreg         : signal is "TRUE";

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin
------------------------------------------------------------------------
-- Registering the active-low reset for the MIG component
------------------------------------------------------------------------
   RSTSYNC: process(clk_200MHz_i)
   begin
      if rising_edge(clk_200MHz_i) then
         sreg <= sreg(0) & rst_i;
         rstn <= not sreg(1);
      end if;
   end process RSTSYNC;
   
------------------------------------------------------------------------
-- DDR controller instance
------------------------------------------------------------------------
   Inst_DDR: mig_7series_0
   port map (
      ddr3_dq              => ddr3_dq,
      ddr3_dqs_p           => ddr3_dqs_p,
      ddr3_dqs_n           => ddr3_dqs_n,
      ddr3_addr            => ddr3_addr,
      ddr3_ba              => ddr3_ba,
      ddr3_ras_n           => ddr3_ras_n,
      ddr3_cas_n           => ddr3_cas_n,
      ddr3_we_n            => ddr3_we_n,
      ddr3_ck_p            => ddr3_ck_p,
      ddr3_ck_n            => ddr3_ck_n,
      ddr3_cke             => ddr3_cke,
      ddr3_dm              => ddr3_dm,
      ddr3_odt             => ddr3_odt,
      ddr3_reset_n         => ddr3_reset_n,
      -- Inputs
      sys_clk_i            => clk_200MHz_i,
      sys_rst              => rstn,
      -- user interface signals
      app_addr             => mem_addr,
      app_cmd              => mem_cmd,
      app_en               => mem_en,
      app_wdf_data         => mem_wdf_data,
      app_wdf_end          => mem_wdf_end,
      app_wdf_mask         => mem_wdf_mask,
      app_wdf_wren         => mem_wdf_wren,
      app_rd_data          => mem_rd_data,
      app_rd_data_end      => mem_rd_data_end,
      app_rd_data_valid    => mem_rd_data_valid,
      app_rdy              => mem_rdy,
      app_wdf_rdy          => mem_wdf_rdy,
      app_sr_req           => '0',
      app_sr_active        => open,
      app_ref_req          => '0',
      app_ref_ack          => open,
      app_zq_req           => '0',
      app_zq_ack           => open,
      ui_clk               => mem_ui_clk,
      ui_clk_sync_rst      => mem_ui_rst,
      init_calib_complete  => calib_complete);

------------------------------------------------------------------------
-- Registering all inputs of the state machine to 'mem_ui_clk' domain
------------------------------------------------------------------------
   REG_IN: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         cs_i_int <= cs_i;
      	 cyc_i_int <= cyc_i;
      	 stb_i_int <= stb_i;
         sel_i_int <= sel_i;
         adr_i_int <= adr_i;
         dat_i_int <= dat_i;
         we_i_int <= we_i;
      end if;
   end process REG_IN;
   
------------------------------------------------------------------------
-- State Machine
------------------------------------------------------------------------
-- Register states
   SYNC_PROCESS: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if mem_ui_rst = '1' then
            cState <= stIdle;
         else
            cState <= nState;
         end if;
      end if;
   end process SYNC_PROCESS;

-- Next state logic
   NEXT_STATE_DECODE: process(cState, calib_complete, cs_i_int, cyc_i_int, stb_i_int,
   mem_rdy, mem_wdf_rdy, we_i_int)
   begin
      nState <= cState;
      case(cState) is
         -- If calibration is done successfully and CEN is
         -- deasserted then start a new transaction
         when stIdle =>
            if cs_i_int = '1' and cyc_i_int = '1' and stb_i_int = '1' and
               calib_complete = '1' then
               -- if repeating a read of the same address just go to the wait cen state
               if we_i_int = '0' and last_read_adr_valid = '1' and adr_i_int(27 downto 3) = last_read_adr(27 downto 3) then
                   nState <= stReRead;
               else
                   nState <= stPreset;
               end if;
            end if;
         -- In this state we store the address and data to
         -- be written or the address to read from. We need
         -- this additional state to make sure that all input
         -- transitions are fully settled and registered
         when stPreset =>
            if we_i_int = '1' then
               nState <= stSendData;
            else
               nState <= stSetCmdRd;
            end if;
         -- In a write transaction the data it written first
         -- giving higher priority to 'mem_wdf_rdy' frag over
         -- 'mem_rdy'
         when stSendData =>
            if mem_wdf_rdy = '1' then
               nState <= stSetCmdWr;
            end if;
         -- Sending the read command and wait for the 'mem_rdy'
         -- frag to be asserted (in case it's not)
         when stSetCmdRd =>
            if mem_rdy = '1' then
               nState <= stWaitCen;
            end if;
         -- Sending the write command after the data has been
         -- written to the controller FIFO and wait ro the
         -- 'mem_rdy' frag to be asserted (in case it's not)
         when stSetCmdWr =>
            if mem_rdy = '1' then
               nState <= stWaitCen;
            end if;
         -- After sending all the control signals and data, we
         -- wait for the external CEN to signal transaction
         -- end
         when stWaitCen =>
            if cs_i_int = '0' then
               nState <= stIdle;
            end if;
         when stReRead =>
            if cs_i_int = '0' then
               nState <= stIdle;
            end if;
         when others => nState <= stIdle;            
      end case;      
   end process;

------------------------------------------------------------------------
-- Generating the FIFO control and command signals according to the 
-- current state of the FSM
------------------------------------------------------------------------
   MEM_WR_CTL: process(cState)
   begin
      if cState = stSendData then
         mem_wdf_wren <= '1';
         mem_wdf_end <= '1';
      else
         mem_wdf_wren <= '0';
         mem_wdf_end <= '0';
      end if;
   end process MEM_WR_CTL;
   
   MEM_CTL: process(cState)
   begin
      if cState = stSetCmdRd then
         mem_en <= '1';
         mem_cmd <= CMD_READ;
      elsif cState = stSetCmdWr then
         mem_en <= '1';
         mem_cmd <= CMD_WRITE;
      else
         mem_en <= '0';
         mem_cmd <= (others => '0');
      end if;
   end process MEM_CTL;
   
   DTACK_CTL: process(mem_ui_clk)
   begin
        if rising_edge(mem_ui_clk) then
            if rst_i = '1' then
                dtack_int <= '1';
                last_read_adr_valid <= '0';
            end if;
            if cState = stWaitCen then
                -- read cycle: wait for rd_data_valid
                -- write cyle: done already
                if we_i_int='0' then
                    if mem_rd_data_valid = '1' then
                         dtack_int <= '0';
                    end if;
                    last_read_adr_valid <= mem_rd_data_valid;
                    last_read_adr <= adr_i_int;
                else
                    dtack_int <= '0';
                    last_read_adr_valid <= '0';
                end if;
            elsif cState = stReRead then
                dtack_int <= '0';
            else
                dtack_int <= '1';
            end if;
   		end if;
   end process DTACK_CTL;

    ACKO: process(cpu_clk)
    begin
        if rising_edge(cpu_clk) then
            if rst_i = '1' then
                ack <= '0';
            elsif stb_i = '0' then
                ack <= '0';
            elsif dtack_int='0' then
                ack <= '1';
            end if;
        end if;
    end process ACKO;
    
    ACKOO: process(stb_i,cs_i,ack)
    begin
    	if stb_i = '1' and cs_i = '1' then
    		ack_o <= ack;
    	else
    		ack_o <= '0';
    	end if;
    end process ACKOO;

------------------------------------------------------------------------
-- Decoding the least significant 3 bits of the address and creating
-- accordingly the 'mem_wdf_mask'
------------------------------------------------------------------------
   WR_DATA_MSK: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if cState = stPreset then
         	case(adr_i_int(2 downto 0) & sel_i_int) is
         	when "00011" => mem_wdf_mask <= "1111111111111100";
			when "00010" =>	mem_wdf_mask <= "1111111111111101";
         	when "00001" =>	mem_wdf_mask <= "1111111111111110";
         	when "00111" => mem_wdf_mask <= "1111111111110011";
			when "00110" =>	mem_wdf_mask <= "1111111111110111";
         	when "00101" =>	mem_wdf_mask <= "1111111111111011";
         	when "01011" => mem_wdf_mask <= "1111111111001111";
			when "01010" =>	mem_wdf_mask <= "1111111111011111";
         	when "01001" =>	mem_wdf_mask <= "1111111111101111";
         	when "01111" => mem_wdf_mask <= "1111111100111111";
			when "01110" =>	mem_wdf_mask <= "1111111101111111";
         	when "01101" =>	mem_wdf_mask <= "1111111110111111";
         	when "10011" => mem_wdf_mask <= "1111110011111111";
			when "10010" =>	mem_wdf_mask <= "1111110111111111";
         	when "10001" =>	mem_wdf_mask <= "1111111011111111";
         	when "10111" => mem_wdf_mask <= "1111001111111111";
			when "10110" =>	mem_wdf_mask <= "1111011111111111";
         	when "10101" =>	mem_wdf_mask <= "1111101111111111";
         	when "11011" => mem_wdf_mask <= "1100111111111111";
			when "11010" =>	mem_wdf_mask <= "1101111111111111";
         	when "11001" =>	mem_wdf_mask <= "1110111111111111";
         	when "11111" => mem_wdf_mask <= "0011111111111111";
			when "11110" =>	mem_wdf_mask <= "0111111111111111";
         	when "11101" =>	mem_wdf_mask <= "1011111111111111";
         	when others =>  mem_wdf_mask <= "1111111111111111";
            end case;
         end if;
      end if;
   end process WR_DATA_MSK;
   
------------------------------------------------------------------------
-- Registering write data and read/write address
------------------------------------------------------------------------
   WR_DATA_ADDR: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if cState = stPreset then
            mem_wdf_data <= dat_i_int(15 downto 0) &
            				dat_i_int(15 downto 0) &
            				dat_i_int(15 downto 0) &
            				dat_i_int(15 downto 0) &
            				dat_i_int(15 downto 0) &
            				dat_i_int(15 downto 0) &
            				dat_i_int(15 downto 0) &
            				dat_i_int(15 downto 0);
         end if;
      end if;
   end process WR_DATA_ADDR;

   WR_ADDR: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if cState = stPreset then
            mem_addr <= adr_i_int(27 downto 3) & "0000";
         end if;
      end if;
   end process WR_ADDR;

------------------------------------------------------------------------
-- select output data
------------------------------------------------------------------------
   RD_DATA: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if cState = stWaitCen and mem_rd_data_valid = '1' and 
            mem_rd_data_end = '1' then
            last_data <= mem_rd_data;
            case(adr_i_int(2 downto 0)) is
            when "000" => dat_o <= mem_rd_data(15 downto 0);
            when "001" => dat_o <= mem_rd_data(31 downto 16);
            when "010" => dat_o <= mem_rd_data(47 downto 32);
            when "011" => dat_o <= mem_rd_data(63 downto 48);
            when "100" => dat_o <= mem_rd_data(79 downto 64);
            when "101" => dat_o <= mem_rd_data(95 downto 80);
            when "110" => dat_o <= mem_rd_data(111 downto 96);
            when others => dat_o <= mem_rd_data(127 downto 112);
            end case;
         elsif cState = stReRead then
             case(adr_i_int(2 downto 0)) is
             when "000" => dat_o <= last_data(15 downto 0);
             when "001" => dat_o <= last_data(31 downto 16);
             when "010" => dat_o <= last_data(47 downto 32);
             when "011" => dat_o <= last_data(63 downto 48);
             when "100" => dat_o <= last_data(79 downto 64);
             when "101" => dat_o <= last_data(95 downto 80);
             when "110" => dat_o <= last_data(111 downto 96);
             when others => dat_o <= last_data(127 downto 112);
             end case;
         end if;
      end if;
   end process RD_DATA;

end Behavioral;
