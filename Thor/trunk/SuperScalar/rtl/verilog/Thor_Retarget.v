// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
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
//
// Establish the source queue id for a target register after a branch.
// Makes use of the fact that in Verilog later instructions override
// earlier ones. So if there are two queue entries that use the same
// target register, the later queue entry will become the valid source
// as it's written after the earlier queue entry.
//
// This code uses a tree approach rather than loop logic which races to the
// the right value. The timing from the toolset is a little more reliable
// that way. 
//
// ============================================================================
//
if (branchmiss) begin
    // Default the entire register file as valid, then invalidate target
    // registers as they are found in the queue.
    for (n = 1; n < NREGS; n = n + 1)
        rf_v[n] = `VAL;
    // Missed at head0, one instruction (current one) to worry about.
    if (missid==head0) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
    end
    else if (missid==head1) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
        rf_source[iqentry_tgt[head1]] <= { iqentry_mem[head1], head1};
        rf_v[iqentry_tgt[head1]] = `INV;
    end
    else if (missid==head2) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
        rf_source[iqentry_tgt[head1]] <= { iqentry_mem[head1], head1};
        rf_v[iqentry_tgt[head1]] = `INV;
        rf_source[iqentry_tgt[head2]] <= { iqentry_mem[head2], head2};
        rf_v[iqentry_tgt[head2]] = `INV;
    end
    else if (missid==head3) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
        rf_source[iqentry_tgt[head1]] <= { iqentry_mem[head1], head1};
        rf_v[iqentry_tgt[head1]] = `INV;
        rf_source[iqentry_tgt[head2]] <= { iqentry_mem[head2], head2};
        rf_v[iqentry_tgt[head2]] = `INV;
        rf_source[iqentry_tgt[head3]] <= { iqentry_mem[head3], head3};
        rf_v[iqentry_tgt[head3]] = `INV;
    end
    else if (missid==head4) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
        rf_source[iqentry_tgt[head1]] <= { iqentry_mem[head1], head1};
        rf_v[iqentry_tgt[head1]] = `INV;
        rf_source[iqentry_tgt[head2]] <= { iqentry_mem[head2], head2};
        rf_v[iqentry_tgt[head2]] = `INV;
        rf_source[iqentry_tgt[head3]] <= { iqentry_mem[head3], head3};
        rf_v[iqentry_tgt[head3]] = `INV;
        rf_source[iqentry_tgt[head4]] <= { iqentry_mem[head4], head4};
        rf_v[iqentry_tgt[head4]] = `INV;
    end
    else if (missid==head5) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
        rf_source[iqentry_tgt[head1]] <= { iqentry_mem[head1], head1};
        rf_v[iqentry_tgt[head1]] = `INV;
        rf_source[iqentry_tgt[head2]] <= { iqentry_mem[head2], head2};
        rf_v[iqentry_tgt[head2]] = `INV;
        rf_source[iqentry_tgt[head3]] <= { iqentry_mem[head3], head3};
        rf_v[iqentry_tgt[head3]] = `INV;
        rf_source[iqentry_tgt[head4]] <= { iqentry_mem[head4], head4};
        rf_v[iqentry_tgt[head4]] = `INV;
        rf_source[iqentry_tgt[head5]] <= { iqentry_mem[head5], head5};
        rf_v[iqentry_tgt[head5]] = `INV;
    end
    else if (missid==head6) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
        rf_source[iqentry_tgt[head1]] <= { iqentry_mem[head1], head1};
        rf_v[iqentry_tgt[head1]] = `INV;
        rf_source[iqentry_tgt[head2]] <= { iqentry_mem[head2], head2};
        rf_v[iqentry_tgt[head2]] = `INV;
        rf_source[iqentry_tgt[head3]] <= { iqentry_mem[head3], head3};
        rf_v[iqentry_tgt[head3]] = `INV;
        rf_source[iqentry_tgt[head4]] <= { iqentry_mem[head4], head4};
        rf_v[iqentry_tgt[head4]] = `INV;
        rf_source[iqentry_tgt[head5]] <= { iqentry_mem[head5], head5};
        rf_v[iqentry_tgt[head5]] = `INV;
        rf_source[iqentry_tgt[head6]] <= { iqentry_mem[head6], head6};
        rf_v[iqentry_tgt[head6]] = `INV;
    end
    else if (missid==head7) begin
        rf_source[iqentry_tgt[head0]] <= { iqentry_mem[head0], head0};
        rf_v[iqentry_tgt[head0]] = `INV;
        rf_source[iqentry_tgt[head1]] <= { iqentry_mem[head1], head1};
        rf_v[iqentry_tgt[head1]] = `INV;
        rf_source[iqentry_tgt[head2]] <= { iqentry_mem[head2], head2};
        rf_v[iqentry_tgt[head2]] = `INV;
        rf_source[iqentry_tgt[head3]] <= { iqentry_mem[head3], head3};
        rf_v[iqentry_tgt[head3]] = `INV;
        rf_source[iqentry_tgt[head4]] <= { iqentry_mem[head4], head4};
        rf_v[iqentry_tgt[head4]] = `INV;
        rf_source[iqentry_tgt[head5]] <= { iqentry_mem[head5], head5};
        rf_v[iqentry_tgt[head5]] = `INV;
        rf_source[iqentry_tgt[head6]] <= { iqentry_mem[head6], head6};
        rf_v[iqentry_tgt[head6]] = `INV;
        rf_source[iqentry_tgt[head7]] <= { iqentry_mem[head7], head7};
        rf_v[iqentry_tgt[head7]] = `INV;
    end
	// The following registers are always valid
    rf_v[7'h00] = `VAL;
    rf_v[7'h50] = `VAL;    // C0
    rf_v[7'h5F] = `VAL;    // C15 (PC)
    rf_v[7'h72] = `VAL; // tick
end

