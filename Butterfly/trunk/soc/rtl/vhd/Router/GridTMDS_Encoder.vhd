-------------------------------------------------------------------------------
-- Hacked up for 12b/14b encoding version: Robert Finch
-- File: TMDS_Encoder.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI output on 7-series Xilinx FPGA
-- Date: 30 October 2014
--
-------------------------------------------------------------------------------
-- (c) 2014 Copyright Digilent Incorporated
-- All Rights Reserved
-- 
-- This program is free software; distributed under the terms of BSD 3-clause 
-- license ("Revised BSD License", "New BSD License", or "Modified BSD License")
--
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
-- 3. Neither the name(s) of the above-listed copyright holder(s) nor the names
--    of its contributors may be used to endorse or promote products derived
--    from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-------------------------------------------------------------------------------
--
-- Purpose:
-- This module implements the encoding algorithm outlined in the
-- DVI 1.0 specifications and instantiates the serializer block. The 8-bit data
-- and 3 control signals are encoded and transmitted over the data channel.
-- The sDataOut_p/n ports must connect to top-level ports.
--  
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.GridRouter_Constants.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GridTMDS_Encoder is
   Port (
      PixelClk : in std_logic;   --Recovered TMDS clock x1 (CLKDIV)
      SerialClk : in std_logic;  --Recovered TMDS clock x7 (CLK)
      aRst : in std_logic;       --asynchronous reset; must be reset when PixelClk/SerialClk is not within spec
      
      --Encoded parallel data
      pDataOutRaw : out std_logic_vector(13 downto 0);
      
      --Unencoded parallel data
      pDataOut : in std_logic_vector(11 downto 0);
      pC0 : in std_logic;
      pC1 : in std_logic;
      pVde : in std_logic
   );
end GridTMDS_Encoder;

architecture Behavioral of GridTMDS_Encoder is
signal pDataOut_1 : std_logic_vector(11 downto 0);
signal q_m_1, q_m_xor_1, q_m_xnor_1, q_m_2: std_logic_vector(12 downto 0);
signal control_token_2, q_out_2: std_logic_vector(13 downto 0);
signal n1d_1, n1q_m_2, n0q_m_2 : unsigned(3 downto 0); --range 0-12
signal n1d,n1q_m_1 : unsigned(4 downto 0);  -- will only be 0-12
signal dc_bias_2, cnt_t_3, cnt_t_2 : signed(4 downto 0) := "00000"; --range -12 - +12 + sign
signal pC0_1, pC1_1, pVde_1, pC0_2, pC1_2, pVde_2 : std_logic;
signal cond_not_balanced_2, cond_balanced_2 : std_logic;
signal p1,p2 : std_logic_vector(15 downto 0);

component cntpop16 port (
    i : in std_logic_vector(15 downto 0);
    o : out unsigned(4 downto 0)
);
end component;
begin

-- VHDL can't handle the parameter begin concatonated at the same time as it's
-- passed so two more temp var's are required.
p1 <= "0000" & pDataOut(11 downto 0);
p2 <= "0000" & q_m_1(11 downto 0);

popcnt1: cntpop16
port map (
    i => p1,
    o => n1d
);

popcnt2: cntpop16
port map (
    i => p2,
    o => n1q_m_1
);

----------------------------------------------------------------------------------
-- DVI 1.0 Specs Figure 3-5
-- Pipeline stage 1, minimise transitions
----------------------------------------------------------------------------------
Stage1: process(PixelClk)
begin
	if Rising_Edge(PixelClk) then
		pVde_1 <= pVde;

		n1d_1 <= n1d(3 downto 0);
		pDataOut_1 <= pDataOut; --insert data into the pipeline;
		pC0_1 <= pC0; --insert control into the pipeline;
		pC1_1 <= pC1;
	end if;
end process Stage1;

----------------------------------------------------------------------------------
-- Choose one of the two encoding options based on n1d_1
----------------------------------------------------------------------------------
q_m_xor_1(0) <= pDataOut_1(0);
encode1: for i in 1 to 11 generate
	q_m_xor_1(i) <= q_m_xor_1(i-1) xor pDataOut_1(i);
end generate encode1;
q_m_xor_1(12) <= '1';

q_m_xnor_1(0) <= pDataOut_1(0);
encode2: for i in 1 to 11 generate
	q_m_xnor_1(i) <= q_m_xnor_1(i-1) xnor pDataOut_1(i);
end generate encode2;
q_m_xnor_1(12) <= '0';

q_m_1 <= q_m_xnor_1 when n1d_1 > 6 or (n1d_1 = 6 and pDataOut_1(0) = '0') else
         q_m_xor_1;

----------------------------------------------------------------------------------
-- Pipeline stage 2, balance DC
----------------------------------------------------------------------------------
Stage2: process(PixelClk)
begin
	if Rising_Edge(PixelClk) then
		n1q_m_2 <= n1q_m_1(3 downto 0);
		n0q_m_2 <= 12 - n1q_m_1(3 downto 0);
		q_m_2 <= q_m_1;
		pC0_2 <= pC0_1;
		pC1_2 <= pC1_1;
		pVde_2 <= pVde_1;
	end if;
end process Stage2;

cond_balanced_2 <=   '1' when cnt_t_3 = 0 or n1q_m_2 = 6 else -- DC balanced output
						   '0';
cond_not_balanced_2 <=  '1' when (cnt_t_3 > 0 and n1q_m_2 > 6) or -- too many 1's
									 (cnt_t_3 < 0 and n1q_m_2 < 6) else -- too many 0's
                        '0';

control_token_2 <= 	kCtlTkn0 when pC1_2 = '0' and pC0_2 = '0' else
                     kCtlTkn1 when pC1_2 = '0' and pC0_2 = '1' else
                     kCtlTkn2 when pC1_2 = '1' and pC0_2 = '0' else
                     kCtlTkn3;
							
q_out_2 <=  control_token_2												when pVde_2 = '0' else	--control period
			   not q_m_2(12) & q_m_2(12) & not q_m_2(11 downto 0)    when cond_balanced_2 = '1' and q_m_2(12) = '0' else
			   not q_m_2(12) & q_m_2(12) & q_m_2(11 downto 0)        when cond_balanced_2 = '1' and q_m_2(12) = '1' else
			   '1' & q_m_2(12) & not q_m_2(11 downto 0)             when cond_not_balanced_2 = '1' else
			   '0' & q_m_2(12) & q_m_2(11 downto 0);	--DC balanced

dc_bias_2 <= to_signed(to_integer(n0q_m_2),5) - to_signed(to_integer(n1q_m_2),5);

cnt_t_2 <=  to_signed(0, cnt_t_2'length)                                   when pVde_2 = '0' else	--control period
			   cnt_t_3 + dc_bias_2                                            when cond_balanced_2 = '1' and q_m_2(12) = '0' else
			   cnt_t_3 - dc_bias_2                                            when cond_balanced_2 = '1' and q_m_2(12) = '1' else
			   cnt_t_3 + signed('0' & q_m_2(12 downto 12) & '0') + dc_bias_2	   when cond_not_balanced_2 = '1' else
			   cnt_t_3 - signed('0' & not q_m_2(12 downto 12) & '0') - dc_bias_2;

----------------------------------------------------------------------------------
-- Pipeline stage 3, registered output
----------------------------------------------------------------------------------
Stage3: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      cnt_t_3 <= cnt_t_2;
      pDataOutRaw <= q_out_2; --encoded, ready to be serialized
   end if;
end process Stage3;
		
end Behavioral;
