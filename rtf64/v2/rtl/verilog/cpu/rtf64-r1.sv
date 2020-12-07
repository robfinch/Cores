// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64-r1.sv
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

import rtf64pkg::*;

module rtf64_r1(ir, ia, id, cdb, res, crres);
parameter WID=64;
input [31:0] ir;
input [WID-1:0] ia;
input [WID-1:0] id;
input [7:0] cdb;
output reg [WID-1:0] res;
output reg [7:0] crres;

wire [2:0] mop = ir[12:10];

always @*
begin
  case(ir[22:18])
  `COMR1:   
    case(ir[25:23])
    3'd0: res <= ~ia;
    3'd1: res <= {id[63:32],~ia[31:0]};
    3'd2: res <= {id[63:16],~ia[15:0]};
    3'd3: res <= {id[63: 8],~ia[ 7:0]};
    default:  res <= ~ia;
    endcase
  `NOTR1:   
    case(ir[25:23])
    3'd0: res <= ia==64'd0;
    3'd1: res <= ia[31:0]==32'd0;
    3'd2: res <= ia[15:0]==16'h0;
    3'd3: res <= ia[7:0]==8'h0;
    3'd4: res <= ia==64'd0;
    3'd5: res <= {ia[63:32]==32'd0,31'd0,ia[31:0]==32'd0};
    3'd6: res <= {ia[63:48]==16'd0,15'd0,ia[47:32]==16'd0,15'd0,ia[31:16]==16'd0,15'd0,ia[15:0]==16'd0};
    3'd7: res <= {ia[63:56]==8'd0,7'd0,ia[55:48]==8'd0,7'd0,ia[47:40]==8'd0,7'd0,ia[39:32]==8'd0,7'd0,
                  ia[31:24]==8'd0,7'd0,ia[23:16]==8'd0,7'd0,ia[15:8]==8'd0,7'd0,ia[7:0]==8'd0};
    endcase
  `NEGR1:
    case(ir[25:23])
    3'd0: res <= -ia;
    3'd1: res <= {id[63:32],-ia[31:0]};
    3'd2: res <= {id[63:16],-ia[15:0]};
    3'd3: res <= {id[63: 8],-ia[ 7:0]};
    3'd5: res <= {-ia[63:32],-ia[31:0]};
    3'd6: res <= {-ia[63:48],-ia[47:32],-ia[31:16],-ia[15:0]};
    3'd7: res <= {-ia[63:56],-ia[55:48],-ia[47:40],-ia[39:32],-ia[31:24],-ia[23:16],-ia[15:8],-ia[7:0]};
    default: res <= -ia;
    endcase
  `TST1:
    begin
      case(ir[25:23])
      3'd0: // Octa
        case(mop)
        `CMP_CPY:
          begin
            crres[0] <= ia!=64'd0;
            crres[1] <= ia==64'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= ^ia;
            crres[5] <= ia[0];
            crres[6] <= 1'b0;
            crres[7] <= ia[63];
          end
        `CMP_AND:
          begin
            crres[0] <= cdb[0] && ia!=64'd0;
            crres[1] <= cdb[1] && ia==64'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ^ia;
            crres[5] <= cdb[5] & ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ia[63];
          end
        `CMP_OR:
          begin
            crres[0] <= cdb[0] || ia!=64'd0;
            crres[1] <= cdb[1] || ia==64'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ^ia;
            crres[5] <= cdb[5] | ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ia[63];
          end
        `CMP_ANDCM:
          begin
            crres[0] <= cdb[0] && !(ia!=64'd0);
            crres[1] <= cdb[1] && !(ia==64'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ~^ia;
            crres[5] <= cdb[5] & ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ~ia[63];
          end
        `CMP_ORCM:
          begin
            crres[0] <= cdb[0] || !(ia!=64'd0);
            crres[1] <= cdb[1] || !(ia==64'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ~^ia;
            crres[5] <= cdb[5] | ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ~ia[63];
          end
        default:  ;
        endcase
      3'd1: // Tetra
        case(mop)
        `CMP_CPY:
          begin
            crres[0] <= ia[31:0]!=32'd0;
            crres[1] <= ia[31:0]==32'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= ^ia[31:0];
            crres[5] <= ia[0];
            crres[6] <= 1'b0;
            crres[7] <= ia[31];
          end
        `CMP_AND:
          begin
            crres[0] <= cdb[0] && ia[31:0]!=32'd0;
            crres[1] <= cdb[1] && ia[31:0]==32'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ^ia[31:0];
            crres[5] <= cdb[5] & ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ia[31];
          end
        `CMP_OR:
          begin
            crres[0] <= cdb[0] || ia[31:0]!=32'd0;
            crres[1] <= cdb[1] || ia[31:0]==32'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ^ia[31:0];
            crres[5] <= cdb[5] | ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ia[31];
          end
        `CMP_ANDCM:
          begin
            crres[0] <= cdb[0] && !(ia[31:0]!=32'd0);
            crres[1] <= cdb[1] && !(ia[31:0]==32'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ~^ia[31:0];
            crres[5] <= cdb[5] & ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ~ia[31];
          end
        `CMP_ORCM:
          begin
            crres[0] <= cdb[0] || !(ia[31:0]!=32'd0);
            crres[1] <= cdb[1] || !(ia[31:0]==32'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ~^ia[31:0];
            crres[5] <= cdb[5] | ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ~ia[31];
          end
        default:  ;
        endcase
      3'd2: // Wyde
        case(mop)
        `CMP_CPY:
          begin
            crres[0] <= ia[15:0]!=16'd0;
            crres[1] <= ia[15:0]==16'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= ^ia[15:0];
            crres[5] <= ia[0];
            crres[6] <= 1'b0;
            crres[7] <= ia[15];
          end
        `CMP_AND:
          begin
            crres[0] <= cdb[0] && ia[15:0]!=16'd0;
            crres[1] <= cdb[1] && ia[15:0]==16'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ^ia[15:0];
            crres[5] <= cdb[5] & ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ia[15];
          end
        `CMP_OR:
          begin
            crres[0] <= cdb[0] || ia[15:0]!=16'd0;
            crres[1] <= cdb[1] || ia[15:0]==16'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ^ia[15:0];
            crres[5] <= cdb[5] | ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ia[15];
          end
        `CMP_ANDCM:
          begin
            crres[0] <= cdb[0] && !(ia[15:0]!=16'd0);
            crres[1] <= cdb[1] && !(ia[15:0]==16'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ~^ia[15:0];
            crres[5] <= cdb[5] & ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ~ia[15];
          end
        `CMP_ORCM:
          begin
            crres[0] <= cdb[0] || !(ia[15:0]!=16'd0);
            crres[1] <= cdb[1] || !(ia[15:0]==16'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ~^ia[15:0];
            crres[5] <= cdb[5] | ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ~ia[15];
          end
        default:  ;
        endcase
      3'd3: // Byte
        case(mop)
        `CMP_CPY:
          begin
            crres[0] <= ia[7:0]!=8'd0;
            crres[1] <= ia[7:0]==8'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= ^ia[7:0];
            crres[5] <= ia[0];
            crres[6] <= 1'b0;
            crres[7] <= ia[7];
          end
        `CMP_AND:
          begin
            crres[0] <= cdb[0] && ia[7:0]!=8'd0;
            crres[1] <= cdb[1] && ia[7:0]==8'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ^ia[7:0];
            crres[5] <= cdb[5] & ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ia[7];
          end
        `CMP_OR:
          begin
            crres[0] <= cdb[0] || ia[7:0]!=8'd0;
            crres[1] <= cdb[1] || ia[7:0]==8'd0;
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ^ia[7:0];
            crres[5] <= cdb[5] | ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ia[7];
          end
        `CMP_ANDCM:
          begin
            crres[0] <= cdb[0] && !(ia[7:0]!=8'd0);
            crres[1] <= cdb[1] && !(ia[7:0]==8'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] & ~^ia[7:0];
            crres[5] <= cdb[5] & ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] & ~ia[7];
          end
        `CMP_ORCM:
          begin
            crres[0] <= cdb[0] || !(ia[7:0]!=8'd0);
            crres[1] <= cdb[1] || !(ia[7:0]==8'd0);
            crres[2] <= 1'b0;
            crres[3] <= 1'b0;
            crres[4] <= cdb[4] | ~^ia[7:0];
            crres[5] <= cdb[5] | ~ia[0];
            crres[6] <= 1'b0;
            crres[7] <= cdb[7] | ~ia[7];
          end
        default:  ;
        endcase
      default:  ;
      endcase
    end
  `PTRINC:
    if (ia[2:0]>=ir[25:23])
      res <= {ia[WID-1:3]+1'd1,3'd0};
    else
      res <= ia + 1'd1;
  default:  ;                                    
  endcase
end

endmodule
