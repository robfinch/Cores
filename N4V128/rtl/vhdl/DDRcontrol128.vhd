-- ============================================================================
--        __
--   \\__/ o\    (C) 2017  Robert Finch, Waterloo
--    \  __ /    All rights reserved.
--     \/_//     robfinch<remove>@finitron.ca
--       ||
--
--	DDRcontrol128.v
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
entity DDRcontrol128 is
   port (
      -- Common
      clk_200MHz_i         : in    std_logic; -- 200 MHz system clock
      cpu_clk              : in    std_logic;
      rst_i                : in    std_logic; -- active high system reset
      
      -- Video master
      vcyc_i			   : in    std_logic;
      vstb_i			   : in	std_logic;
      vsel_i			   : in   std_logic_vector(15 downto 0);
      vwe_i                : in    std_logic;
      vadr_i               : in    std_logic_vector(28 downto 0);
      vdat_i               : in    std_logic_vector(127 downto 0);
      vdat_o               : out   std_logic_vector(127 downto 0);
      vack_o			   : out   std_logic;
      
      -- AV Controller
      acyc_i			   : in    std_logic;
      astb_i			   : in	std_logic;
      asel_i			   : in   std_logic_vector(15 downto 0);
      awe_i                : in    std_logic;
      aadr_i               : in    std_logic_vector(28 downto 0);
      adat_i               : in    std_logic_vector(127 downto 0);
      adat_o               : out   std_logic_vector(127 downto 0);
      aack_o			   : out   std_logic;

      -- CPU
      ccs_i                : in    std_logic;
      ccyc_i			   : in    std_logic;
      cstb_i			   : in	std_logic;
      csel_i			   : in   std_logic_vector(3 downto 0);
      cwe_i                : in    std_logic;
      cadr_i               : in    std_logic_vector(28 downto 0);
      cdat_i               : in    std_logic_vector(31 downto 0);
      cdat_o               : out   std_logic_vector(31 downto 0);
      cack_o			   : out   std_logic;

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
                    stWaitCen, stReRead, stMastered);

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
signal adr_i_int           : std_logic_vector(28 downto 0);
signal dat_i_int        : std_logic_vector(127 downto 0);
signal cs_i_int         : std_logic;
signal we_i_int         : std_logic;
signal sel_i_int            : std_logic_vector(15 downto 0);

signal last_read_adr        : std_logic_vector(27 downto 0);
signal last_read_adr_valid : std_logic;
signal last_data           : std_logic_vector(127 downto 0);
signal ack_int           : std_logic;
signal ack                 : std_logic;
signal ackv	: std_logic;
signal acka : std_logic;
signal ackc : std_logic;

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

