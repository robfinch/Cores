using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FriscCoreGen
{
	public partial class frmCache : Form
	{
		int ways;
		string L1ICacheCmpNWay;

		public frmCache()
		{
			InitializeComponent();
		}

		private void button3_Click(object sender, EventArgs e)
		{
			int nn;
			int l2;
			string pfx;
			string ab;
			int ls;
			ways = Convert.ToInt16(comboBox3.Text);
			L1ICacheCmpNWay = "L1_icache_cmpNway(rst, clk, nxt, wr, invline, invall, adr, lineno,";
			if (radioButton4.Checked)
				L1ICacheCmpNWay = L1ICacheCmpNWay + "nxt_lineno,";
			L1ICacheCmpNWay = L1ICacheCmpNWay + " hit, missadr);\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "parameter AMSB = " + numericUpDown1.Value + ";\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "parameter pLines = " + comboBox2.Text + ";\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "localparam pLNMSB = $clog2(" + comboBox2.Text + ");\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "input rst;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "input clk;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "input nxt;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "input wr;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "input invline;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "input invall;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "input [AMSB:0] adr;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "output reg [pLNMSB:0] lineno;\r\n";
			if (radioButton4.Checked)
				L1ICacheCmpNWay = L1ICacheCmpNWay + "output reg [pLNMSB:0] nxt_lineno;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "output reg hit;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "output reg [AMSB:0] missadr;\r\n\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "reg [AMSB:0] radr;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "(* ram_style=\"distributed\" *);\r\n";
			for (nn = 0; nn < ways; nn++)
			{
				L1ICacheCmpNWay = L1ICacheCmpNWay + "reg [AMSB-5:0] mem" + nn.ToString() + " [0:pLines/" + ways.ToString() + "-1];\r\n";
				L1ICacheCmpNWay = L1ICacheCmpNWay + "reg [pLines/" + ways.ToString() + "-1:0] mem" + nn.ToString() + "v;\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "integer n;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "intial begin\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  for (n = 0; n < pLines/" + ways.ToString() + "; n = n + 1) begin\r\n";
			for (nn = 0; nn < ways; nn++)
			{
				L1ICacheCmpNWay = L1ICacheCmpNWay + "    mem" + nn.ToString() + "[n] = 0;\r\n";
				L1ICacheCmpNWay = L1ICacheCmpNWay + "    mem" + nn.ToString() + "v[n] = 0;\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  end\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "end\r\n\r\n";
			if (radioButton4.Checked)
				L1ICacheCmpNWay = L1ICacheCmpNWay + "wire [AMSB:0] nxt_adr = adr + 9'd" + comboBox1.Text + ";\r\n\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "wire [21:0] lfsro\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "reg [pLNMSB:0] wlineno;";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "always @(posedge clk)\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "if (rst)";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  wlineno <= 1'd0;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "else begin\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) begin\r\n";
			pfx = "";
			switch(ways)
			{
				case 1:	break;
				case 2: pfx = "1'd";  L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[0])\r\n"; break;
				case 4: pfx = "2'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[1:0])\r\n"; break;
				case 8: pfx = "3'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[2:0])\r\n"; break;
				case 16: pfx = "4'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[3:0])\r\n"; break;
				case 32: pfx = "5'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[4:0])\r\n"; break;
			}
			ls = Convert.ToInt16(comboBox1.Text);
			if (ls > 64)
				ab = "7";
			else if (ls > 32)
				ab = "6";
			else if (ls > 16)
				ab = "5";
			else if (ls > 8)
				ab = "4";
			else if (ls > 4)
				ab = "3";
			else if (ls > 2)
				ab = "2";
			else
				ab = "1";
			for (nn = 0; nn < ways; nn++ )
			{
				L1ICacheCmpNWay = L1ICacheCmpNWay + "    " + pfx + nn.ToString() + ":	begin  mem" + nn.ToString() + "[adr[pMSB:"+ab+ "]] <= adr[AMSB:" + ab + "];  wlineno <= {" + pfx + nn.ToString() + ",adr[pMSB:" + ab + "]}; end\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "    endcase\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  end\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "end\r\n\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "always @(posedge clk)\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "if (rst) begin\r\n";
			for (nn = 0; nn < ways; nn++)
			{
				L1ICacheCmpNWay = L1ICacheCmpNWay + "  mem" + nn.ToString() + "v <= 1'd0;\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "end\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "else begin\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (invall) begin\r\n";
			for (nn = 0; nn < ways; nn++)
			{
				L1ICacheCmpNWay = L1ICacheCmpNWay + "    mem" + nn.ToString() + "v <= 1'd0;\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  end\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  else if (invline) begin\r\n";
			for (nn = 0; nn < ways; nn++)
				L1ICacheCmpNWay = L1ICacheCmpNWay + "    if (hit" + nn.ToString() + ") mem" + nn.ToString() + "v[adr[pMSB:"+ab+"]] <= 1'b0;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  end\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  else if (wr) begin\r\n";
			switch (ways)
			{
				case 1: break;
				case 2: pfx = "1'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[0])\r\n"; break;
				case 4: pfx = "2'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[1:0])\r\n"; break;
				case 8: pfx = "3'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[2:0])\r\n"; break;
				case 16: pfx = "4'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[3:0])\r\n"; break;
				case 32: pfx = "5'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "    case(lfsro[4:0])\r\n"; break;
			}
			for (nn = 0; nn < ways; nn++)
			{
				L1ICacheCmpNWay = L1ICacheCmpNWay + "    " + pfx + nn.ToString() + ":	begin  mem" + nn.ToString() + "v[adr[pMSB:" + ab + "]] <= 1'b1; end\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "    endcase\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  end\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "end\r\n\r\n";
			for (nn = 0; nn < ways; nn++)
				L1ICacheCmpNWay = L1ICacheCmpNWay + "wire hit"+nn.ToString() + " = mem" + nn.ToString() + "[adr[pMSB:" + ab + "]] & mem" + nn.ToString() + "v[adr[pMSB:" + ab + "]];\r\n";
			if (radioButton4.Checked)
				for (nn = 0; nn < ways; nn++)
					L1ICacheCmpNWay = L1ICacheCmpNWay + "wire hit" + nn.ToString() + "n = mem" + nn.ToString() + "[nxt_adr[pMSB:" + ab + "]] & mem" + nn.ToString() + "v[nxt_adr[pMSB:" + ab + "]];\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "always @*\r\n";
			if (radioButton4.Checked)
			{
				int wa = Convert.ToInt16(comboBox1.Text) - Convert.ToInt16(numericUpDown2.Value) - 1;
				L1ICacheCmpNWay = L1ICacheCmpNWay + "if (adr[" + Convert.ToString(Convert.ToInt16(ab)-1) + ":0] > 9'd" + wa.ToString() + ") begin\r\n";
				switch(ways)
				{
					case 1: break;
					case 2: pfx = "1'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[0],adr[pMSB:" + ab + "]};\r\n"; break;
					case 4: pfx = "2'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[1:0],adr[pMSB:" + ab + "]};\r\n"; break;
					case 8: pfx = "3'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[2:0],adr[pMSB:" + ab + "]};\r\n"; break;
					case 16: pfx = "4'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[3:0],adr[pMSB:" + ab + "]};\r\n"; break;
					case 32: pfx = "5'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[4:0],adr[pMSB:" + ab + "]};\r\n"; break;
				}
				for (nn = 0; nn < ways - 1; nn++)
				{
					L1ICacheCmpNWay = L1ICacheCmpNWay + "  else if (hit" + nn.ToString() + ") lineno = {" + pfx + nn.ToString() + ",adr[pMSB:" + ab + "]};\r\n";
				}
				L1ICacheCmpNWay = L1ICacheCmpNWay + "  else lineno = {" + pfx + nn.ToString() + ",adr[pMSB:" + ab + "]};\r\n";
				nn = 0;
				L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (hit" + nn.ToString() + "n) nxt_lineno = {" + pfx + nn.ToString() + ",nxt_adr[pMSB:" + ab + "]};\r\n";
				for (nn = 1; nn < ways - 1; nn++)
				{
					L1ICacheCmpNWay = L1ICacheCmpNWay + "  else if (hit" + nn.ToString() + "n) nxt_lineno = {" + pfx + nn.ToString() + ",nxt_adr[pMSB:" + ab + "]};\r\n";
				}
				L1ICacheCmpNWay = L1ICacheCmpNWay + "  else nxt_lineno = {" + pfx + nn.ToString() + ",nxt_adr[pMSB:" + ab + "]};\r\n";
				L1ICacheCmpNWay = L1ICacheCmpNWay + "  hit = \r\n";
				for (nn = 0; nn < ways-1; nn++)
				{
					L1ICacheCmpNWay = L1ICacheCmpNWay + "    (hit"+nn.ToString() + " & hit" +nn.ToString() + "n) |\r\n";
				}
				L1ICacheCmpNWay = L1ICacheCmpNWay + "    (hit" + nn.ToString() + " & hit" + nn.ToString() + "n);\r\n";
				L1ICacheCmpNWay = L1ICacheCmpNWay + "  missadr = (";
				for (nn = 0; nn < ways-1; nn++)
					L1ICacheCmpNWay = L1ICacheCmpNWay + "hit" + nn.ToString() + "|";
				L1ICacheCmpNWay = L1ICacheCmpNWay + "hit" + nn.ToString() + ") ? nxt_adr : adr;\r\n";
				L1ICacheCmpNWay = L1ICacheCmpNWay + "end else\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "begin\r\n";
			switch (ways)
			{
				case 1: break;
				case 2: pfx = "1'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[0],adr[pMSB:" + ab + "]};\r\n"; break;
				case 4: pfx = "2'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[1:0],adr[pMSB:" + ab + "]};\r\n"; break;
				case 8: pfx = "3'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[2:0],adr[pMSB:" + ab + "]};\r\n"; break;
				case 16: pfx = "4'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[3:0],adr[pMSB:" + ab + "]};\r\n"; break;
				case 32: pfx = "5'd"; L1ICacheCmpNWay = L1ICacheCmpNWay + "  if (wr) lineno = {lfsro[4:0],adr[pMSB:" + ab + "]};\r\n"; break;
			}
			for (nn = 0; nn < ways - 1; nn++)
			{
				L1ICacheCmpNWay = L1ICacheCmpNWay + "  else if (hit" + nn.ToString() + ") lineno = {" + pfx + nn.ToString() + ",adr[pMSB:" + ab + "]};\r\n";
			}
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  else lineno = {" + pfx + nn.ToString() + ",adr[pMSB:" + ab + "]};\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "  hit = ";
			for (nn = 0; nn < ways - 1; nn++)
				L1ICacheCmpNWay = L1ICacheCmpNWay + "hit" + nn.ToString() + "|";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "hit" + nn.ToString() + ";\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "missadr = adr;\r\n";
			L1ICacheCmpNWay = L1ICacheCmpNWay + "end\r\n";
			textBox1.Text = L1ICacheCmpNWay;
		}
	}
}
