-- ============================================================================
--        __
--   \\__/ o\    (C) 2020  Robert Finch, Waterloo
--    \  __ /    All rights reserved.
--     \/_--     robfinch<remove>@finitron.ca
--       ||
--
--	xbusPhaseAlign.vhd
--
-- BSD 3-Clause License
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
--
-- 3. Neither the name of the copyright holder nor the names of its
--    contributors may be used to endorse or promote products derived from
--    this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity xbusPhaseAlign is
  generic (
    pParallelWidth : natural := 14;
    pCtrlTokenCnt : natural := 2;
    pCtrlToken : std_logic_vector(13 downto 0) := "11010101010100"
  );
  port (
    rst_i : in std_logic;
    clk_i : in std_logic;
    dat_i : in std_logic_vector(13 downto 0);
    idly_ce : out std_logic;
    idly_inc : out std_logic;
    idly_cnt : in std_logic_vector(4 downto 0);
    idly_ld : out std_logic;
    aligned : out std_logic;
    error : out std_logic;
    eye_size : out std_logic_vector(4 downto 0);
    restore : in std_logic;
    clr_restore : in std_logic;
    BitslipValReset : in std_logic
  );
end xbusPhaseAlign;

architecture Behavioral of xbusPhaseAlign is
constant INIT : natural := 0;
constant LOOPX : natural := 1;
constant INC_DELAY : natural := 2;
constant INC_WAIT_TOKEN_FIND : natural := 3;
constant DEC_DELAY : natural := 4;
constant DEC_WAIT_TOKEN_FIND : natural := 5;
constant CALC_CENTER : natural := 6;
constant MOVE_TO_CENTER : natural := 7;
constant MTC1 : natural := 8;
constant MTC2 : natural := 9;
constant DONE : natural := 10;
constant LOOK_FOR_TOKEN : natural := 11;
constant INC_DELAY2 : natural := 12;
constant INC2 : natural := 13;
constant RESET_BITSLIP : natural := 14;

signal state : natural range 0 to 15;
signal cnt : natural range 0 to 15;
signal pos_count : natural range 0 to 15;
signal end_pos : unsigned(7 downto 0);
signal start_pos : unsigned(7 downto 0);
signal center : unsigned(7 downto 0);
signal token_cnt : natural range 0 to 63;
signal timeout_cnt : natural range 0 to 127;
signal found_token : std_logic;
signal reset_found_token : std_logic;
signal reset_timeout : std_logic;
signal timeout : std_logic;
signal err1 : std_logic;
signal eye_size1 : unsigned(7 downto 0);
signal did_restore : std_logic;

begin

error <= err1;
eye_size <= std_logic_vector(eye_size1(4 downto 0));

TimeoutCounter: process (clk_i) is
begin
  if Rising_Edge(clk_i) then
    timeout_cnt <= timeout_cnt + 1;
    if (rst_i = '1') then
      timeout_cnt <= 0;
      timeout <= '0';
    else
      if (found_token = '1') then
        timeout_cnt <= 0;
      end if;
      if (reset_timeout = '1') then
        timeout <= '0';
      elsif (timeout_cnt >= 8) then
        timeout_cnt <= 0;
        timeout <= '1';
      end if;
    end if;
  end if;
end process TimeoutCounter;

FindToken: process (clk_i) is
begin
  if Rising_Edge(clk_i) then
    if (rst_i = '1') then
      token_cnt <= 0;
      found_token <= '0';
    else
      if (dat_i = pCtrlToken) then
        token_cnt <= token_cnt + 1;
      else
        token_cnt <= 0;
      end if;
      if (reset_found_token = '1') then
        found_token <= '0';
      elsif (token_cnt = pCtrlTokenCnt) then
        found_token <= '1';
      end if;
    end if;
  end if;
end process FindToken;
 
