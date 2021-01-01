
package nPowerPkg;

parameter TRUE  = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH  = 1'b1;
parameter LOW   = 1'b0;
parameter AWID  = 32;

parameter CR2   = 6'd19;
parameter RFI		= 10'd50;
parameter CRAND = 10'd257;
parameter CROR  = 10'd449;
parameter CRXOR = 10'd193;
parameter CRNAND= 10'd225;
parameter CRNOR = 10'd33;
parameter CREQV = 10'd289;
parameter CRANDC= 10'd129;
parameter CRORC = 10'd417;

parameter R2    = 6'd31;
parameter CMP   = 10'd0;
parameter CMPL  = 10'd32;

parameter ADD   = 10'd266;
parameter ADDO  = 10'd778;
parameter ADDC	= 10'd10;
parameter ADDCO	= 10'd522;
parameter ADDE	= 10'd138;
parameter ADDEO = 10'd650;
parameter ADDME = 10'd234;
parameter ADDMEO= 10'd746;
parameter ADDZE	= 10'd202;
parameter ADDZEO= 10'd714;
parameter SUBF  = 10'd40;
parameter SUBFO = 10'd552;
parameter SUBFC = 10'd8;
parameter SUBFCO= 10'd520;
parameter SUBFE = 10'd136;
parameter SUBFEO= 10'd648;
parameter SUBFME= 10'd232;
parameter SUBFMEO=10'd744;
parameter SUBFZE= 10'd200;
parameter SUBFZEO=10'd712;

parameter DIVW  = 10'd491;
parameter DIVWO = 10'd1003;
parameter DIVWU = 10'd459;
parameter DIVWUO= 10'd971;
parameter MULLW = 10'd235;
parameter MULLWO= 10'd747;
parameter NEG   = 10'd104;

parameter EXTSB = 10'd954;
parameter EXTSH = 10'd922;
parameter EXTSW = 10'd986;

parameter MULLI = 6'd7;
parameter SUBFIC= 6'd8;
parameter ADDIC = 6'd12;
parameter ADDICD= 6'd13;
parameter ADDI  = 6'd14;
parameter ADDIS = 6'd15;
parameter CMPI  = 6'd11;
parameter CMPLI = 6'd10;

// Logic
parameter AND   = 10'd28;
parameter ANDC  = 10'd60;
parameter OR    = 10'd444;
parameter ORC   = 10'd412;
parameter XOR   = 10'd316;
parameter NAND  = 10'd476;
parameter NOR   = 10'd124;
parameter EQV   = 10'd284;
parameter ANDI  = 6'd28;
parameter ANDIS = 6'd29;
parameter ORI   = 6'd24;
parameter ORIS  = 6'd25;
parameter XORI  = 6'd26;
parameter XORIS = 6'd27;

// Shift
parameter SLD   = 10'd27;
parameter SLW   = 10'd24;
parameter SRW   = 10'd536;
parameter SRAW  = 10'd792;
parameter SRAWI = 10'd824;
parameter RLWIMI  = 6'd20;
parameter RLWINM  = 6'd21;
parameter RLWNM   = 6'd23;

parameter CNTLZW	= 10'd26;

// Branch
parameter B     = 6'd18;
parameter BC    = 6'd16;
parameter BCCTR = 10'd528;
parameter BCLR  = 10'd16;

// Loads
parameter LBZ   = 6'd34;
parameter LBZU  = 6'd35;
parameter LHZ   = 6'd40;
parameter LHZU  = 6'd41;
parameter LHA		= 6'd42;
parameter LHAU	= 6'd43;
parameter LWZ   = 6'd32;
parameter LWZU  = 6'd33;
parameter L58   = 6'd58;
parameter LWA   = 2'd2;

parameter LBZX  = 10'd87;
parameter LBZUX = 10'd119;
parameter LHZX  = 10'd279;
parameter LHZUX = 10'd311;
parameter LHAX	= 10'd343;
parameter LHAUX = 10'd345;
parameter LWZX  = 10'd23;
parameter LWZUX = 10'd55;

