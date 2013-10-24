// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
task load_tsk;
input [7:0] dat;
begin
	case(load_what)
	`LW_MH:
			begin
				M[15:8] <= dat;
				load_what <= ML;
				next_state(LOAD1);
			end
	`LW_ML:
			begin
				M[7:0] <= dat;
				state <= CALC;
			end
	`BYTE1:
			begin
				res <= dat;
				next_state(IFETCH1);
			end
	`LW_CCR:	begin
				next_state(PULL1);
				radr <= radr + 16'd1;
				cf <= dat[0];
				vf <= dat[1];
				zf <= dat[2];
				nf <= dat[3];
				im <= dat[4];
				hf <= dat[5];
				firqim <= dat[6];
				ef <= dat[7];
				if (isRTI) begin
					ir[15:8] <= dat[7] ? 8'hFE : 8'h80;
					ssp <= ssp + 16'd1;
				end
				else if (isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
			end
	`LW_ACCA:	begin
				acca <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH1);
			end
	`LW_ACCB:	begin
				accb <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH1);
			end
	`LW_DPR:	begin
				dpr <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH1);
			end
	`LW_XH:	begin
				load_what <= `XL;
				next_state(LOAD1);
				xr[15:8] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_XL:	begin
				xr[7:0] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH1);
			end
	`LW_YH:	begin
				load_what <= `YL;
				next_state(LOAD1);
				yr[15:8] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_YL:	begin
				yr[7:0] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH1);
			end
	`LW_USPH:	begin
				load_what <= `USPL;
				next_state(LOAD1);
				usp[15:8] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_USPL:	begin
				usp[7:0] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH1);
			end
	`LW_SSPH:	begin
				load_what <= `SSPL;
				next_state(LOAD1);
				usp[15:8] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_SSPL:	begin
				usp[7:0] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_PCL:	begin
				pc[7:0] <= dat;
				radr <= radr + 16'd1;
				if (isRTI|isRTS|isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
				next_state(IFETCH);
			end
	`LW_PCH:	begin
				pc[15:8] <= dat;
				load_what <= `PCL;
				radr <= radr + 16'd1;
				if (isRTI|isRTS|isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
				next_state(LOAD1);
			end
	`LW_IAL:
			begin
				ia[7:0] <= dat;
				res[7:0] <= dat;
				if (isLEA)
					next_state(IFETCH1);
			end
	`LW_IAH:
			begin
				ia[15:8] <= dat;
				res[15:8] <= dat;
				load_what <= `LW_IAL;
				state <= LOAD1;
			end
	endcase
end
endtask
