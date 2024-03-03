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

rf80386_pkg::LxDT:
	begin
		ad <= ea;
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
		ldt_desc <= dat;
		tGoto(rf80386_pkg::IFETCH);
	end
