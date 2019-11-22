// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
parameter BIDLE = 5'd0;
parameter B_StoreAck = 5'd1;
parameter B_Store2 = 5'd2;
parameter B_StoreAck2 = 5'd3;
parameter B_Store3 = 5'd4;
parameter B_StoreAck3 = 5'd5;
parameter B_DCacheLoadStart = 5'd6;
parameter B_DCacheLoadStb = 5'd7;
parameter B_DCacheLoadWait = 5'd8;
parameter B_DCacheLoadResetBusy = 5'd9;
parameter B8 = 5'd10;
parameter B11 = 5'd11;
parameter B_RMWAck = 5'd12;
parameter B_DLoadAck = 5'd13;
parameter B14 = 5'd14;
parameter B15 = 5'd15;
parameter B16 = 5'd16;
parameter B17 = 5'd17;
parameter B18 = 5'd18;
parameter B_LSNAck = 5'd19;
parameter B2a = 5'd20;
parameter B2b = 5'd21;
parameter B2c = 5'd22;
parameter B_DCacheLoadAck = 5'd23;
parameter B_RMWCvt = 5'd24;
parameter B21 = 5'd25;
parameter B_WaitSeg = 5'd29;
parameter B_DLoadNack = 5'd30;
parameter B_WaitIC = 5'd31;

parameter IDLE = 4'd0;
parameter IC1 = 4'd1;
parameter IC2 = 4'd2;
parameter IC_WaitROM = 4'd3;
parameter IC_WaitL2 = 4'd4;
parameter IC5 = 4'd5;
parameter IC9 = 4'd6;
parameter IC10 = 4'd7;
parameter IC_Ack = 4'd8;
parameter IC_Nack = 4'd9;
parameter IC_Nack2 = 4'd10;