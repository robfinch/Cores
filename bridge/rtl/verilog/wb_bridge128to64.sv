import wishbone_pkg::*;

module wb_bridge128to64(req128_i, resp128_o, req64_o, resp64_i);
input wb_cmd_request128_t req128_i;
output wb_cmd_response128_t resp128_o;
output wb_cmd_request64_t req64_o;
input wb_cmd_response64_t resp64_i;

reg szerr;

always_comb
begin
	szerr = 1'b0;
	req64_o.om = req128_i.om;
	req64_o.cmd = req128_i.cmd;
	req64_o.cid = req128_i.cid;
	req64_o.tid = req128_i.tid;
	req64_o.bte = req128_i.bte;
	req64_o.blen = req128_i.blen;
	req64_o.cti = req128_i.cti;
	req64_o.seg = req128_i.seg;
	req64_o.sz = req128_i.sz;
	req64_o.cyc = req128_i.cyc;
	req64_o.stb = req128_i.stb;
	req64_o.we = req128_i.we;
	req64_o.sel = req128_i.sel[15:8]|req128_i.sel[7:0];
	req64_o.asid = req128_i.asid;
	req64_o.vadr = req128_i.vadr;
	req64_o.padr = req128_i.padr;
	case(req128_i.sel)
	16'h0001:	req64_o.dat = {8{req128_i.data1[7:0]}};
	16'h0002:	req64_o.dat = {8{req128_i.data1[15:8]}};
	16'h0004:	req64_o.dat = {8{req128_i.data1[23:16]}};
	16'h0008:	req64_o.dat = {8{req128_i.data1[31:24]}};
	16'h0010:	req64_o.dat = {8{req128_i.data1[39:32]}};
	16'h0020:	req64_o.dat = {8{req128_i.data1[47:40]}};
	16'h0040:	req64_o.dat = {8{req128_i.data1[55:48]}};
	16'h0080:	req64_o.dat = {8{req128_i.data1[63:56]}};
	16'h0100:	req64_o.dat = {8{req128_i.data1[71:64]}};
	16'h0200:	req64_o.dat = {8{req128_i.data1[79:72]}};
	16'h0400:	req64_o.dat = {8{req128_i.data1[87:80]}};
	16'h0800:	req64_o.dat = {8{req128_i.data1[95:88]}};
	16'h1000:	req64_o.dat = {8{req128_i.data1[103:96]}};
	16'h2000:	req64_o.dat = {8{req128_i.data1[111:104]}};
	16'h4000:	req64_o.dat = {8{req128_i.data1[119:112]}};
	16'h8000:	req64_o.dat = {8{req128_i.data1[127:120]}};
	16'h0003:	req64_o.dat = {4{req128_i.data1[15:0]}};
	16'h000C:	req64_o.dat = {4{req128_i.data1[31:16]}};
	16'h0030:	req64_o.dat = {4{req128_i.data1[47:32]}};
	16'h00C0:	req64_o.dat = {4{req128_i.data1[63:48]}};
	16'h0300:	req64_o.dat = {4{req128_i.data1[79:64]}};
	16'h0C00:	req64_o.dat = {4{req128_i.data1[95:80]}};
	16'h3000:	req64_o.dat = {4{req128_i.data1[111:96]}};
	16'hC000:	req64_o.dat = {4{req128_i.data1[127:112]}};
	16'h000F:	req64_o.dat = {2{req128_i.data1[31:0]}};
	16'h00F0:	req64_o.dat = {2{req128_i.data1[63:32]}};
	16'h0F00:	req64_o.dat = {2{req128_i.data1[95:64]}};
	16'hF000:	req64_o.dat = {2{req128_i.data1[127:96]}};
	16'h00FF:	req64_o.dat = req128_i.data1[63:0];
	16'hFF00:	req64_o.dat = req128_i.data1[127:64];
	default:	req64_o.dat = 'd0;
	endcase
	req64_o.pl = req128_i.pl;
	req64_o.pri = req128_i.pri;
	req64_o.cache = req128_i.cache;
	req64_o.csr = req128_i.csr;
	case(req128_i.sz)
	wishbone_pkg::octa,
	wishbone_pkg::hexi:
		szerr = 1'b1;
	default:	szerr = 1'b0;
	endcase
end

always_comb
begin
	resp128_o.cid = resp64_i.cid;
	resp128_o.tid = resp64_i.tid;
	resp128_o.pri = resp64_i.pri;
	resp128_o.stall = resp64_i.stall;
	resp128_o.next = resp64_i.next;
	resp128_o.ack = resp64_i.ack;
	resp128_o.err = resp64_i.err;
	resp128_o.rty = resp64_i.rty;
	resp128_o.dat = {2{resp64_i.dat}};
	resp128_o.adr = resp64_i.adr;
end

endmodule