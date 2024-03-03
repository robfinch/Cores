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
