LOAD_CS_DESC:
	begin
		if (selector.ti)
			ad <= ldt_base + {selector.ndx,3'd0};
		else
			ad <= gdt_base + {selector.ndx,3'd0};
		sel <= 16'h00FF;
		tGosub(LOAD,LOAD_CS_DESC1);
	end
LOAD_CS_DESC1:
	begin
		cs_desc <= dat;
	end