// Stores
parameter STB   = 6'd38;
parameter STBU  = 6'd39;
parameter STH   = 6'd44;
parameter STHU  = 6'd45;
parameter STW   = 6'd36;
parameter STWU  = 6'd37;

parameter STBX  = 10'd215;
parameter STBUX = 10'd247;
parameter STHX  = 10'd407;
parameter STHUX = 10'd439;
parameter STWX  = 10'd151;
parameter STWUX = 10'd183;

parameter MCRXR = 10'd512;
parameter MFSPR = 10'd339;
parameter MTSPR = 10'd467;
parameter SPR_LR  = 10'd256;
parameter SPR_XER = 10'd32;

parameter MFCR  = 10'd19;
parameter MFSR  = 10'd595;
parameter MTSR  = 10'd210;
parameter MTCRF = 10'd144;
parameter MFSRI = 10'd659;
parameter MTSRIN  = 10'd242;

parameter MFMSR	= 10'd83;
parameter MTMSR = 10'd146;

parameter CRx   = 6'd19;

parameter SC    = 6'd17;
parameter TW    = 10'd4;
parameter TWI   = 6'd3;
parameter SYNC	= 10'd598;

parameter NOP_INSN  = {R2,5'd0,5'd0,5'd0,AND,1'b0};

// Cause
parameter FLT_NONE 		= 8'h00;
parameter FLT_RESET		= 8'h01;
parameter FLT_MACHINE_CHECK	= 8'h02;
parameter FLT_DATA_STORAGE	= 8'h03;
parameter FLT_INSTRUCTION_STORAGE = 8'h04;
parameter FLT_EXTERNAL = 8'h05;
parameter FLT_ALIGNMENT = 8'h06;
parameter FLT_PROGRAM = 8'h07;
parameter FLT_FPU_UNAVAILABLE = 8'h08;
parameter FLT_DECREMENTER = 8'h09;
parameter FLT_RESERVED_A = 8'h0A;
parameter FLT_RESERVED_B = 8'h0B;
parameter FLT_SYSTEM_CALL = 8'h0C;
parameter FLT_TRACE = 8'h0D;
parameter FLT_FP_ASSIST = 8'h0E;
parameter FLT_RESERVED = 8'h2F;

// Instruction fetch
parameter IFETCH1 = 4'd0;
parameter IALIGN = 4'd1;
parameter IWAIT = 4'd2;
parameter IACCESS = 4'd3;
parameter IACCESS_CYC = 4'd4;
parameter IACCESS_ACK = 4'd5;
parameter IC_UPDATE = 4'd6;
parameter ICU1 = 4'd7;
parameter ICU2 = 4'd8;
parameter IFETCH0 = 4'd9;
parameter IFETCH0a = 4'd10;
parameter IFETCH0b = 4'd11;

// Decode
parameter DECODE = 2'd0;
parameter DWAIT = 2'd1;

// Register Fetch
parameter RFETCH = 2'd0;
parameter RWAIT = 2'd1;

// Execute
parameter EXECUTE = 3'd0;
parameter EFLAGS = 3'd1;
parameter EWAIT = 3'd2;
parameter EDIV1 = 3'd3;
parameter EDIV2 = 3'd4;
parameter EDIV3 = 3'd5;

// Memory
parameter MEMORY1 = 3'd0;
parameter MEMORY2 = 3'd1;
parameter MEMORY3 = 3'd2;
parameter MEMORY4 = 3'd3;
parameter MEMORY5 = 3'd4;
parameter MALIGN = 3'd5;
parameter MWAIT = 3'd6;
parameter MSX = 3'd7;

// Writeback stage
parameter WRITEBACK0 = 3'd0;
parameter WRITEBACK1 = 3'd1;
parameter WRITEBACK2 = 3'd2;
parameter WRITEBACK3 = 3'd3;
parameter WRITEBACK4 = 3'd4;
parameter WWAIT = 3'd5;

parameter pL1CacheLines = 64;
localparam pL1msb = $clog2(pL1CacheLines-1)-1+5;
parameter RSTPC = 32'hFFFD0000;
parameter RIBO = 1;

endpackage