StateMachine: process (clk_i) is
begin
  if Rising_Edge(clk_i) then
    if (rst_i = '1') then
      reset_found_token <= '0';
      reset_timeout <= '0';
      idly_ce <= '0';
      idly_inc <= '0';
      idly_ld <= restore;
      aligned <= '0';
      err1 <= '0';
      if (restore = '1') then
        state <= RESET_BITSLIP;
      else
        state <= INIT;
      end if;
      if (clr_restore = '1') then
        did_restore <= '0';
      else
        did_restore <= restore;
      end if;
    else
      reset_found_token <= '0';
      reset_timeout <= '0';
      idly_ce <= '0';
      idly_inc <= '0';
      idly_ld <= '0';

      case(state) is
        
      when INIT =>
				idly_ld <= '1';
				err1 <= '0';
				pos_count <= 0;
				end_pos <= to_unsigned(0,8);
				start_pos <= to_unsigned(0,8);
				state <= LOOK_FOR_TOKEN;
			
			-- If the IDLY count was restored because there is a return to a
			-- previously timed device, then skip over the delay increment /
			-- decrement. Assume the delay is correct, but the bitslip may
			-- need to be reset.
      when LOOK_FOR_TOKEN =>
        if (err1 = '0') then
          if (idly_cnt = x"1F" or did_restore = '1') then
            err1 <= '1';
          end if;
          if (timeout = '1') then
            state <= INC_DELAY2;
          end if;
          if (found_token = '1') then
            err1 <= '0';
            if (did_restore = '1') then
              state <= DONE;
            else
              state <= LOOPX;
            end if;
          end if;
        end if;
          
      when RESET_BITSLIP =>
        if (BitslipValReset = '1') then
          err1 <= '0';
          state <= DONE;
        else
          err1 <= '1';
        end if;
          
      when INC_DELAY2 =>
				reset_timeout <= '1';
				idly_ce <= '1';
				idly_inc <= '1';
				state <= INC2;

      when INC2 =>
        state <= LOOK_FOR_TOKEN;        

      -- Loop four time to get average eye.
      when LOOPX =>
				pos_count <= pos_count + 1;
				if (pos_count = 4) then
					state <= CALC_CENTER;
				else
					state <= INC_DELAY;
				end if;
		
      -- ToDo: fix this for tokens that would always be found (causes infinite loop).
      -- Increase delay until token can no longer be found. This will give the end
      -- position of the eye.
      when INC_DELAY =>
				idly_ce <= '1';
				idly_inc <= '1';
				reset_found_token <= '1';
				cnt <= 0;
				state <= INC_WAIT_TOKEN_FIND;
			
      -- Wait for the token to be found again. If the token has not been found
      -- within a few clock cycles then the increment was too great. Go to the
      -- decrement state.
      when INC_WAIT_TOKEN_FIND =>
				cnt <= cnt + 1;
				if (cnt >= 4) then
					end_pos <= end_pos + conv_integer(idly_cnt);
					state <= DEC_DELAY;
				end if;
				if (found_token = '1') then
					state <= INC_DELAY;
				end if;

      -- Decrease the delay until the token can no longer be found. This will give
      -- the start position of the eye.
      when DEC_DELAY =>
				idly_ce <= '1';
				idly_inc <= '0';
				reset_found_token <= '1';
				cnt <= 0;
				state <= DEC_WAIT_TOKEN_FIND;
			
      when DEC_WAIT_TOKEN_FIND =>
				cnt <= cnt + 1;
				if (cnt >= 8) then
					state <= LOOPX;
					start_pos <= start_pos + conv_integer(idly_cnt);
				end if;
				if (found_token = '1') then
          state <= DEC_DELAY;
				end if;

      when CALC_CENTER =>
				eye_size1 <= shift_right(unsigned(
					((end_pos - start_pos) + 1)),2);
				center <= shift_right(unsigned((end_pos + start_pos) + 1),3);
				state <= MOVE_TO_CENTER;

      when MOVE_TO_CENTER =>
				if (idly_cnt = std_logic_vector(center)) then
					state <= DONE;
				else
					idly_ce <= '1';
					idly_inc <= '1';
				end if;

      -- Stay in done state unless reset.
      when DONE =>
        aligned <= '1';
      
      when others =>
      
      end case;
    end if;
  end if;
end process StateMachine;    

end Behavioral;