signal burst_ctr			: std_logic_vector(4 downto 0);
	
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
      	 if cState = stIdle then
      	 	ackv <= '0';
      	 	acka <= '0';
      	 	ackc <= '0';
      	 	if vcyc_i= '1' then
		      	 cyc_i_int <= vcyc_i;
		      	 stb_i_int <= vstb_i;
		         sel_i_int <= vsel_i;
		         adr_i_int <= vadr_i;
		         dat_i_int <= vdat_i;
		         we_i_int <= vwe_i;
		         ackv <= '1';
      	 	elsif acyc_i = '1' then
		      	 cyc_i_int <= acyc_i;
		      	 stb_i_int <= astb_i;
		         sel_i_int <= asel_i;
		         adr_i_int <= aadr_i;
		         dat_i_int <= adat_i;
		         we_i_int <= awe_i;
		         acka <= '1';
      		elsif ccyc_i = '1' and cs_i = '1' then
		      	 cyc_i_int <= ccyc_i;
		      	 stb_i_int <= cstb_i;
		      	 case(cadr_i(3 downto 2))
		      	 when "00" => sel_i_in <= "000000" & csel_i;
		      	 when "01"=> sel_i_in <= "0000" & csel_i & "00";
		      	 when "10"=> sel_i_in <= "00" & csel_i & "0000";
		      	 when others => sel_i_in <= csel_i & "000000";
		      	 end case;
		         adr_i_int <= cadr_i;
		         dat_i_int <= cdat_i & cdat_i & cdat_i & cdat_i;
		         we_i_int <= cwe_i;
		         ackc <= '1';
		    else
		      	 cyc_i_int <= '0';
		      	 stb_i_int <= '0';
		         sel_i_int <= X"0000";
		         we_i_int <= '0';
      		end if;
     	 end if;
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
   NEXT_STATE_DECODE: process(cState, calib_complete, cyc_i_int, stb_i_int,
   mem_rdy, mem_wdf_rdy, we_i_int)
   begin
      nState <= cState;
      case(cState) is
         -- If calibration is done successfully and CEN is
         -- deasserted then start a new transaction
         when stIdle =>
         	if vcyc_i = '1' or acyc_i = '1' or ccyc_i = '1' and calib_complete = '1' then
         		nState <= stMastered;
         	end if;
         when stMastered =>
            if cyc_i_int = '1' and stb_i_int = '1' then
               -- if repeating a read of the same address just go to the wait cen state
               if we_i_int = '0' and last_read_adr_valid = '1' and adr_i_int(28 downto 4) = last_read_adr(28 downto 4) then
                   nState <= stReRead;
               else
                   nState <= stPreset;
               end if;
            -- the following should not happen, but set back to idle to prevent lock-up
            else
            	nState <= stIdle;
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
            if mem_rdy = '1' and NOT ackv then
               nState <= stWaitCen;
            elsif mem_rdy = '1' and ackv and burst_ctr = X"F" then
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
            if cyc_i_int = '0' then
               nState <= stIdle;
            end if;
         when stReRead =>
            if cyc_i_int = '0' then
               nState <= stIdle;
            end if;
         when others => nState <= stIdle;            
      end case;      
   end process;

	BURST: process (mem_ui_clk)
	begin
		if rising_edge (mem_ui_clk) then
			if cState = stIdle then
				burst_ctr <= X"0";
			elsif cState = stSetCmdRd and mem_rdy = '1' then
				burst_ctr <= burst_ctr + X"1";
			elsif cState = stWaitCen and mem_rd_data_valid = '1' then
				burst_ctr <= burst_ctr + X"1";
			end if;
		end if;
	end process BURST;

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
   
   ACK_CTL: process(mem_ui_clk)
   begin
        if rising_edge(mem_ui_clk) then
            if rst_i = '1' then
                ack_int <= '0';
                last_read_adr_valid <= '0';
            end if;
            if cState = stWaitCen then
                -- read cycle: wait for rd_data_valid
                -- write cyle: done already
                if we_i_int='0' then
                    if mem_rd_data_valid = '1' then
                         ack_int <= '1';
                    end if;
                    last_read_adr_valid <= mem_rd_data_valid;
                    last_read_adr <= adr_i_int;
                else
                    ack_int <= '1';
                    last_read_adr_valid <= '0';
                end if;
            elsif cState = stReRead then
                ack_int <= '1';
            else
                ack_int <= '0';
            end if;
   		end if;
   end process ACK_CTL;

    ACKO: process(cpu_clk)
    begin
        if rising_edge(cpu_clk) then
            if rst_i = '1' then
                ack <= '0';
            elsif vstb_i = '0' and astb_i = '0' and cstb_i = '0' then
                ack <= '0';
            elsif ack_int='1' then
                ack <= '1';
            end if;
        end if;
    end process ACKO;
    
    ACKOO: process(cstb_i,ccs_i,ack,vstb_i,astb_i,acka,ackv,ackc)
    begin
    	if cstb_i = '1' and ccs_i = '1' then
    		cack_o <= ack and ackc;
    	else
    		cack_o <= '0';
    	end if;
    	if vstb_i = '1' then
    		vack_o <= ack and ackv;
    	else
    		vack_o <= '0';
    	end if;
    	if astb_i = '1' then
    		aack_o <= ack and acka;
    	else
    		aack_o <= '0';
    	end if;
    end process ACKOO;

------------------------------------------------------------------------
-- write data mask
------------------------------------------------------------------------
   WR_DATA_MSK: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if cState = stPreset then
         	mem_wdf_mask <= NOT sel_i_int;
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
            mem_wdf_data <= dat_i_int;
         end if;
      end if;
   end process WR_DATA_ADDR;

   WR_ADDR: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if cState = stPreset then
            mem_addr <= adr_i_int(28 downto 4) & "0000";
         elsif cState = stSetCmdRd and mem_rdy = '1' then
         	mem_addr <= mem_addr + 16;
         end if;
      end if;
   end process WR_ADDR;

------------------------------------------------------------------------
-- select output data
------------------------------------------------------------------------
   RD_DATA: process(mem_ui_clk)
   begin
      if rising_edge(mem_ui_clk) then
         if cState = stWaitCen and mem_rd_data_valid = '1' then
            last_data <= mem_rd_data;
            if ackc = '1' then
	            case(adr_i_int(3 downto 2)) is
	            when "00" => cdat_o <= mem_rd_data(31 downto 0);
	            when "01" => cdat_o <= mem_rd_data(63 downto 32);
	            when "10" => cdat_o <= mem_rd_data(95 downto 64);
	            when "11" => cdat_o <= mem_rd_data(127 downto 96);
	            end case;
	        elsif ackv = '1' then
	        	vdat_o <= mem_rd_data;
	        elsif acka = '1' then
	        	adat_o <= mem_rd_data;
	        end if;
         elsif cState = stReRead then
         	if ackc = '1' then
				case(adr_i_int(3 downto 2)) is
				when "00" => cdat_o <= last_data(31 downto 0);
				when "01" => cdat_o <= last_data(63 downto 32);
				when "10" => cdat_o <= last_data(95 downto 64);
				when "11" => cdat_o <= last_data(127 downto 96);
				end case;
         	elsif ackv = '1' then
         		vdat_o <= last_data;
         	elsif acka = '1' then
         		adat_o <= last_data;
        	end if;
         end if;
      end if;
   end process RD_DATA;

end Behavioral;
