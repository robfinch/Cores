rf80386_pkg::XCHG_MEM:
begin
	res <= b;
	tGoto(rf80386_pkg::STORE_DATA);
end
