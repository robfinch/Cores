// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  PUSHA push all registers to stack
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================

PUSHA:
	begin
		tWrite(sssp,ah);
		tGoto(PUSHA1);
	end
PUSHA1:
	if (rty_i)
		tWrite(sssp,ah);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA2);
	end	
PUSHA2:
	begin
		tWrite(sssp,al);
		tGoto(PUSHA3);
	end
PUSHA3:
	if (rty_i)
		tWrite(sssp,al);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA4);
	end	
PUSHA4:
	begin
		tWrite(sssp,ch);
		tGoto(PUSHA5);
	end
PUSHA5:
	if (rty_i)
		tWrite(sssp,ch);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA6);
	end	
PUSHA6:
	begin
		tWrite(sssp,cl);
		tGoto(PUSHA7);
	end
PUSHA7:
	if (rty_i)
		tWrite(sssp,cl);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA8);
	end	
PUSHA8:
	begin
		tWrite(sssp,dh);
		tGoto(PUSHA9);
	end
PUSHA9:
	if (rty_i)
		tWrite(sssp,dh);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA10);
	end	
PUSHA10:
	begin
		tWrite(sssp,dl);
		tGoto(PUSHA11);
	end
PUSHA11:
	if (rty_i)
		tWrite(sssp,dl);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA12);
	end	
PUSHA12:
	begin
		tWrite(sssp,bh);
		tGoto(PUSHA13);
	end
PUSHA13:
	if (rty_i)
		tWrite(sssp,bh);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA14);
	end	
PUSHA14:
	begin
		tWrite(sssp,bl);
		tGoto(PUSHA15);
	end
PUSHA15:
	if (rty_i)
		tWrite(sssp,bl);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA16);
	end
// Push the starting SP value before all the pushes.	
PUSHA16:
	begin
		tWrite(sssp,tsp[15:8]);
		tGoto(PUSHA17);
	end
PUSHA17:
	if (rty_i)
		tWrite(sssp,tsp[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA18);
	end	
PUSHA18:
	begin
		tWrite(sssp,tsp[7:0]);
		tGoto(PUSHA19);
	end
PUSHA19:
	if (rty_i)
		tWrite(sssp,tsp[7:0]);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA20);
	end	
PUSHA20:
	begin
		tWrite(sssp,bp[15:8]);
		tGoto(PUSHA21);
	end
PUSHA21:
	if (rty_i)
		tWrite(sssp,bp[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA22);
	end	
PUSHA22:
	begin
		tWrite(sssp,bp[7:0]);
		tGoto(PUSHA23);
	end
PUSHA23:
	if (rty_i)
		tWrite(sssp,bp[7:0]);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA24);
	end	
PUSHA24:
	begin
		tWrite(sssp,si[15:8]);
		tGoto(PUSHA25);
	end
PUSHA25:
	if (rty_i)
		tWrite(sssp,si[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA26);
	end	
PUSHA26:
	begin
		tWrite(sssp,si[7:0]);
		tGoto(PUSHA27);
	end
PUSHA27:
	if (rty_i)
		tWrite(sssp,si[7:0]);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA28);
	end	
PUSHA28:
	begin
		tWrite(sssp,di[15:8]);
		tGoto(PUSHA29);
	end
PUSHA29:
	if (rty_i)
		tWrite(sssp,di[15:8]);
	else begin
		sp <= sp_dec;
		tGoto(PUSHA30);
	end	
PUSHA30:
	begin
		tWrite(sssp,di[7:0]);
		tGoto(PUSHA31);
	end
PUSHA31:
	if (rty_i)
		tWrite(sssp,di[7:0]);
	else begin
		tGoto(rf8088_pkg::IFETCH);
