// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2015  Robert Finch, Stratford
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
// SuperScalar
// Memory combinational logic
//
// ============================================================================
//
//
assign
	iqentry_LdOpsValid[0] = (iqentry_ld[0] & iqentry_av[0] & iqentry_bv[0]),
	iqentry_LdOpsValid[1] = (iqentry_ld[1] & iqentry_av[1] & iqentry_bv[1]),
	iqentry_LdOpsValid[2] = (iqentry_ld[2] & iqentry_av[2] & iqentry_bv[2]),
	iqentry_LdOpsValid[3] = (iqentry_ld[3] & iqentry_av[3] & iqentry_bv[3]),
	iqentry_LdOpsValid[4] = (iqentry_ld[4] & iqentry_av[4] & iqentry_bv[4]),
	iqentry_LdOpsValid[5] = (iqentry_ld[5] & iqentry_av[5] & iqentry_bv[5]),
	iqentry_LdOpsValid[6] = (iqentry_ld[6] & iqentry_av[6] & iqentry_bv[6]),
	iqentry_LdOpsValid[7] = (iqentry_ld[7] & iqentry_av[7] & iqentry_bv[7]),
	iqentry_LdOpsValid[8] = (iqentry_ld[8] & iqentry_av[8] & iqentry_bv[8]),
	iqentry_LdOpsValid[9] = (iqentry_ld[9] & iqentry_av[9] & iqentry_bv[9]),
	iqentry_LdOpsValid[10] = (iqentry_ld[10] & iqentry_av[10] & iqentry_bv[10]),
	iqentry_LdOpsValid[11] = (iqentry_ld[11] & iqentry_av[11] & iqentry_bv[11]),
	iqentry_LdOpsValid[12] = (iqentry_ld[12] & iqentry_av[12] & iqentry_bv[12]),
	iqentry_LdOpsValid[13] = (iqentry_ld[13] & iqentry_av[13] & iqentry_bv[13]),
	iqentry_LdOpsValid[14] = (iqentry_ld[14] & iqentry_av[14] & iqentry_bv[14]),
	iqentry_LdOpsValid[15] = (iqentry_ld[15] & iqentry_av[15] & iqentry_bv[15]);

