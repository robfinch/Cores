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
	public partial class frmM : Form
	{
		public string cap;
		public string capn;

		public frmM()
		{
			InitializeComponent();
		}

		private void button1_Click(object sender, EventArgs e)
		{
			cap = "";
			capn = "";
			if (checkBox1.Checked)
				cap = "MUL,";
			else
				capn = "MUL,";
			if (checkBox2.Checked)
				cap += "MULH,";
			else
				capn += "MULH,";
			if (checkBox3.Checked)
				cap += "MULHSU,";
			else
				capn += "MULHSU,";
			if (checkBox4.Checked)
				cap += "MULHU,";
			else
				capn += "MULHU,";
			if (checkBox5.Checked)
				cap += "DIV,";
			else
				capn += "DIV,";
			if (checkBox6.Checked)
				cap += "DIVU,";
			else
				capn += "DIVU,";
			if (checkBox7.Checked)
				cap += "REM,";
			else
				capn += "REM,";
			if (checkBox8.Checked)
				cap += "REMU,";
			else
				capn += "REMU,";
		}

		private void frmM_Load(object sender, EventArgs e)
		{
			if (cap.Contains("MUL,"))
				checkBox1.Checked = true;
			if (cap.Contains("MULH,"))
				checkBox2.Checked = true;
			if (cap.Contains("MULHSU,"))
				checkBox3.Checked = true;
			if (cap.Contains("MULHU,"))
				checkBox4.Checked = true;
			if (cap.Contains("DIV,"))
				checkBox5.Checked = true;
			if (cap.Contains("DIVU,"))
				checkBox6.Checked = true;
			if (cap.Contains("REM,"))
				checkBox7.Checked = true;
			if (cap.Contains("REMU,"))
				checkBox7.Checked = true;
		}
	}
}
