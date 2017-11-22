-------------------------------------------------------------------------------
--
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

use work.DVI_Constants.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TMDS_Encoder is
   Port (
      PixelClk : in std_logic;   --Recovered TMDS clock x1 (CLKDIV)
      SerialClk : in std_logic;  --Recovered TMDS clock x5 (CLK)
      aRst : in std_logic;       --asynchronous reset; must be reset when PixelClk/SerialClk is not within spec
      
      --Encoded parallel data
      pDataOutRaw : out std_logic_vector(9 downto 0);
      
      --Unencoded parallel data
      pDataOut : in std_logic_vector(7 downto 0);
      pC0 : in std_logic;
      pC1 : in std_logic;
      pVde : in std_logic
   );
end TMDS_Encoder;

architecture Behavioral of TMDS_Encoder is
signal pDataOut_1 : std_logic_vector(7 downto 0);
signal q_m_1, q_m_xor_1, q_m_xnor_1, q_m_2: std_logic_vector(8 downto 0);
signal control_token_2, q_out_2: std_logic_vector(9 downto 0);
signal n1d_1, n1q_m_2, n0q_m_2, n1q_m_1 : unsigned(3 downto 0); --range 0-8
signal dc_bias_2, cnt_t_3, cnt_t_2 : signed(4 downto 0) := "00000"; --range -8 - +8 + sign
signal pC0_1, pC1_1, pVde_1, pC0_2, pC1_2, pVde_2 : std_logic;
signal cond_not_balanced_2, cond_balanced_2 : std_logic;

--function sum_bits(u : std_logic_vector) return unsigned(3 downto 0) is
--   variable sum : unsigned(3 downto 0);
--	begin
--      assert u'length < 16 report "sum_bits error";
--      sum := to_unsigned(0,4);
--		for i in u'range loop
--        sum := sum + unsigned(u(i downto i));
--		end loop;
--		return sum;
--	end sum_bits;

