import wishbone_pkg::*;

module wb_bridge128to32(req128_i, resp128_o, req32_o, resp32_i);
input wb_cmd_request128_t req128_i;
output wb_cmd_response128_t resp128_o;
output wb_cmd_request32_t req32_o;
input wb_cmd_response32_t resp32_i;

reg szerr;

always_comb
begin
	szerr = 1'b0;
	req32_o.om = req128_i.om;
	req32_o.cmd = req128_i.cmd;
	req32_o.cid = req128_i.cid;
	req32_o.tid = req128_i.tid;
	req32_o.bte = req128_i.bte;
	req32_o.blen = req128_i.blen;
	req32_o.cti = req128_i.cti;
	req32_o.seg = req128_i.seg;
	req32_o.sz = req128_i.sz;
	req32_o.cyc = req128_i.cyc;
	req32_o.stb = req128_i.stb;
	req32_o.we = req128_i.we;
	req32_o.sel = req128_i.sel[15:12]|req128_i.sel[11:8]|req128_i.sel[7:4]|req128_i.sel[3:0];
	req32_o.asid = req128_i.asid;
	req32_o.vadr = req128_i.vadr;
	req32_o.padr = req128_i.padr;
	case(req128_i.sel)
	16'h0001:	req32_o.dat = {4{req128_i.data1[7:0]}};
	16'h0002:	req32_o.dat = {4{req128_i.data1[15:8]}};
	16'h0004:	req32_o.dat = {4{req128_i.data1[23:16]}};
	16'h0008:	req32_o.dat = {4{req128_i.data1[31:24]}};
	16'h0010:	req32_o.dat = {4{req128_i.data1[39:32]}};
	16'h0020:	req32_o.dat = {4{req128_i.data1[47:40]}};
	16'h0040:	req32_o.dat = {4{req128_i.data1[55:48]}};
	16'h0080:	req32_o.dat = {4{req128_i.data1[63:56]}};
	16'h0100:	req32_o.dat = {4{req128_i.data1[71:64]}};
	16'h0200:	req32_o.dat = {4{req128_i.data1[79:72]}};
	16'h0400:	req32_o.dat = {4{req128_i.data1[87:80]}};
	16'h0800:	req32_o.dat = {4{req128_i.data1[95:88]}};
	16'h1000:	req32_o.dat = {4{req128_i.data1[103:96]}};
	16'h2000:	req32_o.dat = {4{req128_i.data1[111:104]}};
	16'h4000:	req32_o.dat = {4{req128_i.data1[119:112]}};
	16'h8000:	req32_o.dat = {4{req128_i.data1[127:120]}};
	16'h0003:	req32_o.dat = {2{req128_i.data1[15:0]}};
	16'h000C:	req32_o.dat = {2{req128_i.data1[31:16]}};
	16'h0030:	req32_o.dat = {2{req128_i.data1[47:32]}};
	16'h00C0:	req32_o.dat = {2{req128_i.data1[63:48]}};
	16'h0300:	req32_o.dat = {2{req128_i.data1[79:64]}};
	16'h0C00:	req32_o.dat = {2{req128_i.data1[95:80]}};
	16'h3000:	req32_o.dat = {2{req128_i.data1[111:96]}};
	16'hC000:	req32_o.dat = {2{req128_i.data1[127:112]}};
	16'h000F:	req32_o.dat = req128_i.data1[31:0];
	16'h00F0:	req32_o.dat = req128_i.data1[63:32];
	16'h0F00:	req32_o.dat = req128_i.data1[95:64];
	16'hF000:	req32_o.dat = req128_i.data1[127:96];
	default:	req32_o.dat = 'd0;
	endcase
	req32_o.pl = req128_i.pl;
	req32_o.pri = req128_i.pri;
	req32_o.cache = req128_i.cache;
	req32_o.csr = req128_i.csr;
	case(req128_i.sz)
	wishbone_pkg::octa,
	wishbone_pkg::hexi:
		szerr = 1'b1;
	default:	szerr = 1'b0;
	endcase
end

always_comb
begin
	resp128_o.cid = resp32_i.cid;
	resp128_o.tid = resp32_i.tid;
	resp128_o.pri = resp32_i.pri;
	resp128_o.stall = resp32_i.stall;
	resp128_o.next = resp32_i.next;
	resp128_o.ack = resp32_i.ack;
	resp128_o.err = resp32_i.err;
	resp128_o.rty = resp32_i.rty;
	resp128_o.dat = {4{resp32_i.dat}};
	resp128_o.adr = resp32_i.adr;
end

endmodule