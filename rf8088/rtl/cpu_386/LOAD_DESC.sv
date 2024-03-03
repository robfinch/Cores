rf80386_pkg::LOAD_CS_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_CS_DESC1);
	end
rf80386_pkg::LOAD_CS_DESC1:
	begin
		cs_desc <= dat;
		tReturn();
	end

rf80386_pkg::LOAD_DS_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DS_DESC1);
	end
rf80386_pkg::LOAD_DS_DESC1:
	begin
		ds_desc <= dat;
		tReturn();
	end

rf80386_pkg::LOAD_ES_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_ES_DESC1);
	end
rf80386_pkg::LOAD_ES_DESC1:
	begin
		es_desc <= dat;
		tReturn();
	end

rf80386_pkg::LOAD_SS_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_SS_DESC1);
	end
rf80386_pkg::LOAD_SS_DESC1:
	begin
		ss_desc <= dat;
		tReturn();
	end

rf80386_pkg::LOAD_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		case(rrr)
		3'd0:	if (es == selector) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd1:	if (cs == selector) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd2:	if (ss == selector) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd3:	if (ds == selector) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd4:	if (fs == selector) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		3'd5:	if (gs == selector) tReturn(); else tGosub(rf80386_pkg::LOAD,rf80386_pkg::LOAD_DESC1);
		default:	tGoto(RESET);
		endcase
	end
rf80386_pkg::LOAD_DESC1:
	begin
		case(rrr)
		3'd0:	es_desc <= dat;
		3'd1:	cs_desc <= dat;
		3'd2:	ss_desc <= dat;
		3'd3:	ds_desc <= dat;
		3'd4:	fs_desc <= dat;
		3'd5:	gs_desc <= dat;
		default:	;
		endcase
		tReturn();
	end

rf80386_pkg::LxDT:
	begin
		ad <= ea;
		if (lmsw)
			sel <= 16'h0003;
		else
			sel <= 16'h003F;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LxDT1);
	end
rf80386_pkg::LxDT1:
	begin
		if (lidt) begin
			idt.limit <= dat[15:0];
			idt.base <= cs_desc.db ? dat[47:16] : {8'h00,dat[39:16]};
		end
		else if (lgdt) begin
			gdt.limit <= dat[15:0];
			gdt.base <= cs_desc.db ? dat[47:16] : {8'h00,dat[39:16]};
		end
		else if (lmsw) begin
			cr0[3:0] <= dat[3:0];
		end
		tGoto(rf80386_pkg::IFETCH);
	end

rf80386_pkg::LLDT:
	begin
		ad <= ea;
		sel <= 16'h0003;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LLDT1);
	end
rf80386_pkg::LLDT1:
	begin
		selector <= dat[15:0];
		tGoto(rf80386_pkg::LLDT2);
	end
rf80386_pkg::LOAD_LLDT2:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LLDT3);
	end
rf80386_pkg::LLDT3:
	begin
		if (ltr) begin
			tr <= selector;
			tr_desc <= dat;
		end
		else begin
			ldt <= selector;
			ldt_desc <= dat;
		end
		tGoto(rf80386_pkg::IFETCH);
	end

rf80386_pkg::LAR:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::LAR1);
	end
rf80386_pkg::LAR1:
	begin
		zf <= 1'b1;
		wrregs <= 1'b1;
		if (lsl) begin
			if (dat[55])	// 'g' bit
				res <= {dat[51:48],dat[15:0],12'h0};
			else
				res <= {dat[51:48],dat[15:0]};
		end
		else begin
			if (cs_desc.db)
				res <= {8'h00,dat[55:52],4'h0,dat[47:40],8'h00};
			else
				res <= {dat[47:40],8'h00};
		end
		tReturn();
	end