function cntpop8(u : in std_logic_vector(7 downto 0))
return integer is
    begin
        case u is
        when "00000000" => return 0;
        when "00000001" => return 1;
        when "00000010" => return 1;
		when "00000011" => return 2;
        when "00000100" => return 1;
        when "00000101" => return 2;
        when "00000110" => return 2;
        when "00000111" => return 3;
        when "00001000" => return 1;
        when "00001001" => return 2;
        when "00001010" => return 2;
        when "00001011" => return 3;
        when "00001100" => return 2;
        when "00001101" => return 3;
        when "00001110" => return 3;
        when "00001111" => return 4;
             
        when "00010000" => return 1;
        when "00010001" => return 2;
        when "00010010" => return 2;
        when "00010011" => return 3;
        when "00010100" => return 2;
        when "00010101" => return 3;
        when "00010110" => return 3;
        when "00010111" => return 4;
        when "00011000" => return 2;
        when "00011001" => return 3;
        when "00011010" => return 3;
        when "00011011" => return 4;
        when "00011100" => return 3;
        when "00011101" => return 4;
        when "00011110" => return 4;
        when "00011111" => return 5;
             
        when "00100000" => return 1;
        when "00100001" => return 2;
        when "00100010" => return 2;
        when "00100011" => return 3;
        when "00100100" => return 2;
        when "00100101" => return 3;
        when "00100110" => return 3;
        when "00100111" => return 4;
        when "00101000" => return 2;
        when "00101001" => return 3;
        when "00101010" => return 3;
        when "00101011" => return 4;
        when "00101100" => return 3;
        when "00101101" => return 4;
        when "00101110" => return 4;
        when "00101111" => return 5;
             
        when "00110000" => return 2;
        when "00110001" => return 3;
        when "00110010" => return 3;
        when "00110011" => return 4;
        when "00110100" => return 3;
        when "00110101" => return 4;
        when "00110110" => return 4;
        when "00110111" => return 5;
        when "00111000" => return 3;
        when "00111001" => return 4;
        when "00111010" => return 4;
        when "00111011" => return 5;
        when "00111100" => return 4;
        when "00111101" => return 5;
        when "00111110" => return 5;
        when "00111111" => return 6;
             
        -- 44 - 1    
        when "01000000" => return 1;
        when "01000001" => return 2;
        when "01000010" => return 2;
        when "01000011" => return 3;
        when "01000100" => return 2;
        when "01000101" => return 3;
        when "01000110" => return 3;
        when "01000111" => return 4;
        when "01001000" => return 2;
        when "01001001" => return 3;
        when "01001010" => return 3;
        when "01001011" => return 4;
        when "01001100" => return 3;
        when "01001101" => return 4;
        when "01001110" => return 4;
        when "01001111" => return 5;

        when "01010000" => return 2;
        when "01010001" => return 3;
        when "01010010" => return 3;
        when "01010011" => return 4;
        when "01010100" => return 3;
        when "01010101" => return 4;
        when "01010110" => return 4;
        when "01010111" => return 5;
        when "01011000" => return 3;
        when "01011001" => return 4;
        when "01011010" => return 4;
        when "01011011" => return 5;
        when "01011100" => return 4;
        when "01011101" => return 5;
        when "01011110" => return 5;
        when "01011111" => return 6;
             
        when "01100000" => return 2;
        when "01100001" => return 3;
        when "01100010" => return 3;
        when "01100011" => return 4;
        when "01100100" => return 3;
        when "01100101" => return 4;
        when "01100110" => return 4;
        when "01100111" => return 5;
        when "01101000" => return 3;
        when "01101001" => return 4;
        when "01101010" => return 4;
        when "01101011" => return 5;
        when "01101100" => return 4;
        when "01101101" => return 5;
        when "01101110" => return 5;
        when "01101111" => return 6;
             
        when "01110000" => return 3;
        when "01110001" => return 4;
        when "01110010" => return 4;
        when "01110011" => return 5;
        when "01110100" => return 4;
        when "01110101" => return 5;
        when "01110110" => return 5;
        when "01110111" => return 6;
        when "01111000" => return 4;
        when "01111001" => return 5;
        when "01111010" => return 5;
        when "01111011" => return 6;
        when "01111100" => return 5;
        when "01111101" => return 6;
        when "01111110" => return 6;
        when "01111111" => return 7;

        --  - 2    
        when "10000000" => return 1;
        when "10000001" => return 2;
        when "10000010" => return 2;
        when "10000011" => return 3;
        when "10000100" => return 2;
        when "10000101" => return 3;
        when "10000110" => return 3;
        when "10000111" => return 4;
        when "10001000" => return 2;
        when "10001001" => return 3;
        when "10001010" => return 3;
        when "10001011" => return 4;
        when "10001100" => return 3;
        when "10001101" => return 4;
        when "10001110" => return 4;
        when "10001111" => return 5;

        when "10010000" => return 2;
        when "10010001" => return 3;
        when "10010010" => return 3;
        when "10010011" => return 4;
        when "10010100" => return 3;
        when "10010101" => return 4;
        when "10010110" => return 4;
        when "10010111" => return 5;
        when "10011000" => return 3;
        when "10011001" => return 4;
        when "10011010" => return 4;
        when "10011011" => return 5;
        when "10011100" => return 4;
        when "10011101" => return 5;
        when "10011110" => return 5;
        when "10011111" => return 6;
            
        when "10100000" => return 2;
        when "10100001" => return 3;
        when "10100010" => return 3;
        when "10100011" => return 4;
        when "10100100" => return 3;
        when "10100101" => return 4;
        when "10100110" => return 4;
        when "10100111" => return 5;
        when "10101000" => return 3;
        when "10101001" => return 4;
        when "10101010" => return 4;
        when "10101011" => return 5;
        when "10101100" => return 4;
        when "10101101" => return 5;
        when "10101110" => return 5;
        when "10101111" => return 6;
                               
        when "10110000" => return 3;
        when "10110001" => return 4;
        when "10110010" => return 4;
        when "10110011" => return 5;
        when "10110100" => return 4;
        when "10110101" => return 5;
        when "10110110" => return 5;
        when "10110111" => return 6;
        when "10111000" => return 4;
        when "10111001" => return 5;
        when "10111010" => return 5;
        when "10111011" => return 6;
        when "10111100" => return 5;
        when "10111101" => return 6;
        when "10111110" => return 6;
        when "10111111" => return 7;
            
        -- 44 - 3    
        when "11000000" => return 2;
        when "11000001" => return 3;
        when "11000010" => return 3;
        when "11000011" => return 4;
        when "11000100" => return 3;
        when "11000101" => return 4;
        when "11000110" => return 4;
        when "11000111" => return 5;
        when "11001000" => return 3;
        when "11001001" => return 4;
        when "11001010" => return 4;
        when "11001011" => return 5;
        when "11001100" => return 4;
        when "11001101" => return 5;
        when "11001110" => return 5;
        when "11001111" => return 6;
                               
        when "11010000" => return 3;
        when "11010001" => return 4;
        when "11010010" => return 4;
        when "11010011" => return 5;
        when "11010100" => return 4;
        when "11010101" => return 5;
        when "11010110" => return 5;
        when "11010111" => return 6;
        when "11011000" => return 4;
        when "11011001" => return 5;
        when "11011010" => return 5;
        when "11011011" => return 6;
        when "11011100" => return 5;
        when "11011101" => return 6;
        when "11011110" => return 6;
        when "11011111" => return 7;
            
        when "11100000" => return 3;
        when "11100001" => return 4;
        when "11100010" => return 4;
        when "11100011" => return 5;
        when "11100100" => return 4;
        when "11100101" => return 5;
        when "11100110" => return 5;
        when "11100111" => return 6;
        when "11101000" => return 4;
        when "11101001" => return 5;
        when "11101010" => return 5;
        when "11101011" => return 6;
        when "11101100" => return 5;
        when "11101101" => return 6;
        when "11101110" => return 6;
        when "11101111" => return 7;
                               
        when "11110000" => return 4;
        when "11110001" => return 5;
        when "11110010" => return 5;
        when "11110011" => return 6;
        when "11110100" => return 5;
        when "11110101" => return 6;
        when "11110110" => return 6;
        when "11110111" => return 7;
        when "11111000" => return 5;
        when "11111001" => return 6;
        when "11111010" => return 6;
        when "11111011" => return 7;
        when "11111100" => return 6;
        when "11111101" => return 7;
        when "11111110" => return 7;
        when "11111111" => return 8;
        when others => return 8;
        end case;
    end;