assign
	iqentry_StOpsValid[0] = (iqentry_st[0] & iqentry_av[0] & iqentry_bv[0] & iqentry_cv[0]),
	iqentry_StOpsValid[1] = (iqentry_st[1] & iqentry_av[1] & iqentry_bv[1] & iqentry_cv[1]),
	iqentry_StOpsValid[2] = (iqentry_st[2] & iqentry_av[2] & iqentry_bv[2] & iqentry_cv[2]),
	iqentry_StOpsValid[3] = (iqentry_st[3] & iqentry_av[3] & iqentry_bv[3] & iqentry_cv[3]),
	iqentry_StOpsValid[4] = (iqentry_st[4] & iqentry_av[4] & iqentry_bv[4] & iqentry_cv[4]),
	iqentry_StOpsValid[5] = (iqentry_st[5] & iqentry_av[5] & iqentry_bv[5] & iqentry_cv[5]),
	iqentry_StOpsValid[6] = (iqentry_st[6] & iqentry_av[6] & iqentry_bv[6] & iqentry_cv[6]),
	iqentry_StOpsValid[7] = (iqentry_st[7] & iqentry_av[7] & iqentry_bv[7] & iqentry_cv[7]),
	iqentry_StOpsValid[8] = (iqentry_st[8] & iqentry_av[8] & iqentry_bv[8] & iqentry_cv[8]),
	iqentry_StOpsValid[9] = (iqentry_st[9] & iqentry_av[9] & iqentry_bv[9] & iqentry_cv[9]),
	iqentry_StOpsValid[10] = (iqentry_st[10] & iqentry_av[10] & iqentry_bv[10] & iqentry_cv[10]),
	iqentry_StOpsValid[11] = (iqentry_st[11] & iqentry_av[11] & iqentry_bv[11] & iqentry_cv[11),
	iqentry_StOpsValid[12] = (iqentry_st[12] & iqentry_av[12] & iqentry_bv[12] & iqentry_cv[12]),
	iqentry_StOpsValid[13] = (iqentry_st[13] & iqentry_av[13] & iqentry_bv[13] & iqentry_cv[13]),
	iqentry_StOpsValid[14] = (iqentry_st[14] & iqentry_av[14] & iqentry_bv[14] & iqentry_cv[14]),
	iqentry_StOpsValid[15] = (iqentry_st[15] & iqentry_av[15] & iqentry_bv[15] & iqentry_cv[15]);

assign
	iqentry_LdReady[0] = (iqentry_v[0] & iqentry_LdOpsValid[0] & ~iqentry_LdIssue[0] & ~iqentry_done[0] & ~iqentry_out[0] & ~iqentry_stomp[0]),
	iqentry_LdReady[1] = (iqentry_v[1] & iqentry_LdOpsValid[1] & ~iqentry_LdIssue[1] & ~iqentry_done[1] & ~iqentry_out[1] & ~iqentry_stomp[1]),
	iqentry_LdReady[2] = (iqentry_v[2] & iqentry_LdOpsValid[2] & ~iqentry_LdIssue[2] & ~iqentry_done[2] & ~iqentry_out[2] & ~iqentry_stomp[2]),
	iqentry_LdReady[3] = (iqentry_v[3] & iqentry_LdOpsValid[3] & ~iqentry_LdIssue[3] & ~iqentry_done[3] & ~iqentry_out[3] & ~iqentry_stomp[3]),
	iqentry_LdReady[4] = (iqentry_v[4] & iqentry_LdOpsValid[4] & ~iqentry_LdIssue[4] & ~iqentry_done[4] & ~iqentry_out[4] & ~iqentry_stomp[4]),
	iqentry_LdReady[5] = (iqentry_v[5] & iqentry_LdOpsValid[5] & ~iqentry_LdIssue[5] & ~iqentry_done[5] & ~iqentry_out[5] & ~iqentry_stomp[5]),
	iqentry_LdReady[6] = (iqentry_v[6] & iqentry_LdOpsValid[6] & ~iqentry_LdIssue[6] & ~iqentry_done[6] & ~iqentry_out[6] & ~iqentry_stomp[6]),
	iqentry_LdReady[7] = (iqentry_v[7] & iqentry_LdOpsValid[7] & ~iqentry_LdIssue[7] & ~iqentry_done[7] & ~iqentry_out[7] & ~iqentry_stomp[7]),
	iqentry_LdReady[8] = (iqentry_v[8] & iqentry_LdOpsValid[8] & ~iqentry_LdIssue[8] & ~iqentry_done[8] & ~iqentry_out[8] & ~iqentry_stomp[8]),
	iqentry_LdReady[9] = (iqentry_v[9] & iqentry_LdOpsValid[9] & ~iqentry_LdIssue[9] & ~iqentry_done[9] & ~iqentry_out[9] & ~iqentry_stomp[9]),
	iqentry_LdReady[10] = (iqentry_v[10] & iqentry_LdOpsValid[10] & ~iqentry_LdIssue[10] & ~iqentry_done[10] & ~iqentry_out[10] & ~iqentry_stomp[10]),
	iqentry_LdReady[11] = (iqentry_v[11] & iqentry_LdOpsValid[11] & ~iqentry_LdIssue[11] & ~iqentry_done[11] & ~iqentry_out[11] & ~iqentry_stomp[11]),
	iqentry_LdReady[12] = (iqentry_v[12] & iqentry_LdOpsValid[12] & ~iqentry_LdIssue[12] & ~iqentry_done[12] & ~iqentry_out[12] & ~iqentry_stomp[12]),
	iqentry_LdReady[13] = (iqentry_v[13] & iqentry_LdOpsValid[13] & ~iqentry_LdIssue[13] & ~iqentry_done[13] & ~iqentry_out[13] & ~iqentry_stomp[13]),
	iqentry_LdReady[14] = (iqentry_v[14] & iqentry_LdOpsValid[14] & ~iqentry_LdIssue[14] & ~iqentry_done[14] & ~iqentry_out[14] & ~iqentry_stomp[14]),
	iqentry_LdReady[15] = (iqentry_v[15] & iqentry_LdOpsValid[15] & ~iqentry_LdIssue[15] & ~iqentry_done[15] & ~iqentry_out[15] & ~iqentry_stomp[15]);

assign
	iqentry_StReady[0] = (iqentry_v[0] & iqentry_StOpsValid[0] & ~iqentry_StIssue[0] & ~iqentry_done[0] & ~iqentry_out[0] & ~iqentry_stomp[0]),
	iqentry_StReady[1] = (iqentry_v[1] & iqentry_StOpsValid[1] & ~iqentry_StIssue[1] & ~iqentry_done[1] & ~iqentry_out[1] & ~iqentry_stomp[1]),
	iqentry_StReady[2] = (iqentry_v[2] & iqentry_StOpsValid[2] & ~iqentry_StIssue[2] & ~iqentry_done[2] & ~iqentry_out[2] & ~iqentry_stomp[2]),
	iqentry_StReady[3] = (iqentry_v[3] & iqentry_StOpsValid[3] & ~iqentry_StIssue[3] & ~iqentry_done[3] & ~iqentry_out[3] & ~iqentry_stomp[3]),
	iqentry_StReady[4] = (iqentry_v[4] & iqentry_StOpsValid[4] & ~iqentry_StIssue[4] & ~iqentry_done[4] & ~iqentry_out[4] & ~iqentry_stomp[4]),
	iqentry_StReady[5] = (iqentry_v[5] & iqentry_StOpsValid[5] & ~iqentry_StIssue[5] & ~iqentry_done[5] & ~iqentry_out[5] & ~iqentry_stomp[5]),
	iqentry_StReady[6] = (iqentry_v[6] & iqentry_StOpsValid[6] & ~iqentry_StIssue[6] & ~iqentry_done[6] & ~iqentry_out[6] & ~iqentry_stomp[6]),
	iqentry_StReady[7] = (iqentry_v[7] & iqentry_StOpsValid[7] & ~iqentry_StIssue[7] & ~iqentry_done[7] & ~iqentry_out[7] & ~iqentry_stomp[7]),
	iqentry_StReady[8] = (iqentry_v[8] & iqentry_StOpsValid[8] & ~iqentry_StIssue[8] & ~iqentry_done[8] & ~iqentry_out[8] & ~iqentry_stomp[8]),
	iqentry_StReady[9] = (iqentry_v[9] & iqentry_StOpsValid[9] & ~iqentry_StIssue[9] & ~iqentry_done[9] & ~iqentry_out[9] & ~iqentry_stomp[9]),
	iqentry_StReady[10] = (iqentry_v[10] & iqentry_StOpsValid[10] & ~iqentry_StIssue[10] & ~iqentry_done[10] & ~iqentry_out[10] & ~iqentry_stomp[10]),
	iqentry_StReady[11] = (iqentry_v[11] & iqentry_StOpsValid[11] & ~iqentry_StIssue[11] & ~iqentry_done[11] & ~iqentry_out[11] & ~iqentry_stomp[11]),
	iqentry_StReady[12] = (iqentry_v[12] & iqentry_StOpsValid[12] & ~iqentry_StIssue[12] & ~iqentry_done[12] & ~iqentry_out[12] & ~iqentry_stomp[12]),
	iqentry_StReady[13] = (iqentry_v[13] & iqentry_StOpsValid[13] & ~iqentry_StIssue[13] & ~iqentry_done[13] & ~iqentry_out[13] & ~iqentry_stomp[13]),
	iqentry_StReady[14] = (iqentry_v[14] & iqentry_StOpsValid[14] & ~iqentry_StIssue[14] & ~iqentry_done[14] & ~iqentry_out[14] & ~iqentry_stomp[14]),
	iqentry_StReady[15] = (iqentry_v[15] & iqentry_StOpsValid[15] & ~iqentry_StIssue[15] & ~iqentry_done[15] & ~iqentry_out[15] & ~iqentry_stomp[15]);

