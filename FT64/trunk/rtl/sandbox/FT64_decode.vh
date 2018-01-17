//function IsBranch;
//input [31:0] isn;
//casex(isn[`INSTRUCTION_OP])
//`Bcc:   IsBranch = TRUE;
//`BccR:  IsBranch = TRUE;
//`BBc:   IsBranch = TRUE;
//`BEQI:  IsBranch = TRUE;
//default: IsBranch = FALSE;
//endcase
//endfunction

//function IsJmp;
//input [31:0] isn;
//IsJmp = isn[`INSTRUCTION_OP]==`JMP;
//endfunction

//function IsCall;
//input [31:0] isn;
//IsCall = isn[`INSTRUCTION_OP]==`CALL;
//endfunction

//function IsRet;
//input [31:0] isn;
//IsRet = isn[`INSTRUCTION_OP]==`RET;
//endfunction

//function IsRTI;
//input [31:0] isn;
//IsRTI = isn[`INSTRUCTION_OP]==`RR && isn[`INSTRUCTION_S2]==`RTI;
//endfunction