begin
----------------------------------------------------------------------------------
-- DVI 1.0 Specs Figure 3-5
-- Pipeline stage 1, minimise transitions
----------------------------------------------------------------------------------
Stage1: process(PixelClk)
begin
	if Rising_Edge(PixelClk) then
		pVde_1 <= pVde;

		n1d_1 <= to_unsigned(cntpop8(pDataOut(7 downto 0)),4);
		pDataOut_1 <= pDataOut; --insert data into the pipeline;
		pC0_1 <= pC0; --insert control into the pipeline;
		pC1_1 <= pC1;
	end if;
end process Stage1;

----------------------------------------------------------------------------------
-- Choose one of the two encoding options based on n1d_1
----------------------------------------------------------------------------------
q_m_xor_1(0) <= pDataOut_1(0);
encode1: for i in 1 to 7 generate
	q_m_xor_1(i) <= q_m_xor_1(i-1) xor pDataOut_1(i);
end generate encode1;
q_m_xor_1(8) <= '1';

q_m_xnor_1(0) <= pDataOut_1(0);
encode2: for i in 1 to 7 generate
	q_m_xnor_1(i) <= q_m_xnor_1(i-1) xnor pDataOut_1(i);
end generate encode2;
q_m_xnor_1(8) <= '0';

q_m_1 <= q_m_xnor_1 when n1d_1 > 4 or (n1d_1 = 4 and pDataOut_1(0) = '0') else
         q_m_xor_1;

n1q_m_1 <= to_unsigned(cntpop8(q_m_1(7 downto 0)),4);
		
----------------------------------------------------------------------------------
-- Pipeline stage 2, balance DC
----------------------------------------------------------------------------------
Stage2: process(PixelClk)
begin
	if Rising_Edge(PixelClk) then
		n1q_m_2 <= n1q_m_1;
		n0q_m_2 <= 8 - n1q_m_1;
		q_m_2 <= q_m_1;
		pC0_2 <= pC0_1;
		pC1_2 <= pC1_1;
		pVde_2 <= pVde_1;
	end if;
end process Stage2;

cond_balanced_2 <=   '1' when cnt_t_3 = 0 or n1q_m_2 = 4 else -- DC balanced output
						   '0';
cond_not_balanced_2 <=  '1' when (cnt_t_3 > 0 and n1q_m_2 > 4) or -- too many 1's
									 (cnt_t_3 < 0 and n1q_m_2 < 4) else -- too many 0's
                        '0';

control_token_2 <= 	kCtlTkn0 when pC1_2 = '0' and pC0_2 = '0' else
                     kCtlTkn1 when pC1_2 = '0' and pC0_2 = '1' else
                     kCtlTkn2 when pC1_2 = '1' and pC0_2 = '0' else
                     kCtlTkn3;
							
q_out_2 <=  control_token_2												when pVde_2 = '0' else	--control period
			   not q_m_2(8) & q_m_2(8) & not q_m_2(7 downto 0)    when cond_balanced_2 = '1' and q_m_2(8) = '0' else
			   not q_m_2(8) & q_m_2(8) & q_m_2(7 downto 0)        when cond_balanced_2 = '1' and q_m_2(8) = '1' else
			   '1' & q_m_2(8) & not q_m_2(7 downto 0)             when cond_not_balanced_2 = '1' else
			   '0' & q_m_2(8) & q_m_2(7 downto 0);	--DC balanced

dc_bias_2 <= to_signed(to_integer(n0q_m_2),5) - to_signed(to_integer(n1q_m_2),5);

cnt_t_2 <=  to_signed(0, cnt_t_2'length)                                   when pVde_2 = '0' else	--control period
			   cnt_t_3 + dc_bias_2                                            when cond_balanced_2 = '1' and q_m_2(8) = '0' else
			   cnt_t_3 - dc_bias_2                                            when cond_balanced_2 = '1' and q_m_2(8) = '1' else
			   cnt_t_3 + signed('0' & q_m_2(8 downto 8) & '0') + dc_bias_2	   when cond_not_balanced_2 = '1' else
			   cnt_t_3 - signed('0' & not q_m_2(8 downto 8) & '0') - dc_bias_2;

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
