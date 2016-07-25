#pragma once
#include <cstdlib>

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Threading;
	using namespace System::Runtime::InteropServices;

	/// <summary>
	/// Summary for frmRegisters
	/// </summary>
	public ref class frmRegisters : public System::Windows::Forms::Form
	{
	public:
		Mutex^ mut;
		frmRegisters(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			UpdateForm();
			toolTipC1->SetToolTip(txtCa1, "C1 is typically used to store the subroutine return address.\n The short form RTS instruction expects this register to contain the return address.");
			toolTipC8->SetToolTip(txtCa8, "C8 and C9 are typically used by the compiler as register variables to store\n"
				"the address of a subroutine called multiple times.");
			toolTipC8->SetToolTip(txtCa9, "C8 and C9 are typically used by the compiler as register variables to store\n"
				"the address of a subroutine called multiple times.");
			toolTipC10->SetToolTip(txtCa10, "C10 is used by the compiler to store the catch handler link address.\n");
			toolTipC12->SetToolTip(txtCa12, "C12 specifies the location of the interrupt vector table in memory.");
			toolTipC14->SetToolTip(txtCa14, "C14 contains the address at which an interrupt occurred.\nThe RTI instruction uses this register to determine where to return.");
			toolTipR0->SetToolTip(txtR0, "R0 is always zero and can't be altered.");
			toolTipR28->SetToolTip(txtR28, "ISP / R28 is the interrupt mode stack pointer. References to R27 will be re-routed to this register.\n"
				"R28 is accessible only from a kernel mode.");
			toolTipR29->SetToolTip(txtR29, "ESP / R29 is the exception mode stack pointer. References to R27 will be re-routed to this register.\n"
				"R29 is accessible only from a kernel mode.");
			toolTipR30->SetToolTip(txtR30, "DSP / R30 is the debug mode stack pointer. References to R27 will be re-routed to this register.\n"
				"R30 is accessible only from a kernel mode.");
			toolTipR31->SetToolTip(txtR31, "TR / R31 is used by the system as the Task Register which points to the active task control block.\n"
				"R31 is accessible only from a kernel mode.");
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmRegisters()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TabControl^  tabControl1;
	protected: 
	private: System::Windows::Forms::TabPage^  tabPage1;
	private: System::Windows::Forms::TextBox^  txtR1;

	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::TextBox^  txtR0;

	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::TabPage^  tabPage2;
	private: System::Windows::Forms::TextBox^  txtR63;

	private: System::Windows::Forms::Label^  label49;
	private: System::Windows::Forms::TextBox^  txtR62;

	private: System::Windows::Forms::Label^  label50;
	private: System::Windows::Forms::TextBox^  txtR61;

	private: System::Windows::Forms::Label^  label51;
	private: System::Windows::Forms::TextBox^  txtR60;

	private: System::Windows::Forms::Label^  label52;
	private: System::Windows::Forms::TextBox^  txtR59;

	private: System::Windows::Forms::Label^  label53;
	private: System::Windows::Forms::TextBox^  txtR58;

	private: System::Windows::Forms::Label^  label54;
	private: System::Windows::Forms::TextBox^  txtR57;

	private: System::Windows::Forms::Label^  label55;
	private: System::Windows::Forms::TextBox^  txtR56;

	private: System::Windows::Forms::Label^  label56;
	private: System::Windows::Forms::TextBox^  txtR55;

	private: System::Windows::Forms::Label^  label57;
	private: System::Windows::Forms::TextBox^  txtR54;

	private: System::Windows::Forms::Label^  label58;
private: System::Windows::Forms::TextBox^  txtR53;

	private: System::Windows::Forms::Label^  label59;
private: System::Windows::Forms::TextBox^  txtR52;

	private: System::Windows::Forms::Label^  label60;
private: System::Windows::Forms::TextBox^  txtR51;

	private: System::Windows::Forms::Label^  label61;
private: System::Windows::Forms::TextBox^  txtR50;

	private: System::Windows::Forms::Label^  label62;
private: System::Windows::Forms::TextBox^  txtR49;

	private: System::Windows::Forms::Label^  label63;
private: System::Windows::Forms::TextBox^  txtR48;

	private: System::Windows::Forms::Label^  label64;
private: System::Windows::Forms::TextBox^  txtR47;

	private: System::Windows::Forms::Label^  label33;
private: System::Windows::Forms::TextBox^  txtR46;

	private: System::Windows::Forms::Label^  label34;
private: System::Windows::Forms::TextBox^  txtR45;

	private: System::Windows::Forms::Label^  label35;
private: System::Windows::Forms::TextBox^  txtR44;

	private: System::Windows::Forms::Label^  label36;
private: System::Windows::Forms::TextBox^  txtR43;

	private: System::Windows::Forms::Label^  label37;
private: System::Windows::Forms::TextBox^  txtR42;

	private: System::Windows::Forms::Label^  label38;
private: System::Windows::Forms::TextBox^  txtR41;

	private: System::Windows::Forms::Label^  label39;
private: System::Windows::Forms::TextBox^  txtR40;

	private: System::Windows::Forms::Label^  label40;
private: System::Windows::Forms::TextBox^  txtR39;

	private: System::Windows::Forms::Label^  label41;
private: System::Windows::Forms::TextBox^  txtR38;

	private: System::Windows::Forms::Label^  label42;
private: System::Windows::Forms::TextBox^  txtR37;

	private: System::Windows::Forms::Label^  label43;
private: System::Windows::Forms::TextBox^  txtR36;

	private: System::Windows::Forms::Label^  label44;
private: System::Windows::Forms::TextBox^  txtR35;

	private: System::Windows::Forms::Label^  label45;
private: System::Windows::Forms::TextBox^  txtR34;

	private: System::Windows::Forms::Label^  label46;
private: System::Windows::Forms::TextBox^  txtR33;

	private: System::Windows::Forms::Label^  label47;
private: System::Windows::Forms::TextBox^  txtR32;

	private: System::Windows::Forms::Label^  label48;
private: System::Windows::Forms::TextBox^  txtR31;

	private: System::Windows::Forms::Label^  label17;
private: System::Windows::Forms::TextBox^  txtR30;

	private: System::Windows::Forms::Label^  label18;
private: System::Windows::Forms::TextBox^  txtR29;

	private: System::Windows::Forms::Label^  label19;
private: System::Windows::Forms::TextBox^  txtR28;

	private: System::Windows::Forms::Label^  label20;
private: System::Windows::Forms::TextBox^  txtR27;

	private: System::Windows::Forms::Label^  label21;
private: System::Windows::Forms::TextBox^  txtR26;

	private: System::Windows::Forms::Label^  label22;
private: System::Windows::Forms::TextBox^  txtR25;

	private: System::Windows::Forms::Label^  label23;
private: System::Windows::Forms::TextBox^  txtR24;

	private: System::Windows::Forms::Label^  label24;
private: System::Windows::Forms::TextBox^  txtR23;

	private: System::Windows::Forms::Label^  label25;
private: System::Windows::Forms::TextBox^  txtR22;

	private: System::Windows::Forms::Label^  label26;
private: System::Windows::Forms::TextBox^  txtR21;

	private: System::Windows::Forms::Label^  label27;
private: System::Windows::Forms::TextBox^  txtR20;

	private: System::Windows::Forms::Label^  label28;
private: System::Windows::Forms::TextBox^  txtR19;

	private: System::Windows::Forms::Label^  label29;
private: System::Windows::Forms::TextBox^  txtR18;

	private: System::Windows::Forms::Label^  label30;
private: System::Windows::Forms::TextBox^  txtR17;

	private: System::Windows::Forms::Label^  label31;
private: System::Windows::Forms::TextBox^  txtR16;

	private: System::Windows::Forms::Label^  label32;
private: System::Windows::Forms::TextBox^  txtR15;

	private: System::Windows::Forms::Label^  label9;
private: System::Windows::Forms::TextBox^  txtR14;

	private: System::Windows::Forms::Label^  label10;
private: System::Windows::Forms::TextBox^  txtR13;

	private: System::Windows::Forms::Label^  label11;
private: System::Windows::Forms::TextBox^  txtR12;

	private: System::Windows::Forms::Label^  label12;
private: System::Windows::Forms::TextBox^  txtR11;

	private: System::Windows::Forms::Label^  label13;
private: System::Windows::Forms::TextBox^  txtR10;

	private: System::Windows::Forms::Label^  label14;
private: System::Windows::Forms::TextBox^  txtR9;

	private: System::Windows::Forms::Label^  label15;
private: System::Windows::Forms::TextBox^  txtR8;

	private: System::Windows::Forms::Label^  label16;
private: System::Windows::Forms::TextBox^  txtR7;

	private: System::Windows::Forms::Label^  label5;
private: System::Windows::Forms::TextBox^  txtR6;

	private: System::Windows::Forms::Label^  label6;
private: System::Windows::Forms::TextBox^  txtR5;

	private: System::Windows::Forms::Label^  label7;
private: System::Windows::Forms::TextBox^  txtR4;

	private: System::Windows::Forms::Label^  label8;
private: System::Windows::Forms::TextBox^  txtR3;

	private: System::Windows::Forms::Label^  label3;
private: System::Windows::Forms::TextBox^  txtR2;

	private: System::Windows::Forms::Label^  label4;
private: System::Windows::Forms::Label^  label109;
private: System::Windows::Forms::Label^  label108;
private: System::Windows::Forms::Label^  label107;
private: System::Windows::Forms::Label^  label106;
private: System::Windows::Forms::Label^  label105;
private: System::Windows::Forms::TextBox^  txtCsLmt;

private: System::Windows::Forms::TextBox^  txtCs;

private: System::Windows::Forms::Label^  label104;
private: System::Windows::Forms::TextBox^  txtSsLmt;


private: System::Windows::Forms::TextBox^  txtSs;

private: System::Windows::Forms::Label^  label103;
private: System::Windows::Forms::TextBox^  txtHsLmt;

private: System::Windows::Forms::TextBox^  txtHs;

private: System::Windows::Forms::Label^  label102;
private: System::Windows::Forms::TextBox^  txtGsLmt;

private: System::Windows::Forms::TextBox^  txtGs;

private: System::Windows::Forms::Label^  label101;
private: System::Windows::Forms::TextBox^  txtFsLmt;

private: System::Windows::Forms::TextBox^  txtFs;

private: System::Windows::Forms::Label^  label100;
private: System::Windows::Forms::TextBox^  txtEsLmt;

private: System::Windows::Forms::TextBox^  txtEs;

private: System::Windows::Forms::Label^  label99;
private: System::Windows::Forms::TextBox^  txtDsLmt;

private: System::Windows::Forms::TextBox^  txtDs;

private: System::Windows::Forms::Label^  label98;
private: System::Windows::Forms::TextBox^  txtZsLmt;


private: System::Windows::Forms::TextBox^  txtZs;

private: System::Windows::Forms::Label^  label97;
private: System::Windows::Forms::TextBox^  txtCa15;

private: System::Windows::Forms::Label^  label96;
private: System::Windows::Forms::TextBox^  txtCa14;

private: System::Windows::Forms::Label^  label95;
private: System::Windows::Forms::TextBox^  txtCa13;

private: System::Windows::Forms::Label^  label94;
private: System::Windows::Forms::TextBox^  txtCa12;

private: System::Windows::Forms::Label^  label93;
private: System::Windows::Forms::TextBox^  txtCa11;

private: System::Windows::Forms::Label^  label92;
private: System::Windows::Forms::TextBox^  txtCa10;

private: System::Windows::Forms::Label^  label91;
private: System::Windows::Forms::TextBox^  txtCa9;

private: System::Windows::Forms::Label^  label90;
private: System::Windows::Forms::TextBox^  txtCa8;

private: System::Windows::Forms::Label^  label89;
private: System::Windows::Forms::TextBox^  txtCa7;

private: System::Windows::Forms::Label^  label88;
private: System::Windows::Forms::TextBox^  txtCa6;

private: System::Windows::Forms::Label^  label87;
private: System::Windows::Forms::TextBox^  txtCa5;

private: System::Windows::Forms::Label^  label86;
private: System::Windows::Forms::TextBox^  txtCa4;

private: System::Windows::Forms::Label^  label85;
private: System::Windows::Forms::TextBox^  txtCa3;

private: System::Windows::Forms::Label^  label84;
private: System::Windows::Forms::TextBox^  txtCa2;

private: System::Windows::Forms::Label^  label83;
private: System::Windows::Forms::TextBox^  txtCa1;

private: System::Windows::Forms::Label^  label82;
private: System::Windows::Forms::TextBox^  textBox16;
private: System::Windows::Forms::Label^  label81;
private: System::Windows::Forms::TextBox^  txtP14;

private: System::Windows::Forms::Label^  label80;
private: System::Windows::Forms::TextBox^  txtP13;

private: System::Windows::Forms::Label^  label79;
private: System::Windows::Forms::TextBox^  txtP12;

private: System::Windows::Forms::Label^  label78;
private: System::Windows::Forms::TextBox^  txtP11;

private: System::Windows::Forms::Label^  label77;
private: System::Windows::Forms::TextBox^  txtP15;

private: System::Windows::Forms::Label^  label76;
private: System::Windows::Forms::TextBox^  txtP10;

private: System::Windows::Forms::Label^  label75;
private: System::Windows::Forms::TextBox^  txtP9;

private: System::Windows::Forms::Label^  label74;
private: System::Windows::Forms::TextBox^  txtP8;

private: System::Windows::Forms::Label^  label73;
private: System::Windows::Forms::TextBox^  txtP7;

private: System::Windows::Forms::Label^  label72;
private: System::Windows::Forms::TextBox^  txtP6;

private: System::Windows::Forms::Label^  label71;
private: System::Windows::Forms::TextBox^  txtP5;

private: System::Windows::Forms::Label^  label70;
private: System::Windows::Forms::TextBox^  txtP4;

private: System::Windows::Forms::Label^  label69;
private: System::Windows::Forms::TextBox^  txtP3;

private: System::Windows::Forms::Label^  label68;
private: System::Windows::Forms::TextBox^  txtP2;

private: System::Windows::Forms::Label^  label67;
private: System::Windows::Forms::TextBox^  txtP1;

private: System::Windows::Forms::Label^  label66;
private: System::Windows::Forms::TextBox^  txtP0;
private: System::Windows::Forms::Label^  label65;
private: System::Windows::Forms::Label^  label116;
private: System::Windows::Forms::TextBox^  txtDBSTAT;

private: System::Windows::Forms::Label^  label115;
private: System::Windows::Forms::TextBox^  txtDBCTRL;

private: System::Windows::Forms::Label^  label114;
private: System::Windows::Forms::TextBox^  txtDBAD3;

private: System::Windows::Forms::Label^  label113;
private: System::Windows::Forms::TextBox^  txtDBAD2;

private: System::Windows::Forms::Label^  label112;
private: System::Windows::Forms::TextBox^  txtDBAD1;

private: System::Windows::Forms::Label^  label111;
private: System::Windows::Forms::TextBox^  txtDBAD0;

private: System::Windows::Forms::Label^  label110;
private: System::Windows::Forms::TextBox^  txtTick;
private: System::Windows::Forms::Label^  label118;
private: System::Windows::Forms::TextBox^  txtLC;
private: System::Windows::Forms::Label^  label117;
private: System::Windows::Forms::ToolTip^  toolTipC12;
private: System::Windows::Forms::ToolTip^  toolTipC14;
private: System::Windows::Forms::ToolTip^  toolTipC1;
private: System::Windows::Forms::ToolTip^  toolTipR31;
private: System::Windows::Forms::ToolTip^  toolTipR30;
private: System::Windows::Forms::ToolTip^  toolTipR29;
private: System::Windows::Forms::ToolTip^  toolTipR28;
private: System::Windows::Forms::ToolTip^  toolTipC8;
private: System::Windows::Forms::ToolTip^  toolTipR0;
private: System::Windows::Forms::Button^  btnUpdate;
private: System::Windows::Forms::ToolTip^  toolTipC10;
private: System::ComponentModel::IContainer^  components;

	protected: 

































































































































	private:
		/// <summary>
		/// Required designer variable.
		/// </summary>


#pragma region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		void InitializeComponent(void)
		{
			this->components = (gcnew System::ComponentModel::Container());
			this->tabControl1 = (gcnew System::Windows::Forms::TabControl());
			this->tabPage1 = (gcnew System::Windows::Forms::TabPage());
			this->txtR63 = (gcnew System::Windows::Forms::TextBox());
			this->label49 = (gcnew System::Windows::Forms::Label());
			this->txtR62 = (gcnew System::Windows::Forms::TextBox());
			this->label50 = (gcnew System::Windows::Forms::Label());
			this->txtR61 = (gcnew System::Windows::Forms::TextBox());
			this->label51 = (gcnew System::Windows::Forms::Label());
			this->txtR60 = (gcnew System::Windows::Forms::TextBox());
			this->label52 = (gcnew System::Windows::Forms::Label());
			this->txtR59 = (gcnew System::Windows::Forms::TextBox());
			this->label53 = (gcnew System::Windows::Forms::Label());
			this->txtR58 = (gcnew System::Windows::Forms::TextBox());
			this->label54 = (gcnew System::Windows::Forms::Label());
			this->txtR57 = (gcnew System::Windows::Forms::TextBox());
			this->label55 = (gcnew System::Windows::Forms::Label());
			this->txtR56 = (gcnew System::Windows::Forms::TextBox());
			this->label56 = (gcnew System::Windows::Forms::Label());
			this->txtR55 = (gcnew System::Windows::Forms::TextBox());
			this->label57 = (gcnew System::Windows::Forms::Label());
			this->txtR54 = (gcnew System::Windows::Forms::TextBox());
			this->label58 = (gcnew System::Windows::Forms::Label());
			this->txtR53 = (gcnew System::Windows::Forms::TextBox());
			this->label59 = (gcnew System::Windows::Forms::Label());
			this->txtR52 = (gcnew System::Windows::Forms::TextBox());
			this->label60 = (gcnew System::Windows::Forms::Label());
			this->txtR51 = (gcnew System::Windows::Forms::TextBox());
			this->label61 = (gcnew System::Windows::Forms::Label());
			this->txtR50 = (gcnew System::Windows::Forms::TextBox());
			this->label62 = (gcnew System::Windows::Forms::Label());
			this->txtR49 = (gcnew System::Windows::Forms::TextBox());
			this->label63 = (gcnew System::Windows::Forms::Label());
			this->txtR48 = (gcnew System::Windows::Forms::TextBox());
			this->label64 = (gcnew System::Windows::Forms::Label());
			this->txtR47 = (gcnew System::Windows::Forms::TextBox());
			this->label33 = (gcnew System::Windows::Forms::Label());
			this->txtR46 = (gcnew System::Windows::Forms::TextBox());
			this->label34 = (gcnew System::Windows::Forms::Label());
			this->txtR45 = (gcnew System::Windows::Forms::TextBox());
			this->label35 = (gcnew System::Windows::Forms::Label());
			this->txtR44 = (gcnew System::Windows::Forms::TextBox());
			this->label36 = (gcnew System::Windows::Forms::Label());
			this->txtR43 = (gcnew System::Windows::Forms::TextBox());
			this->label37 = (gcnew System::Windows::Forms::Label());
			this->txtR42 = (gcnew System::Windows::Forms::TextBox());
			this->label38 = (gcnew System::Windows::Forms::Label());
			this->txtR41 = (gcnew System::Windows::Forms::TextBox());
			this->label39 = (gcnew System::Windows::Forms::Label());
			this->txtR40 = (gcnew System::Windows::Forms::TextBox());
			this->label40 = (gcnew System::Windows::Forms::Label());
			this->txtR39 = (gcnew System::Windows::Forms::TextBox());
			this->label41 = (gcnew System::Windows::Forms::Label());
			this->txtR38 = (gcnew System::Windows::Forms::TextBox());
			this->label42 = (gcnew System::Windows::Forms::Label());
			this->txtR37 = (gcnew System::Windows::Forms::TextBox());
			this->label43 = (gcnew System::Windows::Forms::Label());
			this->txtR36 = (gcnew System::Windows::Forms::TextBox());
			this->label44 = (gcnew System::Windows::Forms::Label());
			this->txtR35 = (gcnew System::Windows::Forms::TextBox());
			this->label45 = (gcnew System::Windows::Forms::Label());
			this->txtR34 = (gcnew System::Windows::Forms::TextBox());
			this->label46 = (gcnew System::Windows::Forms::Label());
			this->txtR33 = (gcnew System::Windows::Forms::TextBox());
			this->label47 = (gcnew System::Windows::Forms::Label());
			this->txtR32 = (gcnew System::Windows::Forms::TextBox());
			this->label48 = (gcnew System::Windows::Forms::Label());
			this->txtR31 = (gcnew System::Windows::Forms::TextBox());
			this->label17 = (gcnew System::Windows::Forms::Label());
			this->txtR30 = (gcnew System::Windows::Forms::TextBox());
			this->label18 = (gcnew System::Windows::Forms::Label());
			this->txtR29 = (gcnew System::Windows::Forms::TextBox());
			this->label19 = (gcnew System::Windows::Forms::Label());
			this->txtR28 = (gcnew System::Windows::Forms::TextBox());
			this->label20 = (gcnew System::Windows::Forms::Label());
			this->txtR27 = (gcnew System::Windows::Forms::TextBox());
			this->label21 = (gcnew System::Windows::Forms::Label());
			this->txtR26 = (gcnew System::Windows::Forms::TextBox());
			this->label22 = (gcnew System::Windows::Forms::Label());
			this->txtR25 = (gcnew System::Windows::Forms::TextBox());
			this->label23 = (gcnew System::Windows::Forms::Label());
			this->txtR24 = (gcnew System::Windows::Forms::TextBox());
			this->label24 = (gcnew System::Windows::Forms::Label());
			this->txtR23 = (gcnew System::Windows::Forms::TextBox());
			this->label25 = (gcnew System::Windows::Forms::Label());
			this->txtR22 = (gcnew System::Windows::Forms::TextBox());
			this->label26 = (gcnew System::Windows::Forms::Label());
			this->txtR21 = (gcnew System::Windows::Forms::TextBox());
			this->label27 = (gcnew System::Windows::Forms::Label());
			this->txtR20 = (gcnew System::Windows::Forms::TextBox());
			this->label28 = (gcnew System::Windows::Forms::Label());
			this->txtR19 = (gcnew System::Windows::Forms::TextBox());
			this->label29 = (gcnew System::Windows::Forms::Label());
			this->txtR18 = (gcnew System::Windows::Forms::TextBox());
			this->label30 = (gcnew System::Windows::Forms::Label());
			this->txtR17 = (gcnew System::Windows::Forms::TextBox());
			this->label31 = (gcnew System::Windows::Forms::Label());
			this->txtR16 = (gcnew System::Windows::Forms::TextBox());
			this->label32 = (gcnew System::Windows::Forms::Label());
			this->txtR15 = (gcnew System::Windows::Forms::TextBox());
			this->label9 = (gcnew System::Windows::Forms::Label());
			this->txtR14 = (gcnew System::Windows::Forms::TextBox());
			this->label10 = (gcnew System::Windows::Forms::Label());
			this->txtR13 = (gcnew System::Windows::Forms::TextBox());
			this->label11 = (gcnew System::Windows::Forms::Label());
			this->txtR12 = (gcnew System::Windows::Forms::TextBox());
			this->label12 = (gcnew System::Windows::Forms::Label());
			this->txtR11 = (gcnew System::Windows::Forms::TextBox());
			this->label13 = (gcnew System::Windows::Forms::Label());
			this->txtR10 = (gcnew System::Windows::Forms::TextBox());
			this->label14 = (gcnew System::Windows::Forms::Label());
			this->txtR9 = (gcnew System::Windows::Forms::TextBox());
			this->label15 = (gcnew System::Windows::Forms::Label());
			this->txtR8 = (gcnew System::Windows::Forms::TextBox());
			this->label16 = (gcnew System::Windows::Forms::Label());
			this->txtR7 = (gcnew System::Windows::Forms::TextBox());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->txtR6 = (gcnew System::Windows::Forms::TextBox());
			this->label6 = (gcnew System::Windows::Forms::Label());
			this->txtR5 = (gcnew System::Windows::Forms::TextBox());
			this->label7 = (gcnew System::Windows::Forms::Label());
			this->txtR4 = (gcnew System::Windows::Forms::TextBox());
			this->label8 = (gcnew System::Windows::Forms::Label());
			this->txtR3 = (gcnew System::Windows::Forms::TextBox());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->txtR2 = (gcnew System::Windows::Forms::TextBox());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->txtR1 = (gcnew System::Windows::Forms::TextBox());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->txtR0 = (gcnew System::Windows::Forms::TextBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->tabPage2 = (gcnew System::Windows::Forms::TabPage());
			this->txtTick = (gcnew System::Windows::Forms::TextBox());
			this->label118 = (gcnew System::Windows::Forms::Label());
			this->txtLC = (gcnew System::Windows::Forms::TextBox());
			this->label117 = (gcnew System::Windows::Forms::Label());
			this->label116 = (gcnew System::Windows::Forms::Label());
			this->txtDBSTAT = (gcnew System::Windows::Forms::TextBox());
			this->label115 = (gcnew System::Windows::Forms::Label());
			this->txtDBCTRL = (gcnew System::Windows::Forms::TextBox());
			this->label114 = (gcnew System::Windows::Forms::Label());
			this->txtDBAD3 = (gcnew System::Windows::Forms::TextBox());
			this->label113 = (gcnew System::Windows::Forms::Label());
			this->txtDBAD2 = (gcnew System::Windows::Forms::TextBox());
			this->label112 = (gcnew System::Windows::Forms::Label());
			this->txtDBAD1 = (gcnew System::Windows::Forms::TextBox());
			this->label111 = (gcnew System::Windows::Forms::Label());
			this->txtDBAD0 = (gcnew System::Windows::Forms::TextBox());
			this->label110 = (gcnew System::Windows::Forms::Label());
			this->label109 = (gcnew System::Windows::Forms::Label());
			this->label108 = (gcnew System::Windows::Forms::Label());
			this->label107 = (gcnew System::Windows::Forms::Label());
			this->label106 = (gcnew System::Windows::Forms::Label());
			this->label105 = (gcnew System::Windows::Forms::Label());
			this->txtCsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtCs = (gcnew System::Windows::Forms::TextBox());
			this->label104 = (gcnew System::Windows::Forms::Label());
			this->txtSsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtSs = (gcnew System::Windows::Forms::TextBox());
			this->label103 = (gcnew System::Windows::Forms::Label());
			this->txtHsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtHs = (gcnew System::Windows::Forms::TextBox());
			this->label102 = (gcnew System::Windows::Forms::Label());
			this->txtGsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtGs = (gcnew System::Windows::Forms::TextBox());
			this->label101 = (gcnew System::Windows::Forms::Label());
			this->txtFsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtFs = (gcnew System::Windows::Forms::TextBox());
			this->label100 = (gcnew System::Windows::Forms::Label());
			this->txtEsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtEs = (gcnew System::Windows::Forms::TextBox());
			this->label99 = (gcnew System::Windows::Forms::Label());
			this->txtDsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtDs = (gcnew System::Windows::Forms::TextBox());
			this->label98 = (gcnew System::Windows::Forms::Label());
			this->txtZsLmt = (gcnew System::Windows::Forms::TextBox());
			this->txtZs = (gcnew System::Windows::Forms::TextBox());
			this->label97 = (gcnew System::Windows::Forms::Label());
			this->txtCa15 = (gcnew System::Windows::Forms::TextBox());
			this->label96 = (gcnew System::Windows::Forms::Label());
			this->txtCa14 = (gcnew System::Windows::Forms::TextBox());
			this->label95 = (gcnew System::Windows::Forms::Label());
			this->txtCa13 = (gcnew System::Windows::Forms::TextBox());
			this->label94 = (gcnew System::Windows::Forms::Label());
			this->txtCa12 = (gcnew System::Windows::Forms::TextBox());
			this->label93 = (gcnew System::Windows::Forms::Label());
			this->txtCa11 = (gcnew System::Windows::Forms::TextBox());
			this->label92 = (gcnew System::Windows::Forms::Label());
			this->txtCa10 = (gcnew System::Windows::Forms::TextBox());
			this->label91 = (gcnew System::Windows::Forms::Label());
			this->txtCa9 = (gcnew System::Windows::Forms::TextBox());
			this->label90 = (gcnew System::Windows::Forms::Label());
			this->txtCa8 = (gcnew System::Windows::Forms::TextBox());
			this->label89 = (gcnew System::Windows::Forms::Label());
			this->txtCa7 = (gcnew System::Windows::Forms::TextBox());
			this->label88 = (gcnew System::Windows::Forms::Label());
			this->txtCa6 = (gcnew System::Windows::Forms::TextBox());
			this->label87 = (gcnew System::Windows::Forms::Label());
			this->txtCa5 = (gcnew System::Windows::Forms::TextBox());
			this->label86 = (gcnew System::Windows::Forms::Label());
			this->txtCa4 = (gcnew System::Windows::Forms::TextBox());
			this->label85 = (gcnew System::Windows::Forms::Label());
			this->txtCa3 = (gcnew System::Windows::Forms::TextBox());
			this->label84 = (gcnew System::Windows::Forms::Label());
			this->txtCa2 = (gcnew System::Windows::Forms::TextBox());
			this->label83 = (gcnew System::Windows::Forms::Label());
			this->txtCa1 = (gcnew System::Windows::Forms::TextBox());
			this->label82 = (gcnew System::Windows::Forms::Label());
			this->textBox16 = (gcnew System::Windows::Forms::TextBox());
			this->label81 = (gcnew System::Windows::Forms::Label());
			this->txtP14 = (gcnew System::Windows::Forms::TextBox());
			this->label80 = (gcnew System::Windows::Forms::Label());
			this->txtP13 = (gcnew System::Windows::Forms::TextBox());
			this->label79 = (gcnew System::Windows::Forms::Label());
			this->txtP12 = (gcnew System::Windows::Forms::TextBox());
			this->label78 = (gcnew System::Windows::Forms::Label());
			this->txtP11 = (gcnew System::Windows::Forms::TextBox());
			this->label77 = (gcnew System::Windows::Forms::Label());
			this->txtP15 = (gcnew System::Windows::Forms::TextBox());
			this->label76 = (gcnew System::Windows::Forms::Label());
			this->txtP10 = (gcnew System::Windows::Forms::TextBox());
			this->label75 = (gcnew System::Windows::Forms::Label());
			this->txtP9 = (gcnew System::Windows::Forms::TextBox());
			this->label74 = (gcnew System::Windows::Forms::Label());
			this->txtP8 = (gcnew System::Windows::Forms::TextBox());
			this->label73 = (gcnew System::Windows::Forms::Label());
			this->txtP7 = (gcnew System::Windows::Forms::TextBox());
			this->label72 = (gcnew System::Windows::Forms::Label());
			this->txtP6 = (gcnew System::Windows::Forms::TextBox());
			this->label71 = (gcnew System::Windows::Forms::Label());
			this->txtP5 = (gcnew System::Windows::Forms::TextBox());
			this->label70 = (gcnew System::Windows::Forms::Label());
			this->txtP4 = (gcnew System::Windows::Forms::TextBox());
			this->label69 = (gcnew System::Windows::Forms::Label());
			this->txtP3 = (gcnew System::Windows::Forms::TextBox());
			this->label68 = (gcnew System::Windows::Forms::Label());
			this->txtP2 = (gcnew System::Windows::Forms::TextBox());
			this->label67 = (gcnew System::Windows::Forms::Label());
			this->txtP1 = (gcnew System::Windows::Forms::TextBox());
			this->label66 = (gcnew System::Windows::Forms::Label());
			this->txtP0 = (gcnew System::Windows::Forms::TextBox());
			this->label65 = (gcnew System::Windows::Forms::Label());
			this->toolTipC12 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipC14 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipC1 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipR31 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipR30 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipR29 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipR28 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipC8 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->toolTipR0 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->btnUpdate = (gcnew System::Windows::Forms::Button());
			this->toolTipC10 = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->tabControl1->SuspendLayout();
			this->tabPage1->SuspendLayout();
			this->tabPage2->SuspendLayout();
			this->SuspendLayout();
			// 
			// tabControl1
			// 
			this->tabControl1->Controls->Add(this->tabPage1);
			this->tabControl1->Controls->Add(this->tabPage2);
			this->tabControl1->Location = System::Drawing::Point(12, 42);
			this->tabControl1->Name = L"tabControl1";
			this->tabControl1->SelectedIndex = 0;
			this->tabControl1->Size = System::Drawing::Size(743, 483);
			this->tabControl1->TabIndex = 0;
			// 
			// tabPage1
			// 
			this->tabPage1->Controls->Add(this->txtR63);
			this->tabPage1->Controls->Add(this->label49);
			this->tabPage1->Controls->Add(this->txtR62);
			this->tabPage1->Controls->Add(this->label50);
			this->tabPage1->Controls->Add(this->txtR61);
			this->tabPage1->Controls->Add(this->label51);
			this->tabPage1->Controls->Add(this->txtR60);
			this->tabPage1->Controls->Add(this->label52);
			this->tabPage1->Controls->Add(this->txtR59);
			this->tabPage1->Controls->Add(this->label53);
			this->tabPage1->Controls->Add(this->txtR58);
			this->tabPage1->Controls->Add(this->label54);
			this->tabPage1->Controls->Add(this->txtR57);
			this->tabPage1->Controls->Add(this->label55);
			this->tabPage1->Controls->Add(this->txtR56);
			this->tabPage1->Controls->Add(this->label56);
			this->tabPage1->Controls->Add(this->txtR55);
			this->tabPage1->Controls->Add(this->label57);
			this->tabPage1->Controls->Add(this->txtR54);
			this->tabPage1->Controls->Add(this->label58);
			this->tabPage1->Controls->Add(this->txtR53);
			this->tabPage1->Controls->Add(this->label59);
			this->tabPage1->Controls->Add(this->txtR52);
			this->tabPage1->Controls->Add(this->label60);
			this->tabPage1->Controls->Add(this->txtR51);
			this->tabPage1->Controls->Add(this->label61);
			this->tabPage1->Controls->Add(this->txtR50);
			this->tabPage1->Controls->Add(this->label62);
			this->tabPage1->Controls->Add(this->txtR49);
			this->tabPage1->Controls->Add(this->label63);
			this->tabPage1->Controls->Add(this->txtR48);
			this->tabPage1->Controls->Add(this->label64);
			this->tabPage1->Controls->Add(this->txtR47);
			this->tabPage1->Controls->Add(this->label33);
			this->tabPage1->Controls->Add(this->txtR46);
			this->tabPage1->Controls->Add(this->label34);
			this->tabPage1->Controls->Add(this->txtR45);
			this->tabPage1->Controls->Add(this->label35);
			this->tabPage1->Controls->Add(this->txtR44);
			this->tabPage1->Controls->Add(this->label36);
			this->tabPage1->Controls->Add(this->txtR43);
			this->tabPage1->Controls->Add(this->label37);
			this->tabPage1->Controls->Add(this->txtR42);
			this->tabPage1->Controls->Add(this->label38);
			this->tabPage1->Controls->Add(this->txtR41);
			this->tabPage1->Controls->Add(this->label39);
			this->tabPage1->Controls->Add(this->txtR40);
			this->tabPage1->Controls->Add(this->label40);
			this->tabPage1->Controls->Add(this->txtR39);
			this->tabPage1->Controls->Add(this->label41);
			this->tabPage1->Controls->Add(this->txtR38);
			this->tabPage1->Controls->Add(this->label42);
			this->tabPage1->Controls->Add(this->txtR37);
			this->tabPage1->Controls->Add(this->label43);
			this->tabPage1->Controls->Add(this->txtR36);
			this->tabPage1->Controls->Add(this->label44);
			this->tabPage1->Controls->Add(this->txtR35);
			this->tabPage1->Controls->Add(this->label45);
			this->tabPage1->Controls->Add(this->txtR34);
			this->tabPage1->Controls->Add(this->label46);
			this->tabPage1->Controls->Add(this->txtR33);
			this->tabPage1->Controls->Add(this->label47);
			this->tabPage1->Controls->Add(this->txtR32);
			this->tabPage1->Controls->Add(this->label48);
			this->tabPage1->Controls->Add(this->txtR31);
			this->tabPage1->Controls->Add(this->label17);
			this->tabPage1->Controls->Add(this->txtR30);
			this->tabPage1->Controls->Add(this->label18);
			this->tabPage1->Controls->Add(this->txtR29);
			this->tabPage1->Controls->Add(this->label19);
			this->tabPage1->Controls->Add(this->txtR28);
			this->tabPage1->Controls->Add(this->label20);
			this->tabPage1->Controls->Add(this->txtR27);
			this->tabPage1->Controls->Add(this->label21);
			this->tabPage1->Controls->Add(this->txtR26);
			this->tabPage1->Controls->Add(this->label22);
			this->tabPage1->Controls->Add(this->txtR25);
			this->tabPage1->Controls->Add(this->label23);
			this->tabPage1->Controls->Add(this->txtR24);
			this->tabPage1->Controls->Add(this->label24);
			this->tabPage1->Controls->Add(this->txtR23);
			this->tabPage1->Controls->Add(this->label25);
			this->tabPage1->Controls->Add(this->txtR22);
			this->tabPage1->Controls->Add(this->label26);
			this->tabPage1->Controls->Add(this->txtR21);
			this->tabPage1->Controls->Add(this->label27);
			this->tabPage1->Controls->Add(this->txtR20);
			this->tabPage1->Controls->Add(this->label28);
			this->tabPage1->Controls->Add(this->txtR19);
			this->tabPage1->Controls->Add(this->label29);
			this->tabPage1->Controls->Add(this->txtR18);
			this->tabPage1->Controls->Add(this->label30);
			this->tabPage1->Controls->Add(this->txtR17);
			this->tabPage1->Controls->Add(this->label31);
			this->tabPage1->Controls->Add(this->txtR16);
			this->tabPage1->Controls->Add(this->label32);
			this->tabPage1->Controls->Add(this->txtR15);
			this->tabPage1->Controls->Add(this->label9);
			this->tabPage1->Controls->Add(this->txtR14);
			this->tabPage1->Controls->Add(this->label10);
			this->tabPage1->Controls->Add(this->txtR13);
			this->tabPage1->Controls->Add(this->label11);
			this->tabPage1->Controls->Add(this->txtR12);
			this->tabPage1->Controls->Add(this->label12);
			this->tabPage1->Controls->Add(this->txtR11);
			this->tabPage1->Controls->Add(this->label13);
			this->tabPage1->Controls->Add(this->txtR10);
			this->tabPage1->Controls->Add(this->label14);
			this->tabPage1->Controls->Add(this->txtR9);
			this->tabPage1->Controls->Add(this->label15);
			this->tabPage1->Controls->Add(this->txtR8);
			this->tabPage1->Controls->Add(this->label16);
			this->tabPage1->Controls->Add(this->txtR7);
			this->tabPage1->Controls->Add(this->label5);
			this->tabPage1->Controls->Add(this->txtR6);
			this->tabPage1->Controls->Add(this->label6);
			this->tabPage1->Controls->Add(this->txtR5);
			this->tabPage1->Controls->Add(this->label7);
			this->tabPage1->Controls->Add(this->txtR4);
			this->tabPage1->Controls->Add(this->label8);
			this->tabPage1->Controls->Add(this->txtR3);
			this->tabPage1->Controls->Add(this->label3);
			this->tabPage1->Controls->Add(this->txtR2);
			this->tabPage1->Controls->Add(this->label4);
			this->tabPage1->Controls->Add(this->txtR1);
			this->tabPage1->Controls->Add(this->label2);
			this->tabPage1->Controls->Add(this->txtR0);
			this->tabPage1->Controls->Add(this->label1);
			this->tabPage1->Location = System::Drawing::Point(4, 22);
			this->tabPage1->Name = L"tabPage1";
			this->tabPage1->Padding = System::Windows::Forms::Padding(3);
			this->tabPage1->Size = System::Drawing::Size(735, 457);
			this->tabPage1->TabIndex = 0;
			this->tabPage1->Text = L"General Registers";
			this->tabPage1->UseVisualStyleBackColor = true;
			// 
			// txtR63
			// 
			this->txtR63->Location = System::Drawing::Point(539, 403);
			this->txtR63->Name = L"txtR63";
			this->txtR63->Size = System::Drawing::Size(121, 20);
			this->txtR63->TabIndex = 127;
			this->txtR63->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label49
			// 
			this->label49->AutoSize = true;
			this->label49->Location = System::Drawing::Point(512, 406);
			this->label49->Name = L"label49";
			this->label49->Size = System::Drawing::Size(27, 13);
			this->label49->TabIndex = 126;
			this->label49->Text = L"R63";
			// 
			// txtR62
			// 
			this->txtR62->Location = System::Drawing::Point(539, 377);
			this->txtR62->Name = L"txtR62";
			this->txtR62->Size = System::Drawing::Size(121, 20);
			this->txtR62->TabIndex = 125;
			this->txtR62->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label50
			// 
			this->label50->AutoSize = true;
			this->label50->Location = System::Drawing::Point(512, 380);
			this->label50->Name = L"label50";
			this->label50->Size = System::Drawing::Size(27, 13);
			this->label50->TabIndex = 124;
			this->label50->Text = L"R62";
			// 
			// txtR61
			// 
			this->txtR61->Location = System::Drawing::Point(539, 351);
			this->txtR61->Name = L"txtR61";
			this->txtR61->Size = System::Drawing::Size(121, 20);
			this->txtR61->TabIndex = 123;
			this->txtR61->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label51
			// 
			this->label51->AutoSize = true;
			this->label51->Location = System::Drawing::Point(512, 354);
			this->label51->Name = L"label51";
			this->label51->Size = System::Drawing::Size(27, 13);
			this->label51->TabIndex = 122;
			this->label51->Text = L"R61";
			// 
			// txtR60
			// 
			this->txtR60->Location = System::Drawing::Point(539, 325);
			this->txtR60->Name = L"txtR60";
			this->txtR60->Size = System::Drawing::Size(121, 20);
			this->txtR60->TabIndex = 121;
			this->txtR60->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label52
			// 
			this->label52->AutoSize = true;
			this->label52->Location = System::Drawing::Point(512, 328);
			this->label52->Name = L"label52";
			this->label52->Size = System::Drawing::Size(27, 13);
			this->label52->TabIndex = 120;
			this->label52->Text = L"R60";
			// 
			// txtR59
			// 
			this->txtR59->Location = System::Drawing::Point(539, 299);
			this->txtR59->Name = L"txtR59";
			this->txtR59->Size = System::Drawing::Size(121, 20);
			this->txtR59->TabIndex = 119;
			this->txtR59->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label53
			// 
			this->label53->AutoSize = true;
			this->label53->Location = System::Drawing::Point(512, 302);
			this->label53->Name = L"label53";
			this->label53->Size = System::Drawing::Size(27, 13);
			this->label53->TabIndex = 118;
			this->label53->Text = L"R59";
			// 
			// txtR58
			// 
			this->txtR58->Location = System::Drawing::Point(539, 273);
			this->txtR58->Name = L"txtR58";
			this->txtR58->Size = System::Drawing::Size(121, 20);
			this->txtR58->TabIndex = 117;
			this->txtR58->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label54
			// 
			this->label54->AutoSize = true;
			this->label54->Location = System::Drawing::Point(512, 276);
			this->label54->Name = L"label54";
			this->label54->Size = System::Drawing::Size(27, 13);
			this->label54->TabIndex = 116;
			this->label54->Text = L"R58";
			// 
			// txtR57
			// 
			this->txtR57->Location = System::Drawing::Point(539, 247);
			this->txtR57->Name = L"txtR57";
			this->txtR57->Size = System::Drawing::Size(121, 20);
			this->txtR57->TabIndex = 115;
			this->txtR57->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label55
			// 
			this->label55->AutoSize = true;
			this->label55->Location = System::Drawing::Point(512, 250);
			this->label55->Name = L"label55";
			this->label55->Size = System::Drawing::Size(27, 13);
			this->label55->TabIndex = 114;
			this->label55->Text = L"R57";
			// 
			// txtR56
			// 
			this->txtR56->Location = System::Drawing::Point(539, 221);
			this->txtR56->Name = L"txtR56";
			this->txtR56->Size = System::Drawing::Size(121, 20);
			this->txtR56->TabIndex = 113;
			this->txtR56->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label56
			// 
			this->label56->AutoSize = true;
			this->label56->Location = System::Drawing::Point(512, 224);
			this->label56->Name = L"label56";
			this->label56->Size = System::Drawing::Size(27, 13);
			this->label56->TabIndex = 112;
			this->label56->Text = L"R56";
			// 
			// txtR55
			// 
			this->txtR55->Location = System::Drawing::Point(539, 195);
			this->txtR55->Name = L"txtR55";
			this->txtR55->Size = System::Drawing::Size(121, 20);
			this->txtR55->TabIndex = 111;
			this->txtR55->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label57
			// 
			this->label57->AutoSize = true;
			this->label57->Location = System::Drawing::Point(512, 198);
			this->label57->Name = L"label57";
			this->label57->Size = System::Drawing::Size(27, 13);
			this->label57->TabIndex = 110;
			this->label57->Text = L"R55";
			// 
			// txtR54
			// 
			this->txtR54->Location = System::Drawing::Point(539, 169);
			this->txtR54->Name = L"txtR54";
			this->txtR54->Size = System::Drawing::Size(121, 20);
			this->txtR54->TabIndex = 109;
			this->txtR54->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label58
			// 
			this->label58->AutoSize = true;
			this->label58->Location = System::Drawing::Point(512, 172);
			this->label58->Name = L"label58";
			this->label58->Size = System::Drawing::Size(27, 13);
			this->label58->TabIndex = 108;
			this->label58->Text = L"R54";
			// 
			// txtR53
			// 
			this->txtR53->Location = System::Drawing::Point(539, 143);
			this->txtR53->Name = L"txtR53";
			this->txtR53->Size = System::Drawing::Size(121, 20);
			this->txtR53->TabIndex = 107;
			this->txtR53->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label59
			// 
			this->label59->AutoSize = true;
			this->label59->Location = System::Drawing::Point(512, 146);
			this->label59->Name = L"label59";
			this->label59->Size = System::Drawing::Size(27, 13);
			this->label59->TabIndex = 106;
			this->label59->Text = L"R53";
			// 
			// txtR52
			// 
			this->txtR52->Location = System::Drawing::Point(539, 117);
			this->txtR52->Name = L"txtR52";
			this->txtR52->Size = System::Drawing::Size(121, 20);
			this->txtR52->TabIndex = 105;
			this->txtR52->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label60
			// 
			this->label60->AutoSize = true;
			this->label60->Location = System::Drawing::Point(512, 120);
			this->label60->Name = L"label60";
			this->label60->Size = System::Drawing::Size(27, 13);
			this->label60->TabIndex = 104;
			this->label60->Text = L"R52";
			// 
			// txtR51
			// 
			this->txtR51->Location = System::Drawing::Point(539, 91);
			this->txtR51->Name = L"txtR51";
			this->txtR51->Size = System::Drawing::Size(121, 20);
			this->txtR51->TabIndex = 103;
			this->txtR51->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label61
			// 
			this->label61->AutoSize = true;
			this->label61->Location = System::Drawing::Point(512, 94);
			this->label61->Name = L"label61";
			this->label61->Size = System::Drawing::Size(27, 13);
			this->label61->TabIndex = 102;
			this->label61->Text = L"R51";
			// 
			// txtR50
			// 
			this->txtR50->Location = System::Drawing::Point(539, 65);
			this->txtR50->Name = L"txtR50";
			this->txtR50->Size = System::Drawing::Size(121, 20);
			this->txtR50->TabIndex = 101;
			this->txtR50->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label62
			// 
			this->label62->AutoSize = true;
			this->label62->Location = System::Drawing::Point(512, 68);
			this->label62->Name = L"label62";
			this->label62->Size = System::Drawing::Size(27, 13);
			this->label62->TabIndex = 100;
			this->label62->Text = L"R50";
			// 
			// txtR49
			// 
			this->txtR49->Location = System::Drawing::Point(539, 39);
			this->txtR49->Name = L"txtR49";
			this->txtR49->Size = System::Drawing::Size(121, 20);
			this->txtR49->TabIndex = 99;
			this->txtR49->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label63
			// 
			this->label63->AutoSize = true;
			this->label63->Location = System::Drawing::Point(512, 42);
			this->label63->Name = L"label63";
			this->label63->Size = System::Drawing::Size(27, 13);
			this->label63->TabIndex = 98;
			this->label63->Text = L"R49";
			// 
			// txtR48
			// 
			this->txtR48->Location = System::Drawing::Point(539, 13);
			this->txtR48->Name = L"txtR48";
			this->txtR48->Size = System::Drawing::Size(121, 20);
			this->txtR48->TabIndex = 97;
			this->txtR48->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label64
			// 
			this->label64->AutoSize = true;
			this->label64->Location = System::Drawing::Point(512, 16);
			this->label64->Name = L"label64";
			this->label64->Size = System::Drawing::Size(27, 13);
			this->label64->TabIndex = 96;
			this->label64->Text = L"R48";
			// 
			// txtR47
			// 
			this->txtR47->Location = System::Drawing::Point(377, 403);
			this->txtR47->Name = L"txtR47";
			this->txtR47->Size = System::Drawing::Size(121, 20);
			this->txtR47->TabIndex = 95;
			this->txtR47->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label33
			// 
			this->label33->AutoSize = true;
			this->label33->Location = System::Drawing::Point(350, 406);
			this->label33->Name = L"label33";
			this->label33->Size = System::Drawing::Size(27, 13);
			this->label33->TabIndex = 94;
			this->label33->Text = L"R47";
			// 
			// txtR46
			// 
			this->txtR46->Location = System::Drawing::Point(377, 377);
			this->txtR46->Name = L"txtR46";
			this->txtR46->Size = System::Drawing::Size(121, 20);
			this->txtR46->TabIndex = 93;
			this->txtR46->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label34
			// 
			this->label34->AutoSize = true;
			this->label34->Location = System::Drawing::Point(350, 380);
			this->label34->Name = L"label34";
			this->label34->Size = System::Drawing::Size(27, 13);
			this->label34->TabIndex = 92;
			this->label34->Text = L"R46";
			// 
			// txtR45
			// 
			this->txtR45->Location = System::Drawing::Point(377, 351);
			this->txtR45->Name = L"txtR45";
			this->txtR45->Size = System::Drawing::Size(121, 20);
			this->txtR45->TabIndex = 91;
			this->txtR45->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label35
			// 
			this->label35->AutoSize = true;
			this->label35->Location = System::Drawing::Point(350, 354);
			this->label35->Name = L"label35";
			this->label35->Size = System::Drawing::Size(27, 13);
			this->label35->TabIndex = 90;
			this->label35->Text = L"R45";
			// 
			// txtR44
			// 
			this->txtR44->Location = System::Drawing::Point(377, 325);
			this->txtR44->Name = L"txtR44";
			this->txtR44->Size = System::Drawing::Size(121, 20);
			this->txtR44->TabIndex = 89;
			this->txtR44->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label36
			// 
			this->label36->AutoSize = true;
			this->label36->Location = System::Drawing::Point(350, 328);
			this->label36->Name = L"label36";
			this->label36->Size = System::Drawing::Size(27, 13);
			this->label36->TabIndex = 88;
			this->label36->Text = L"R44";
			// 
			// txtR43
			// 
			this->txtR43->Location = System::Drawing::Point(377, 299);
			this->txtR43->Name = L"txtR43";
			this->txtR43->Size = System::Drawing::Size(121, 20);
			this->txtR43->TabIndex = 87;
			this->txtR43->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label37
			// 
			this->label37->AutoSize = true;
			this->label37->Location = System::Drawing::Point(350, 302);
			this->label37->Name = L"label37";
			this->label37->Size = System::Drawing::Size(27, 13);
			this->label37->TabIndex = 86;
			this->label37->Text = L"R43";
			// 
			// txtR42
			// 
			this->txtR42->Location = System::Drawing::Point(377, 273);
			this->txtR42->Name = L"txtR42";
			this->txtR42->Size = System::Drawing::Size(121, 20);
			this->txtR42->TabIndex = 85;
			this->txtR42->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label38
			// 
			this->label38->AutoSize = true;
			this->label38->Location = System::Drawing::Point(350, 276);
			this->label38->Name = L"label38";
			this->label38->Size = System::Drawing::Size(27, 13);
			this->label38->TabIndex = 84;
			this->label38->Text = L"R42";
			// 
			// txtR41
			// 
			this->txtR41->Location = System::Drawing::Point(377, 247);
			this->txtR41->Name = L"txtR41";
			this->txtR41->Size = System::Drawing::Size(121, 20);
			this->txtR41->TabIndex = 83;
			this->txtR41->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label39
			// 
			this->label39->AutoSize = true;
			this->label39->Location = System::Drawing::Point(350, 250);
			this->label39->Name = L"label39";
			this->label39->Size = System::Drawing::Size(27, 13);
			this->label39->TabIndex = 82;
			this->label39->Text = L"R41";
			// 
			// txtR40
			// 
			this->txtR40->Location = System::Drawing::Point(377, 221);
			this->txtR40->Name = L"txtR40";
			this->txtR40->Size = System::Drawing::Size(121, 20);
			this->txtR40->TabIndex = 81;
			this->txtR40->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label40
			// 
			this->label40->AutoSize = true;
			this->label40->Location = System::Drawing::Point(350, 224);
			this->label40->Name = L"label40";
			this->label40->Size = System::Drawing::Size(27, 13);
			this->label40->TabIndex = 80;
			this->label40->Text = L"R40";
			// 
			// txtR39
			// 
			this->txtR39->Location = System::Drawing::Point(377, 195);
			this->txtR39->Name = L"txtR39";
			this->txtR39->Size = System::Drawing::Size(121, 20);
			this->txtR39->TabIndex = 79;
			this->txtR39->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label41
			// 
			this->label41->AutoSize = true;
			this->label41->Location = System::Drawing::Point(350, 198);
			this->label41->Name = L"label41";
			this->label41->Size = System::Drawing::Size(27, 13);
			this->label41->TabIndex = 78;
			this->label41->Text = L"R39";
			// 
			// txtR38
			// 
			this->txtR38->Location = System::Drawing::Point(377, 169);
			this->txtR38->Name = L"txtR38";
			this->txtR38->Size = System::Drawing::Size(121, 20);
			this->txtR38->TabIndex = 77;
			this->txtR38->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label42
			// 
			this->label42->AutoSize = true;
			this->label42->Location = System::Drawing::Point(350, 172);
			this->label42->Name = L"label42";
			this->label42->Size = System::Drawing::Size(27, 13);
			this->label42->TabIndex = 76;
			this->label42->Text = L"R38";
			// 
			// txtR37
			// 
			this->txtR37->Location = System::Drawing::Point(377, 143);
			this->txtR37->Name = L"txtR37";
			this->txtR37->Size = System::Drawing::Size(121, 20);
			this->txtR37->TabIndex = 75;
			this->txtR37->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label43
			// 
			this->label43->AutoSize = true;
			this->label43->Location = System::Drawing::Point(350, 146);
			this->label43->Name = L"label43";
			this->label43->Size = System::Drawing::Size(27, 13);
			this->label43->TabIndex = 74;
			this->label43->Text = L"R37";
			// 
			// txtR36
			// 
			this->txtR36->Location = System::Drawing::Point(377, 117);
			this->txtR36->Name = L"txtR36";
			this->txtR36->Size = System::Drawing::Size(121, 20);
			this->txtR36->TabIndex = 73;
			this->txtR36->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label44
			// 
			this->label44->AutoSize = true;
			this->label44->Location = System::Drawing::Point(350, 120);
			this->label44->Name = L"label44";
			this->label44->Size = System::Drawing::Size(27, 13);
			this->label44->TabIndex = 72;
			this->label44->Text = L"R36";
			// 
			// txtR35
			// 
			this->txtR35->Location = System::Drawing::Point(377, 91);
			this->txtR35->Name = L"txtR35";
			this->txtR35->Size = System::Drawing::Size(121, 20);
			this->txtR35->TabIndex = 71;
			this->txtR35->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label45
			// 
			this->label45->AutoSize = true;
			this->label45->Location = System::Drawing::Point(350, 94);
			this->label45->Name = L"label45";
			this->label45->Size = System::Drawing::Size(27, 13);
			this->label45->TabIndex = 70;
			this->label45->Text = L"R35";
			// 
			// txtR34
			// 
			this->txtR34->Location = System::Drawing::Point(377, 65);
			this->txtR34->Name = L"txtR34";
			this->txtR34->Size = System::Drawing::Size(121, 20);
			this->txtR34->TabIndex = 69;
			this->txtR34->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label46
			// 
			this->label46->AutoSize = true;
			this->label46->Location = System::Drawing::Point(350, 68);
			this->label46->Name = L"label46";
			this->label46->Size = System::Drawing::Size(27, 13);
			this->label46->TabIndex = 68;
			this->label46->Text = L"R34";
			// 
			// txtR33
			// 
			this->txtR33->Location = System::Drawing::Point(377, 39);
			this->txtR33->Name = L"txtR33";
			this->txtR33->Size = System::Drawing::Size(121, 20);
			this->txtR33->TabIndex = 67;
			this->txtR33->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label47
			// 
			this->label47->AutoSize = true;
			this->label47->Location = System::Drawing::Point(350, 42);
			this->label47->Name = L"label47";
			this->label47->Size = System::Drawing::Size(27, 13);
			this->label47->TabIndex = 66;
			this->label47->Text = L"R33";
			// 
			// txtR32
			// 
			this->txtR32->Location = System::Drawing::Point(377, 13);
			this->txtR32->Name = L"txtR32";
			this->txtR32->Size = System::Drawing::Size(121, 20);
			this->txtR32->TabIndex = 65;
			this->txtR32->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label48
			// 
			this->label48->AutoSize = true;
			this->label48->Location = System::Drawing::Point(350, 16);
			this->label48->Name = L"label48";
			this->label48->Size = System::Drawing::Size(27, 13);
			this->label48->TabIndex = 64;
			this->label48->Text = L"R32";
			// 
			// txtR31
			// 
			this->txtR31->Location = System::Drawing::Point(215, 403);
			this->txtR31->Name = L"txtR31";
			this->txtR31->Size = System::Drawing::Size(121, 20);
			this->txtR31->TabIndex = 63;
			this->txtR31->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label17
			// 
			this->label17->AutoSize = true;
			this->label17->Location = System::Drawing::Point(162, 406);
			this->label17->Name = L"label17";
			this->label17->Size = System::Drawing::Size(53, 13);
			this->label17->TabIndex = 62;
			this->label17->Text = L"TR / R31";
			// 
			// txtR30
			// 
			this->txtR30->Location = System::Drawing::Point(215, 377);
			this->txtR30->Name = L"txtR30";
			this->txtR30->Size = System::Drawing::Size(121, 20);
			this->txtR30->TabIndex = 61;
			this->txtR30->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label18
			// 
			this->label18->AutoSize = true;
			this->label18->Location = System::Drawing::Point(155, 380);
			this->label18->Name = L"label18";
			this->label18->Size = System::Drawing::Size(60, 13);
			this->label18->TabIndex = 60;
			this->label18->Text = L"DSP / R30";
			// 
			// txtR29
			// 
			this->txtR29->Location = System::Drawing::Point(215, 351);
			this->txtR29->Name = L"txtR29";
			this->txtR29->Size = System::Drawing::Size(121, 20);
			this->txtR29->TabIndex = 59;
			this->txtR29->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label19
			// 
			this->label19->AutoSize = true;
			this->label19->Location = System::Drawing::Point(157, 354);
			this->label19->Name = L"label19";
			this->label19->Size = System::Drawing::Size(59, 13);
			this->label19->TabIndex = 58;
			this->label19->Text = L"ESP / R29";
			// 
			// txtR28
			// 
			this->txtR28->Location = System::Drawing::Point(215, 325);
			this->txtR28->Name = L"txtR28";
			this->txtR28->Size = System::Drawing::Size(121, 20);
			this->txtR28->TabIndex = 57;
			this->txtR28->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label20
			// 
			this->label20->AutoSize = true;
			this->label20->Location = System::Drawing::Point(160, 328);
			this->label20->Name = L"label20";
			this->label20->Size = System::Drawing::Size(55, 13);
			this->label20->TabIndex = 56;
			this->label20->Text = L"ISP / R28";
			// 
			// txtR27
			// 
			this->txtR27->Location = System::Drawing::Point(215, 299);
			this->txtR27->Name = L"txtR27";
			this->txtR27->Size = System::Drawing::Size(121, 20);
			this->txtR27->TabIndex = 55;
			this->txtR27->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label21
			// 
			this->label21->AutoSize = true;
			this->label21->Location = System::Drawing::Point(163, 302);
			this->label21->Name = L"label21";
			this->label21->Size = System::Drawing::Size(52, 13);
			this->label21->TabIndex = 54;
			this->label21->Text = L"SP / R27";
			// 
			// txtR26
			// 
			this->txtR26->Location = System::Drawing::Point(215, 273);
			this->txtR26->Name = L"txtR26";
			this->txtR26->Size = System::Drawing::Size(121, 20);
			this->txtR26->TabIndex = 53;
			this->txtR26->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label22
			// 
			this->label22->AutoSize = true;
			this->label22->Location = System::Drawing::Point(163, 276);
			this->label22->Name = L"label22";
			this->label22->Size = System::Drawing::Size(52, 13);
			this->label22->TabIndex = 52;
			this->label22->Text = L"BP / R26";
			// 
			// txtR25
			// 
			this->txtR25->Location = System::Drawing::Point(215, 247);
			this->txtR25->Name = L"txtR25";
			this->txtR25->Size = System::Drawing::Size(121, 20);
			this->txtR25->TabIndex = 51;
			this->txtR25->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label23
			// 
			this->label23->AutoSize = true;
			this->label23->Location = System::Drawing::Point(163, 250);
			this->label23->Name = L"label23";
			this->label23->Size = System::Drawing::Size(53, 13);
			this->label23->TabIndex = 50;
			this->label23->Text = L"GP / R25";
			// 
			// txtR24
			// 
			this->txtR24->Location = System::Drawing::Point(215, 221);
			this->txtR24->Name = L"txtR24";
			this->txtR24->Size = System::Drawing::Size(121, 20);
			this->txtR24->TabIndex = 49;
			this->txtR24->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label24
			// 
			this->label24->AutoSize = true;
			this->label24->Location = System::Drawing::Point(188, 224);
			this->label24->Name = L"label24";
			this->label24->Size = System::Drawing::Size(27, 13);
			this->label24->TabIndex = 48;
			this->label24->Text = L"R24";
			// 
			// txtR23
			// 
			this->txtR23->Location = System::Drawing::Point(215, 195);
			this->txtR23->Name = L"txtR23";
			this->txtR23->Size = System::Drawing::Size(121, 20);
			this->txtR23->TabIndex = 47;
			this->txtR23->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label25
			// 
			this->label25->AutoSize = true;
			this->label25->Location = System::Drawing::Point(188, 198);
			this->label25->Name = L"label25";
			this->label25->Size = System::Drawing::Size(27, 13);
			this->label25->TabIndex = 46;
			this->label25->Text = L"R23";
			// 
			// txtR22
			// 
			this->txtR22->Location = System::Drawing::Point(215, 169);
			this->txtR22->Name = L"txtR22";
			this->txtR22->Size = System::Drawing::Size(121, 20);
			this->txtR22->TabIndex = 45;
			this->txtR22->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label26
			// 
			this->label26->AutoSize = true;
			this->label26->Location = System::Drawing::Point(188, 172);
			this->label26->Name = L"label26";
			this->label26->Size = System::Drawing::Size(27, 13);
			this->label26->TabIndex = 44;
			this->label26->Text = L"R22";
			// 
			// txtR21
			// 
			this->txtR21->Location = System::Drawing::Point(215, 143);
			this->txtR21->Name = L"txtR21";
			this->txtR21->Size = System::Drawing::Size(121, 20);
			this->txtR21->TabIndex = 43;
			this->txtR21->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label27
			// 
			this->label27->AutoSize = true;
			this->label27->Location = System::Drawing::Point(188, 146);
			this->label27->Name = L"label27";
			this->label27->Size = System::Drawing::Size(27, 13);
			this->label27->TabIndex = 42;
			this->label27->Text = L"R21";
			// 
			// txtR20
			// 
			this->txtR20->Location = System::Drawing::Point(215, 117);
			this->txtR20->Name = L"txtR20";
			this->txtR20->Size = System::Drawing::Size(121, 20);
			this->txtR20->TabIndex = 41;
			this->txtR20->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label28
			// 
			this->label28->AutoSize = true;
			this->label28->Location = System::Drawing::Point(188, 120);
			this->label28->Name = L"label28";
			this->label28->Size = System::Drawing::Size(27, 13);
			this->label28->TabIndex = 40;
			this->label28->Text = L"R20";
			// 
			// txtR19
			// 
			this->txtR19->Location = System::Drawing::Point(215, 91);
			this->txtR19->Name = L"txtR19";
			this->txtR19->Size = System::Drawing::Size(121, 20);
			this->txtR19->TabIndex = 39;
			this->txtR19->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label29
			// 
			this->label29->AutoSize = true;
			this->label29->Location = System::Drawing::Point(188, 94);
			this->label29->Name = L"label29";
			this->label29->Size = System::Drawing::Size(27, 13);
			this->label29->TabIndex = 38;
			this->label29->Text = L"R19";
			// 
			// txtR18
			// 
			this->txtR18->Location = System::Drawing::Point(215, 65);
			this->txtR18->Name = L"txtR18";
			this->txtR18->Size = System::Drawing::Size(121, 20);
			this->txtR18->TabIndex = 37;
			this->txtR18->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label30
			// 
			this->label30->AutoSize = true;
			this->label30->Location = System::Drawing::Point(188, 68);
			this->label30->Name = L"label30";
			this->label30->Size = System::Drawing::Size(27, 13);
			this->label30->TabIndex = 36;
			this->label30->Text = L"R18";
			// 
			// txtR17
			// 
			this->txtR17->Location = System::Drawing::Point(215, 39);
			this->txtR17->Name = L"txtR17";
			this->txtR17->Size = System::Drawing::Size(121, 20);
			this->txtR17->TabIndex = 35;
			this->txtR17->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label31
			// 
			this->label31->AutoSize = true;
			this->label31->Location = System::Drawing::Point(188, 42);
			this->label31->Name = L"label31";
			this->label31->Size = System::Drawing::Size(27, 13);
			this->label31->TabIndex = 34;
			this->label31->Text = L"R17";
			// 
			// txtR16
			// 
			this->txtR16->Location = System::Drawing::Point(215, 13);
			this->txtR16->Name = L"txtR16";
			this->txtR16->Size = System::Drawing::Size(121, 20);
			this->txtR16->TabIndex = 33;
			this->txtR16->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label32
			// 
			this->label32->AutoSize = true;
			this->label32->Location = System::Drawing::Point(188, 16);
			this->label32->Name = L"label32";
			this->label32->Size = System::Drawing::Size(27, 13);
			this->label32->TabIndex = 32;
			this->label32->Text = L"R16";
			// 
			// txtR15
			// 
			this->txtR15->Location = System::Drawing::Point(33, 403);
			this->txtR15->Name = L"txtR15";
			this->txtR15->Size = System::Drawing::Size(121, 20);
			this->txtR15->TabIndex = 31;
			this->txtR15->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label9
			// 
			this->label9->AutoSize = true;
			this->label9->Location = System::Drawing::Point(6, 406);
			this->label9->Name = L"label9";
			this->label9->Size = System::Drawing::Size(27, 13);
			this->label9->TabIndex = 30;
			this->label9->Text = L"R15";
			// 
			// txtR14
			// 
			this->txtR14->Location = System::Drawing::Point(33, 377);
			this->txtR14->Name = L"txtR14";
			this->txtR14->Size = System::Drawing::Size(121, 20);
			this->txtR14->TabIndex = 29;
			this->txtR14->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label10
			// 
			this->label10->AutoSize = true;
			this->label10->Location = System::Drawing::Point(6, 380);
			this->label10->Name = L"label10";
			this->label10->Size = System::Drawing::Size(27, 13);
			this->label10->TabIndex = 28;
			this->label10->Text = L"R14";
			// 
			// txtR13
			// 
			this->txtR13->Location = System::Drawing::Point(33, 351);
			this->txtR13->Name = L"txtR13";
			this->txtR13->Size = System::Drawing::Size(121, 20);
			this->txtR13->TabIndex = 27;
			this->txtR13->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label11
			// 
			this->label11->AutoSize = true;
			this->label11->Location = System::Drawing::Point(6, 354);
			this->label11->Name = L"label11";
			this->label11->Size = System::Drawing::Size(27, 13);
			this->label11->TabIndex = 26;
			this->label11->Text = L"R13";
			// 
			// txtR12
			// 
			this->txtR12->Location = System::Drawing::Point(33, 325);
			this->txtR12->Name = L"txtR12";
			this->txtR12->Size = System::Drawing::Size(121, 20);
			this->txtR12->TabIndex = 25;
			this->txtR12->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label12
			// 
			this->label12->AutoSize = true;
			this->label12->Location = System::Drawing::Point(6, 328);
			this->label12->Name = L"label12";
			this->label12->Size = System::Drawing::Size(27, 13);
			this->label12->TabIndex = 24;
			this->label12->Text = L"R12";
			// 
			// txtR11
			// 
			this->txtR11->Location = System::Drawing::Point(33, 299);
			this->txtR11->Name = L"txtR11";
			this->txtR11->Size = System::Drawing::Size(121, 20);
			this->txtR11->TabIndex = 23;
			this->txtR11->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label13
			// 
			this->label13->AutoSize = true;
			this->label13->Location = System::Drawing::Point(6, 302);
			this->label13->Name = L"label13";
			this->label13->Size = System::Drawing::Size(27, 13);
			this->label13->TabIndex = 22;
			this->label13->Text = L"R11";
			// 
			// txtR10
			// 
			this->txtR10->Location = System::Drawing::Point(33, 273);
			this->txtR10->Name = L"txtR10";
			this->txtR10->Size = System::Drawing::Size(121, 20);
			this->txtR10->TabIndex = 21;
			this->txtR10->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label14
			// 
			this->label14->AutoSize = true;
			this->label14->Location = System::Drawing::Point(6, 276);
			this->label14->Name = L"label14";
			this->label14->Size = System::Drawing::Size(27, 13);
			this->label14->TabIndex = 20;
			this->label14->Text = L"R10";
			// 
			// txtR9
			// 
			this->txtR9->Location = System::Drawing::Point(33, 247);
			this->txtR9->Name = L"txtR9";
			this->txtR9->Size = System::Drawing::Size(121, 20);
			this->txtR9->TabIndex = 19;
			this->txtR9->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label15
			// 
			this->label15->AutoSize = true;
			this->label15->Location = System::Drawing::Point(6, 250);
			this->label15->Name = L"label15";
			this->label15->Size = System::Drawing::Size(21, 13);
			this->label15->TabIndex = 18;
			this->label15->Text = L"R9";
			// 
			// txtR8
			// 
			this->txtR8->Location = System::Drawing::Point(33, 221);
			this->txtR8->Name = L"txtR8";
			this->txtR8->Size = System::Drawing::Size(121, 20);
			this->txtR8->TabIndex = 17;
			this->txtR8->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label16
			// 
			this->label16->AutoSize = true;
			this->label16->Location = System::Drawing::Point(6, 224);
			this->label16->Name = L"label16";
			this->label16->Size = System::Drawing::Size(21, 13);
			this->label16->TabIndex = 16;
			this->label16->Text = L"R8";
			// 
			// txtR7
			// 
			this->txtR7->Location = System::Drawing::Point(33, 195);
			this->txtR7->Name = L"txtR7";
			this->txtR7->Size = System::Drawing::Size(121, 20);
			this->txtR7->TabIndex = 15;
			this->txtR7->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Location = System::Drawing::Point(6, 198);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(21, 13);
			this->label5->TabIndex = 14;
			this->label5->Text = L"R7";
			// 
			// txtR6
			// 
			this->txtR6->Location = System::Drawing::Point(33, 169);
			this->txtR6->Name = L"txtR6";
			this->txtR6->Size = System::Drawing::Size(121, 20);
			this->txtR6->TabIndex = 13;
			this->txtR6->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label6
			// 
			this->label6->AutoSize = true;
			this->label6->Location = System::Drawing::Point(6, 172);
			this->label6->Name = L"label6";
			this->label6->Size = System::Drawing::Size(21, 13);
			this->label6->TabIndex = 12;
			this->label6->Text = L"R6";
			// 
			// txtR5
			// 
			this->txtR5->Location = System::Drawing::Point(33, 143);
			this->txtR5->Name = L"txtR5";
			this->txtR5->Size = System::Drawing::Size(121, 20);
			this->txtR5->TabIndex = 11;
			this->txtR5->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label7
			// 
			this->label7->AutoSize = true;
			this->label7->Location = System::Drawing::Point(6, 146);
			this->label7->Name = L"label7";
			this->label7->Size = System::Drawing::Size(21, 13);
			this->label7->TabIndex = 10;
			this->label7->Text = L"R5";
			// 
			// txtR4
			// 
			this->txtR4->Location = System::Drawing::Point(33, 117);
			this->txtR4->Name = L"txtR4";
			this->txtR4->Size = System::Drawing::Size(121, 20);
			this->txtR4->TabIndex = 9;
			this->txtR4->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label8
			// 
			this->label8->AutoSize = true;
			this->label8->Location = System::Drawing::Point(6, 120);
			this->label8->Name = L"label8";
			this->label8->Size = System::Drawing::Size(21, 13);
			this->label8->TabIndex = 8;
			this->label8->Text = L"R4";
			// 
			// txtR3
			// 
			this->txtR3->Location = System::Drawing::Point(33, 91);
			this->txtR3->Name = L"txtR3";
			this->txtR3->Size = System::Drawing::Size(121, 20);
			this->txtR3->TabIndex = 7;
			this->txtR3->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(6, 94);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(21, 13);
			this->label3->TabIndex = 6;
			this->label3->Text = L"R3";
			// 
			// txtR2
			// 
			this->txtR2->Location = System::Drawing::Point(33, 65);
			this->txtR2->Name = L"txtR2";
			this->txtR2->Size = System::Drawing::Size(121, 20);
			this->txtR2->TabIndex = 5;
			this->txtR2->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(6, 68);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(21, 13);
			this->label4->TabIndex = 4;
			this->label4->Text = L"R2";
			// 
			// txtR1
			// 
			this->txtR1->Location = System::Drawing::Point(33, 39);
			this->txtR1->Name = L"txtR1";
			this->txtR1->Size = System::Drawing::Size(121, 20);
			this->txtR1->TabIndex = 3;
			this->txtR1->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			this->txtR1->TextChanged += gcnew System::EventHandler(this, &frmRegisters::textBox2_TextChanged);
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(6, 42);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(21, 13);
			this->label2->TabIndex = 2;
			this->label2->Text = L"R1";
			this->label2->Click += gcnew System::EventHandler(this, &frmRegisters::label2_Click);
			// 
			// txtR0
			// 
			this->txtR0->Location = System::Drawing::Point(33, 13);
			this->txtR0->Name = L"txtR0";
			this->txtR0->ReadOnly = true;
			this->txtR0->Size = System::Drawing::Size(121, 20);
			this->txtR0->TabIndex = 1;
			this->txtR0->Text = L"0";
			this->txtR0->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(6, 16);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(21, 13);
			this->label1->TabIndex = 0;
			this->label1->Text = L"R0";
			// 
			// tabPage2
			// 
			this->tabPage2->Controls->Add(this->txtTick);
			this->tabPage2->Controls->Add(this->label118);
			this->tabPage2->Controls->Add(this->txtLC);
			this->tabPage2->Controls->Add(this->label117);
			this->tabPage2->Controls->Add(this->label116);
			this->tabPage2->Controls->Add(this->txtDBSTAT);
			this->tabPage2->Controls->Add(this->label115);
			this->tabPage2->Controls->Add(this->txtDBCTRL);
			this->tabPage2->Controls->Add(this->label114);
			this->tabPage2->Controls->Add(this->txtDBAD3);
			this->tabPage2->Controls->Add(this->label113);
			this->tabPage2->Controls->Add(this->txtDBAD2);
			this->tabPage2->Controls->Add(this->label112);
			this->tabPage2->Controls->Add(this->txtDBAD1);
			this->tabPage2->Controls->Add(this->label111);
			this->tabPage2->Controls->Add(this->txtDBAD0);
			this->tabPage2->Controls->Add(this->label110);
			this->tabPage2->Controls->Add(this->label109);
			this->tabPage2->Controls->Add(this->label108);
			this->tabPage2->Controls->Add(this->label107);
			this->tabPage2->Controls->Add(this->label106);
			this->tabPage2->Controls->Add(this->label105);
			this->tabPage2->Controls->Add(this->txtCsLmt);
			this->tabPage2->Controls->Add(this->txtCs);
			this->tabPage2->Controls->Add(this->label104);
			this->tabPage2->Controls->Add(this->txtSsLmt);
			this->tabPage2->Controls->Add(this->txtSs);
			this->tabPage2->Controls->Add(this->label103);
			this->tabPage2->Controls->Add(this->txtHsLmt);
			this->tabPage2->Controls->Add(this->txtHs);
			this->tabPage2->Controls->Add(this->label102);
			this->tabPage2->Controls->Add(this->txtGsLmt);
			this->tabPage2->Controls->Add(this->txtGs);
			this->tabPage2->Controls->Add(this->label101);
			this->tabPage2->Controls->Add(this->txtFsLmt);
			this->tabPage2->Controls->Add(this->txtFs);
			this->tabPage2->Controls->Add(this->label100);
			this->tabPage2->Controls->Add(this->txtEsLmt);
			this->tabPage2->Controls->Add(this->txtEs);
			this->tabPage2->Controls->Add(this->label99);
			this->tabPage2->Controls->Add(this->txtDsLmt);
			this->tabPage2->Controls->Add(this->txtDs);
			this->tabPage2->Controls->Add(this->label98);
			this->tabPage2->Controls->Add(this->txtZsLmt);
			this->tabPage2->Controls->Add(this->txtZs);
			this->tabPage2->Controls->Add(this->label97);
			this->tabPage2->Controls->Add(this->txtCa15);
			this->tabPage2->Controls->Add(this->label96);
			this->tabPage2->Controls->Add(this->txtCa14);
			this->tabPage2->Controls->Add(this->label95);
			this->tabPage2->Controls->Add(this->txtCa13);
			this->tabPage2->Controls->Add(this->label94);
			this->tabPage2->Controls->Add(this->txtCa12);
			this->tabPage2->Controls->Add(this->label93);
			this->tabPage2->Controls->Add(this->txtCa11);
			this->tabPage2->Controls->Add(this->label92);
			this->tabPage2->Controls->Add(this->txtCa10);
			this->tabPage2->Controls->Add(this->label91);
			this->tabPage2->Controls->Add(this->txtCa9);
			this->tabPage2->Controls->Add(this->label90);
			this->tabPage2->Controls->Add(this->txtCa8);
			this->tabPage2->Controls->Add(this->label89);
			this->tabPage2->Controls->Add(this->txtCa7);
			this->tabPage2->Controls->Add(this->label88);
			this->tabPage2->Controls->Add(this->txtCa6);
			this->tabPage2->Controls->Add(this->label87);
			this->tabPage2->Controls->Add(this->txtCa5);
			this->tabPage2->Controls->Add(this->label86);
			this->tabPage2->Controls->Add(this->txtCa4);
			this->tabPage2->Controls->Add(this->label85);
			this->tabPage2->Controls->Add(this->txtCa3);
			this->tabPage2->Controls->Add(this->label84);
			this->tabPage2->Controls->Add(this->txtCa2);
			this->tabPage2->Controls->Add(this->label83);
			this->tabPage2->Controls->Add(this->txtCa1);
			this->tabPage2->Controls->Add(this->label82);
			this->tabPage2->Controls->Add(this->textBox16);
			this->tabPage2->Controls->Add(this->label81);
			this->tabPage2->Controls->Add(this->txtP14);
			this->tabPage2->Controls->Add(this->label80);
			this->tabPage2->Controls->Add(this->txtP13);
			this->tabPage2->Controls->Add(this->label79);
			this->tabPage2->Controls->Add(this->txtP12);
			this->tabPage2->Controls->Add(this->label78);
			this->tabPage2->Controls->Add(this->txtP11);
			this->tabPage2->Controls->Add(this->label77);
			this->tabPage2->Controls->Add(this->txtP15);
			this->tabPage2->Controls->Add(this->label76);
			this->tabPage2->Controls->Add(this->txtP10);
			this->tabPage2->Controls->Add(this->label75);
			this->tabPage2->Controls->Add(this->txtP9);
			this->tabPage2->Controls->Add(this->label74);
			this->tabPage2->Controls->Add(this->txtP8);
			this->tabPage2->Controls->Add(this->label73);
			this->tabPage2->Controls->Add(this->txtP7);
			this->tabPage2->Controls->Add(this->label72);
			this->tabPage2->Controls->Add(this->txtP6);
			this->tabPage2->Controls->Add(this->label71);
			this->tabPage2->Controls->Add(this->txtP5);
			this->tabPage2->Controls->Add(this->label70);
			this->tabPage2->Controls->Add(this->txtP4);
			this->tabPage2->Controls->Add(this->label69);
			this->tabPage2->Controls->Add(this->txtP3);
			this->tabPage2->Controls->Add(this->label68);
			this->tabPage2->Controls->Add(this->txtP2);
			this->tabPage2->Controls->Add(this->label67);
			this->tabPage2->Controls->Add(this->txtP1);
			this->tabPage2->Controls->Add(this->label66);
			this->tabPage2->Controls->Add(this->txtP0);
			this->tabPage2->Controls->Add(this->label65);
			this->tabPage2->Location = System::Drawing::Point(4, 22);
			this->tabPage2->Name = L"tabPage2";
			this->tabPage2->Padding = System::Windows::Forms::Padding(3);
			this->tabPage2->Size = System::Drawing::Size(735, 457);
			this->tabPage2->TabIndex = 1;
			this->tabPage2->Text = L"Other";
			this->tabPage2->UseVisualStyleBackColor = true;
			// 
			// txtTick
			// 
			this->txtTick->Location = System::Drawing::Point(512, 322);
			this->txtTick->Name = L"txtTick";
			this->txtTick->ReadOnly = true;
			this->txtTick->Size = System::Drawing::Size(118, 20);
			this->txtTick->TabIndex = 107;
			this->txtTick->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label118
			// 
			this->label118->AutoSize = true;
			this->label118->Location = System::Drawing::Point(476, 325);
			this->label118->Name = L"label118";
			this->label118->Size = System::Drawing::Size(31, 13);
			this->label118->TabIndex = 106;
			this->label118->Text = L"TICK";
			// 
			// txtLC
			// 
			this->txtLC->Location = System::Drawing::Point(512, 296);
			this->txtLC->Name = L"txtLC";
			this->txtLC->Size = System::Drawing::Size(118, 20);
			this->txtLC->TabIndex = 105;
			this->txtLC->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label117
			// 
			this->label117->AutoSize = true;
			this->label117->Location = System::Drawing::Point(476, 299);
			this->label117->Name = L"label117";
			this->label117->Size = System::Drawing::Size(20, 13);
			this->label117->TabIndex = 104;
			this->label117->Text = L"LC";
			// 
			// label116
			// 
			this->label116->AutoSize = true;
			this->label116->Location = System::Drawing::Point(350, 277);
			this->label116->Name = L"label116";
			this->label116->Size = System::Drawing::Size(86, 13);
			this->label116->TabIndex = 103;
			this->label116->Text = L"Debug Registers";
			// 
			// txtDBSTAT
			// 
			this->txtDBSTAT->Location = System::Drawing::Point(353, 426);
			this->txtDBSTAT->Name = L"txtDBSTAT";
			this->txtDBSTAT->Size = System::Drawing::Size(118, 20);
			this->txtDBSTAT->TabIndex = 102;
			this->txtDBSTAT->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label115
			// 
			this->label115->AutoSize = true;
			this->label115->Location = System::Drawing::Point(304, 429);
			this->label115->Name = L"label115";
			this->label115->Size = System::Drawing::Size(50, 13);
			this->label115->TabIndex = 101;
			this->label115->Text = L"DBSTAT";
			// 
			// txtDBCTRL
			// 
			this->txtDBCTRL->Location = System::Drawing::Point(353, 400);
			this->txtDBCTRL->Name = L"txtDBCTRL";
			this->txtDBCTRL->Size = System::Drawing::Size(118, 20);
			this->txtDBCTRL->TabIndex = 100;
			this->txtDBCTRL->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label114
			// 
			this->label114->AutoSize = true;
			this->label114->Location = System::Drawing::Point(304, 403);
			this->label114->Name = L"label114";
			this->label114->Size = System::Drawing::Size(50, 13);
			this->label114->TabIndex = 99;
			this->label114->Text = L"DBCTRL";
			// 
			// txtDBAD3
			// 
			this->txtDBAD3->Location = System::Drawing::Point(353, 374);
			this->txtDBAD3->Name = L"txtDBAD3";
			this->txtDBAD3->Size = System::Drawing::Size(118, 20);
			this->txtDBAD3->TabIndex = 98;
			this->txtDBAD3->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label113
			// 
			this->label113->AutoSize = true;
			this->label113->Location = System::Drawing::Point(304, 377);
			this->label113->Name = L"label113";
			this->label113->Size = System::Drawing::Size(43, 13);
			this->label113->TabIndex = 97;
			this->label113->Text = L"DBAD3";
			// 
			// txtDBAD2
			// 
			this->txtDBAD2->Location = System::Drawing::Point(353, 348);
			this->txtDBAD2->Name = L"txtDBAD2";
			this->txtDBAD2->Size = System::Drawing::Size(118, 20);
			this->txtDBAD2->TabIndex = 96;
			this->txtDBAD2->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label112
			// 
			this->label112->AutoSize = true;
			this->label112->Location = System::Drawing::Point(304, 351);
			this->label112->Name = L"label112";
			this->label112->Size = System::Drawing::Size(43, 13);
			this->label112->TabIndex = 95;
			this->label112->Text = L"DBAD2";
			// 
			// txtDBAD1
			// 
			this->txtDBAD1->Location = System::Drawing::Point(353, 322);
			this->txtDBAD1->Name = L"txtDBAD1";
			this->txtDBAD1->Size = System::Drawing::Size(118, 20);
			this->txtDBAD1->TabIndex = 94;
			this->txtDBAD1->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label111
			// 
			this->label111->AutoSize = true;
			this->label111->Location = System::Drawing::Point(304, 325);
			this->label111->Name = L"label111";
			this->label111->Size = System::Drawing::Size(43, 13);
			this->label111->TabIndex = 93;
			this->label111->Text = L"DBAD1";
			// 
			// txtDBAD0
			// 
			this->txtDBAD0->Location = System::Drawing::Point(353, 296);
			this->txtDBAD0->Name = L"txtDBAD0";
			this->txtDBAD0->Size = System::Drawing::Size(118, 20);
			this->txtDBAD0->TabIndex = 92;
			this->txtDBAD0->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label110
			// 
			this->label110->AutoSize = true;
			this->label110->Location = System::Drawing::Point(304, 299);
			this->label110->Name = L"label110";
			this->label110->Size = System::Drawing::Size(43, 13);
			this->label110->TabIndex = 91;
			this->label110->Text = L"DBAD0";
			// 
			// label109
			// 
			this->label109->AutoSize = true;
			this->label109->Location = System::Drawing::Point(10, 14);
			this->label109->Name = L"label109";
			this->label109->Size = System::Drawing::Size(99, 13);
			this->label109->TabIndex = 90;
			this->label109->Text = L"Predicate Registers";
			// 
			// label108
			// 
			this->label108->AutoSize = true;
			this->label108->Location = System::Drawing::Point(157, 14);
			this->label108->Name = L"label108";
			this->label108->Size = System::Drawing::Size(120, 13);
			this->label108->TabIndex = 89;
			this->label108->Text = L"Code Address Registers";
			// 
			// label107
			// 
			this->label107->AutoSize = true;
			this->label107->Location = System::Drawing::Point(328, 14);
			this->label107->Name = L"label107";
			this->label107->Size = System::Drawing::Size(96, 13);
			this->label107->TabIndex = 88;
			this->label107->Text = L"Segment Registers";
			// 
			// label106
			// 
			this->label106->AutoSize = true;
			this->label106->Location = System::Drawing::Point(468, 36);
			this->label106->Name = L"label106";
			this->label106->Size = System::Drawing::Size(28, 13);
			this->label106->TabIndex = 87;
			this->label106->Text = L"Limit";
			// 
			// label105
			// 
			this->label105->AutoSize = true;
			this->label105->Location = System::Drawing::Point(328, 36);
			this->label105->Name = L"label105";
			this->label105->Size = System::Drawing::Size(31, 13);
			this->label105->TabIndex = 86;
			this->label105->Text = L"Base";
			// 
			// txtCsLmt
			// 
			this->txtCsLmt->Location = System::Drawing::Point(471, 244);
			this->txtCsLmt->Name = L"txtCsLmt";
			this->txtCsLmt->Size = System::Drawing::Size(118, 20);
			this->txtCsLmt->TabIndex = 85;
			this->txtCsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtCs
			// 
			this->txtCs->Location = System::Drawing::Point(331, 244);
			this->txtCs->Name = L"txtCs";
			this->txtCs->Size = System::Drawing::Size(118, 20);
			this->txtCs->TabIndex = 84;
			this->txtCs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label104
			// 
			this->label104->AutoSize = true;
			this->label104->Location = System::Drawing::Point(304, 247);
			this->label104->Name = L"label104";
			this->label104->Size = System::Drawing::Size(21, 13);
			this->label104->TabIndex = 83;
			this->label104->Text = L"CS";
			// 
			// txtSsLmt
			// 
			this->txtSsLmt->Location = System::Drawing::Point(471, 218);
			this->txtSsLmt->Name = L"txtSsLmt";
			this->txtSsLmt->Size = System::Drawing::Size(118, 20);
			this->txtSsLmt->TabIndex = 82;
			this->txtSsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtSs
			// 
			this->txtSs->Location = System::Drawing::Point(331, 218);
			this->txtSs->Name = L"txtSs";
			this->txtSs->Size = System::Drawing::Size(118, 20);
			this->txtSs->TabIndex = 81;
			this->txtSs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label103
			// 
			this->label103->AutoSize = true;
			this->label103->Location = System::Drawing::Point(304, 221);
			this->label103->Name = L"label103";
			this->label103->Size = System::Drawing::Size(21, 13);
			this->label103->TabIndex = 80;
			this->label103->Text = L"SS";
			// 
			// txtHsLmt
			// 
			this->txtHsLmt->Location = System::Drawing::Point(471, 192);
			this->txtHsLmt->Name = L"txtHsLmt";
			this->txtHsLmt->Size = System::Drawing::Size(118, 20);
			this->txtHsLmt->TabIndex = 79;
			this->txtHsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtHs
			// 
			this->txtHs->Location = System::Drawing::Point(331, 192);
			this->txtHs->Name = L"txtHs";
			this->txtHs->Size = System::Drawing::Size(118, 20);
			this->txtHs->TabIndex = 78;
			this->txtHs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label102
			// 
			this->label102->AutoSize = true;
			this->label102->Location = System::Drawing::Point(304, 195);
			this->label102->Name = L"label102";
			this->label102->Size = System::Drawing::Size(22, 13);
			this->label102->TabIndex = 77;
			this->label102->Text = L"HS";
			// 
			// txtGsLmt
			// 
			this->txtGsLmt->Location = System::Drawing::Point(471, 166);
			this->txtGsLmt->Name = L"txtGsLmt";
			this->txtGsLmt->Size = System::Drawing::Size(118, 20);
			this->txtGsLmt->TabIndex = 76;
			this->txtGsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtGs
			// 
			this->txtGs->Location = System::Drawing::Point(331, 166);
			this->txtGs->Name = L"txtGs";
			this->txtGs->Size = System::Drawing::Size(118, 20);
			this->txtGs->TabIndex = 75;
			this->txtGs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label101
			// 
			this->label101->AutoSize = true;
			this->label101->Location = System::Drawing::Point(304, 169);
			this->label101->Name = L"label101";
			this->label101->Size = System::Drawing::Size(22, 13);
			this->label101->TabIndex = 74;
			this->label101->Text = L"GS";
			// 
			// txtFsLmt
			// 
			this->txtFsLmt->Location = System::Drawing::Point(471, 140);
			this->txtFsLmt->Name = L"txtFsLmt";
			this->txtFsLmt->Size = System::Drawing::Size(118, 20);
			this->txtFsLmt->TabIndex = 73;
			this->txtFsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtFs
			// 
			this->txtFs->Location = System::Drawing::Point(331, 140);
			this->txtFs->Name = L"txtFs";
			this->txtFs->Size = System::Drawing::Size(118, 20);
			this->txtFs->TabIndex = 72;
			this->txtFs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label100
			// 
			this->label100->AutoSize = true;
			this->label100->Location = System::Drawing::Point(304, 143);
			this->label100->Name = L"label100";
			this->label100->Size = System::Drawing::Size(20, 13);
			this->label100->TabIndex = 71;
			this->label100->Text = L"FS";
			// 
			// txtEsLmt
			// 
			this->txtEsLmt->Location = System::Drawing::Point(471, 114);
			this->txtEsLmt->Name = L"txtEsLmt";
			this->txtEsLmt->Size = System::Drawing::Size(118, 20);
			this->txtEsLmt->TabIndex = 70;
			this->txtEsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtEs
			// 
			this->txtEs->Location = System::Drawing::Point(331, 114);
			this->txtEs->Name = L"txtEs";
			this->txtEs->Size = System::Drawing::Size(118, 20);
			this->txtEs->TabIndex = 69;
			this->txtEs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label99
			// 
			this->label99->AutoSize = true;
			this->label99->Location = System::Drawing::Point(304, 117);
			this->label99->Name = L"label99";
			this->label99->Size = System::Drawing::Size(21, 13);
			this->label99->TabIndex = 68;
			this->label99->Text = L"ES";
			// 
			// txtDsLmt
			// 
			this->txtDsLmt->Location = System::Drawing::Point(471, 88);
			this->txtDsLmt->Name = L"txtDsLmt";
			this->txtDsLmt->Size = System::Drawing::Size(118, 20);
			this->txtDsLmt->TabIndex = 67;
			this->txtDsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtDs
			// 
			this->txtDs->Location = System::Drawing::Point(331, 88);
			this->txtDs->Name = L"txtDs";
			this->txtDs->Size = System::Drawing::Size(118, 20);
			this->txtDs->TabIndex = 66;
			this->txtDs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label98
			// 
			this->label98->AutoSize = true;
			this->label98->Location = System::Drawing::Point(304, 91);
			this->label98->Name = L"label98";
			this->label98->Size = System::Drawing::Size(22, 13);
			this->label98->TabIndex = 65;
			this->label98->Text = L"DS";
			// 
			// txtZsLmt
			// 
			this->txtZsLmt->Location = System::Drawing::Point(471, 62);
			this->txtZsLmt->Name = L"txtZsLmt";
			this->txtZsLmt->Size = System::Drawing::Size(118, 20);
			this->txtZsLmt->TabIndex = 64;
			this->txtZsLmt->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtZs
			// 
			this->txtZs->Location = System::Drawing::Point(331, 62);
			this->txtZs->Name = L"txtZs";
			this->txtZs->Size = System::Drawing::Size(118, 20);
			this->txtZs->TabIndex = 63;
			this->txtZs->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label97
			// 
			this->label97->AutoSize = true;
			this->label97->Location = System::Drawing::Point(304, 65);
			this->label97->Name = L"label97";
			this->label97->Size = System::Drawing::Size(21, 13);
			this->label97->TabIndex = 62;
			this->label97->Text = L"ZS";
			// 
			// txtCa15
			// 
			this->txtCa15->Location = System::Drawing::Point(160, 426);
			this->txtCa15->Name = L"txtCa15";
			this->txtCa15->ReadOnly = true;
			this->txtCa15->Size = System::Drawing::Size(118, 20);
			this->txtCa15->TabIndex = 61;
			this->txtCa15->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label96
			// 
			this->label96->AutoSize = true;
			this->label96->Location = System::Drawing::Point(109, 429);
			this->label96->Name = L"label96";
			this->label96->Size = System::Drawing::Size(45, 13);
			this->label96->TabIndex = 60;
			this->label96->Text = L"C15/PC";
			// 
			// txtCa14
			// 
			this->txtCa14->Location = System::Drawing::Point(160, 400);
			this->txtCa14->Name = L"txtCa14";
			this->txtCa14->Size = System::Drawing::Size(118, 20);
			this->txtCa14->TabIndex = 59;
			this->txtCa14->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label95
			// 
			this->label95->AutoSize = true;
			this->label95->Location = System::Drawing::Point(109, 403);
			this->label95->Name = L"label95";
			this->label95->Size = System::Drawing::Size(48, 13);
			this->label95->TabIndex = 58;
			this->label95->Text = L"C14/IPC";
			// 
			// txtCa13
			// 
			this->txtCa13->Location = System::Drawing::Point(160, 374);
			this->txtCa13->Name = L"txtCa13";
			this->txtCa13->Size = System::Drawing::Size(118, 20);
			this->txtCa13->TabIndex = 57;
			this->txtCa13->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label94
			// 
			this->label94->AutoSize = true;
			this->label94->Location = System::Drawing::Point(109, 377);
			this->label94->Name = L"label94";
			this->label94->Size = System::Drawing::Size(52, 13);
			this->label94->TabIndex = 56;
			this->label94->Text = L"C13/EPC";
			// 
			// txtCa12
			// 
			this->txtCa12->Location = System::Drawing::Point(160, 348);
			this->txtCa12->Name = L"txtCa12";
			this->txtCa12->Size = System::Drawing::Size(118, 20);
			this->txtCa12->TabIndex = 55;
			this->txtCa12->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label93
			// 
			this->label93->AutoSize = true;
			this->label93->Location = System::Drawing::Point(109, 351);
			this->label93->Name = L"label93";
			this->label93->Size = System::Drawing::Size(26, 13);
			this->label93->TabIndex = 54;
			this->label93->Text = L"C12";
			// 
			// txtCa11
			// 
			this->txtCa11->Location = System::Drawing::Point(160, 322);
			this->txtCa11->Name = L"txtCa11";
			this->txtCa11->Size = System::Drawing::Size(118, 20);
			this->txtCa11->TabIndex = 53;
			this->txtCa11->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label92
			// 
			this->label92->AutoSize = true;
			this->label92->Location = System::Drawing::Point(109, 325);
			this->label92->Name = L"label92";
			this->label92->Size = System::Drawing::Size(53, 13);
			this->label92->TabIndex = 52;
			this->label92->Text = L"C11/DPC";
			// 
			// txtCa10
			// 
			this->txtCa10->Location = System::Drawing::Point(160, 296);
			this->txtCa10->Name = L"txtCa10";
			this->txtCa10->Size = System::Drawing::Size(118, 20);
			this->txtCa10->TabIndex = 51;
			this->txtCa10->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label91
			// 
			this->label91->AutoSize = true;
			this->label91->Location = System::Drawing::Point(109, 299);
			this->label91->Name = L"label91";
			this->label91->Size = System::Drawing::Size(26, 13);
			this->label91->TabIndex = 50;
			this->label91->Text = L"C10";
			// 
			// txtCa9
			// 
			this->txtCa9->Location = System::Drawing::Point(160, 270);
			this->txtCa9->Name = L"txtCa9";
			this->txtCa9->Size = System::Drawing::Size(118, 20);
			this->txtCa9->TabIndex = 49;
			this->txtCa9->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label90
			// 
			this->label90->AutoSize = true;
			this->label90->Location = System::Drawing::Point(109, 273);
			this->label90->Name = L"label90";
			this->label90->Size = System::Drawing::Size(20, 13);
			this->label90->TabIndex = 48;
			this->label90->Text = L"C9";
			// 
			// txtCa8
			// 
			this->txtCa8->Location = System::Drawing::Point(160, 244);
			this->txtCa8->Name = L"txtCa8";
			this->txtCa8->Size = System::Drawing::Size(118, 20);
			this->txtCa8->TabIndex = 47;
			this->txtCa8->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label89
			// 
			this->label89->AutoSize = true;
			this->label89->Location = System::Drawing::Point(109, 247);
			this->label89->Name = L"label89";
			this->label89->Size = System::Drawing::Size(20, 13);
			this->label89->TabIndex = 46;
			this->label89->Text = L"C8";
			// 
			// txtCa7
			// 
			this->txtCa7->Location = System::Drawing::Point(160, 218);
			this->txtCa7->Name = L"txtCa7";
			this->txtCa7->Size = System::Drawing::Size(118, 20);
			this->txtCa7->TabIndex = 45;
			this->txtCa7->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label88
			// 
			this->label88->AutoSize = true;
			this->label88->Location = System::Drawing::Point(109, 221);
			this->label88->Name = L"label88";
			this->label88->Size = System::Drawing::Size(20, 13);
			this->label88->TabIndex = 44;
			this->label88->Text = L"C7";
			// 
			// txtCa6
			// 
			this->txtCa6->Location = System::Drawing::Point(160, 192);
			this->txtCa6->Name = L"txtCa6";
			this->txtCa6->Size = System::Drawing::Size(118, 20);
			this->txtCa6->TabIndex = 43;
			this->txtCa6->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label87
			// 
			this->label87->AutoSize = true;
			this->label87->Location = System::Drawing::Point(109, 195);
			this->label87->Name = L"label87";
			this->label87->Size = System::Drawing::Size(20, 13);
			this->label87->TabIndex = 42;
			this->label87->Text = L"C6";
			// 
			// txtCa5
			// 
			this->txtCa5->Location = System::Drawing::Point(160, 166);
			this->txtCa5->Name = L"txtCa5";
			this->txtCa5->Size = System::Drawing::Size(118, 20);
			this->txtCa5->TabIndex = 41;
			this->txtCa5->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label86
			// 
			this->label86->AutoSize = true;
			this->label86->Location = System::Drawing::Point(109, 169);
			this->label86->Name = L"label86";
			this->label86->Size = System::Drawing::Size(20, 13);
			this->label86->TabIndex = 40;
			this->label86->Text = L"C5";
			// 
			// txtCa4
			// 
			this->txtCa4->Location = System::Drawing::Point(160, 140);
			this->txtCa4->Name = L"txtCa4";
			this->txtCa4->Size = System::Drawing::Size(118, 20);
			this->txtCa4->TabIndex = 39;
			this->txtCa4->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label85
			// 
			this->label85->AutoSize = true;
			this->label85->Location = System::Drawing::Point(109, 143);
			this->label85->Name = L"label85";
			this->label85->Size = System::Drawing::Size(20, 13);
			this->label85->TabIndex = 38;
			this->label85->Text = L"C4";
			// 
			// txtCa3
			// 
			this->txtCa3->Location = System::Drawing::Point(160, 114);
			this->txtCa3->Name = L"txtCa3";
			this->txtCa3->Size = System::Drawing::Size(118, 20);
			this->txtCa3->TabIndex = 37;
			this->txtCa3->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label84
			// 
			this->label84->AutoSize = true;
			this->label84->Location = System::Drawing::Point(109, 117);
			this->label84->Name = L"label84";
			this->label84->Size = System::Drawing::Size(20, 13);
			this->label84->TabIndex = 36;
			this->label84->Text = L"C3";
			// 
			// txtCa2
			// 
			this->txtCa2->Location = System::Drawing::Point(160, 88);
			this->txtCa2->Name = L"txtCa2";
			this->txtCa2->Size = System::Drawing::Size(118, 20);
			this->txtCa2->TabIndex = 35;
			this->txtCa2->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label83
			// 
			this->label83->AutoSize = true;
			this->label83->Location = System::Drawing::Point(109, 91);
			this->label83->Name = L"label83";
			this->label83->Size = System::Drawing::Size(20, 13);
			this->label83->TabIndex = 34;
			this->label83->Text = L"C2";
			// 
			// txtCa1
			// 
			this->txtCa1->Location = System::Drawing::Point(160, 62);
			this->txtCa1->Name = L"txtCa1";
			this->txtCa1->Size = System::Drawing::Size(118, 20);
			this->txtCa1->TabIndex = 33;
			this->txtCa1->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label82
			// 
			this->label82->AutoSize = true;
			this->label82->Location = System::Drawing::Point(109, 65);
			this->label82->Name = L"label82";
			this->label82->Size = System::Drawing::Size(20, 13);
			this->label82->TabIndex = 32;
			this->label82->Text = L"C1";
			// 
			// textBox16
			// 
			this->textBox16->Location = System::Drawing::Point(160, 36);
			this->textBox16->Name = L"textBox16";
			this->textBox16->ReadOnly = true;
			this->textBox16->Size = System::Drawing::Size(118, 20);
			this->textBox16->TabIndex = 31;
			this->textBox16->Text = L"0";
			this->textBox16->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label81
			// 
			this->label81->AutoSize = true;
			this->label81->Location = System::Drawing::Point(109, 39);
			this->label81->Name = L"label81";
			this->label81->Size = System::Drawing::Size(20, 13);
			this->label81->TabIndex = 30;
			this->label81->Text = L"C0";
			// 
			// txtP14
			// 
			this->txtP14->Enabled = false;
			this->txtP14->Location = System::Drawing::Point(36, 400);
			this->txtP14->Name = L"txtP14";
			this->txtP14->Size = System::Drawing::Size(54, 20);
			this->txtP14->TabIndex = 29;
			this->txtP14->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label80
			// 
			this->label80->AutoSize = true;
			this->label80->Location = System::Drawing::Point(10, 403);
			this->label80->Name = L"label80";
			this->label80->Size = System::Drawing::Size(26, 13);
			this->label80->TabIndex = 28;
			this->label80->Text = L"P14";
			// 
			// txtP13
			// 
			this->txtP13->Enabled = false;
			this->txtP13->Location = System::Drawing::Point(36, 374);
			this->txtP13->Name = L"txtP13";
			this->txtP13->Size = System::Drawing::Size(54, 20);
			this->txtP13->TabIndex = 27;
			this->txtP13->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label79
			// 
			this->label79->AutoSize = true;
			this->label79->Location = System::Drawing::Point(10, 377);
			this->label79->Name = L"label79";
			this->label79->Size = System::Drawing::Size(26, 13);
			this->label79->TabIndex = 26;
			this->label79->Text = L"P13";
			// 
			// txtP12
			// 
			this->txtP12->Enabled = false;
			this->txtP12->Location = System::Drawing::Point(36, 348);
			this->txtP12->Name = L"txtP12";
			this->txtP12->Size = System::Drawing::Size(54, 20);
			this->txtP12->TabIndex = 25;
			this->txtP12->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label78
			// 
			this->label78->AutoSize = true;
			this->label78->Location = System::Drawing::Point(10, 351);
			this->label78->Name = L"label78";
			this->label78->Size = System::Drawing::Size(26, 13);
			this->label78->TabIndex = 24;
			this->label78->Text = L"P12";
			// 
			// txtP11
			// 
			this->txtP11->Enabled = false;
			this->txtP11->Location = System::Drawing::Point(36, 322);
			this->txtP11->Name = L"txtP11";
			this->txtP11->Size = System::Drawing::Size(54, 20);
			this->txtP11->TabIndex = 23;
			this->txtP11->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label77
			// 
			this->label77->AutoSize = true;
			this->label77->Location = System::Drawing::Point(10, 325);
			this->label77->Name = L"label77";
			this->label77->Size = System::Drawing::Size(26, 13);
			this->label77->TabIndex = 22;
			this->label77->Text = L"P11";
			// 
			// txtP15
			// 
			this->txtP15->Enabled = false;
			this->txtP15->Location = System::Drawing::Point(36, 426);
			this->txtP15->Name = L"txtP15";
			this->txtP15->Size = System::Drawing::Size(54, 20);
			this->txtP15->TabIndex = 23;
			this->txtP15->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label76
			// 
			this->label76->AutoSize = true;
			this->label76->Location = System::Drawing::Point(10, 429);
			this->label76->Name = L"label76";
			this->label76->Size = System::Drawing::Size(26, 13);
			this->label76->TabIndex = 22;
			this->label76->Text = L"P15";
			// 
			// txtP10
			// 
			this->txtP10->Enabled = false;
			this->txtP10->Location = System::Drawing::Point(36, 296);
			this->txtP10->Name = L"txtP10";
			this->txtP10->Size = System::Drawing::Size(54, 20);
			this->txtP10->TabIndex = 21;
			this->txtP10->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label75
			// 
			this->label75->AutoSize = true;
			this->label75->Location = System::Drawing::Point(10, 299);
			this->label75->Name = L"label75";
			this->label75->Size = System::Drawing::Size(26, 13);
			this->label75->TabIndex = 20;
			this->label75->Text = L"P10";
			// 
			// txtP9
			// 
			this->txtP9->Enabled = false;
			this->txtP9->Location = System::Drawing::Point(36, 270);
			this->txtP9->Name = L"txtP9";
			this->txtP9->Size = System::Drawing::Size(54, 20);
			this->txtP9->TabIndex = 19;
			this->txtP9->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label74
			// 
			this->label74->AutoSize = true;
			this->label74->Location = System::Drawing::Point(10, 273);
			this->label74->Name = L"label74";
			this->label74->Size = System::Drawing::Size(20, 13);
			this->label74->TabIndex = 18;
			this->label74->Text = L"P9";
			// 
			// txtP8
			// 
			this->txtP8->Enabled = false;
			this->txtP8->Location = System::Drawing::Point(36, 244);
			this->txtP8->Name = L"txtP8";
			this->txtP8->Size = System::Drawing::Size(54, 20);
			this->txtP8->TabIndex = 17;
			this->txtP8->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label73
			// 
			this->label73->AutoSize = true;
			this->label73->Location = System::Drawing::Point(10, 247);
			this->label73->Name = L"label73";
			this->label73->Size = System::Drawing::Size(20, 13);
			this->label73->TabIndex = 16;
			this->label73->Text = L"P8";
			// 
			// txtP7
			// 
			this->txtP7->Location = System::Drawing::Point(36, 218);
			this->txtP7->Name = L"txtP7";
			this->txtP7->Size = System::Drawing::Size(54, 20);
			this->txtP7->TabIndex = 15;
			this->txtP7->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label72
			// 
			this->label72->AutoSize = true;
			this->label72->Location = System::Drawing::Point(10, 221);
			this->label72->Name = L"label72";
			this->label72->Size = System::Drawing::Size(20, 13);
			this->label72->TabIndex = 14;
			this->label72->Text = L"P7";
			// 
			// txtP6
			// 
			this->txtP6->Location = System::Drawing::Point(36, 192);
			this->txtP6->Name = L"txtP6";
			this->txtP6->Size = System::Drawing::Size(54, 20);
			this->txtP6->TabIndex = 13;
			this->txtP6->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label71
			// 
			this->label71->AutoSize = true;
			this->label71->Location = System::Drawing::Point(10, 195);
			this->label71->Name = L"label71";
			this->label71->Size = System::Drawing::Size(20, 13);
			this->label71->TabIndex = 12;
			this->label71->Text = L"P6";
			// 
			// txtP5
			// 
			this->txtP5->Location = System::Drawing::Point(36, 166);
			this->txtP5->Name = L"txtP5";
			this->txtP5->Size = System::Drawing::Size(54, 20);
			this->txtP5->TabIndex = 11;
			this->txtP5->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label70
			// 
			this->label70->AutoSize = true;
			this->label70->Location = System::Drawing::Point(10, 169);
			this->label70->Name = L"label70";
			this->label70->Size = System::Drawing::Size(20, 13);
			this->label70->TabIndex = 10;
			this->label70->Text = L"P5";
			// 
			// txtP4
			// 
			this->txtP4->Location = System::Drawing::Point(36, 140);
			this->txtP4->Name = L"txtP4";
			this->txtP4->Size = System::Drawing::Size(54, 20);
			this->txtP4->TabIndex = 9;
			this->txtP4->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label69
			// 
			this->label69->AutoSize = true;
			this->label69->Location = System::Drawing::Point(10, 143);
			this->label69->Name = L"label69";
			this->label69->Size = System::Drawing::Size(20, 13);
			this->label69->TabIndex = 8;
			this->label69->Text = L"P4";
			// 
			// txtP3
			// 
			this->txtP3->Location = System::Drawing::Point(36, 114);
			this->txtP3->Name = L"txtP3";
			this->txtP3->Size = System::Drawing::Size(54, 20);
			this->txtP3->TabIndex = 7;
			this->txtP3->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label68
			// 
			this->label68->AutoSize = true;
			this->label68->Location = System::Drawing::Point(10, 117);
			this->label68->Name = L"label68";
			this->label68->Size = System::Drawing::Size(20, 13);
			this->label68->TabIndex = 6;
			this->label68->Text = L"P3";
			// 
			// txtP2
			// 
			this->txtP2->Location = System::Drawing::Point(36, 88);
			this->txtP2->Name = L"txtP2";
			this->txtP2->Size = System::Drawing::Size(54, 20);
			this->txtP2->TabIndex = 5;
			this->txtP2->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label67
			// 
			this->label67->AutoSize = true;
			this->label67->Location = System::Drawing::Point(10, 91);
			this->label67->Name = L"label67";
			this->label67->Size = System::Drawing::Size(20, 13);
			this->label67->TabIndex = 4;
			this->label67->Text = L"P2";
			// 
			// txtP1
			// 
			this->txtP1->Location = System::Drawing::Point(36, 62);
			this->txtP1->Name = L"txtP1";
			this->txtP1->Size = System::Drawing::Size(54, 20);
			this->txtP1->TabIndex = 3;
			this->txtP1->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label66
			// 
			this->label66->AutoSize = true;
			this->label66->Location = System::Drawing::Point(10, 65);
			this->label66->Name = L"label66";
			this->label66->Size = System::Drawing::Size(20, 13);
			this->label66->TabIndex = 2;
			this->label66->Text = L"P1";
			// 
			// txtP0
			// 
			this->txtP0->Location = System::Drawing::Point(36, 36);
			this->txtP0->Name = L"txtP0";
			this->txtP0->Size = System::Drawing::Size(54, 20);
			this->txtP0->TabIndex = 1;
			this->txtP0->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label65
			// 
			this->label65->AutoSize = true;
			this->label65->Location = System::Drawing::Point(10, 39);
			this->label65->Name = L"label65";
			this->label65->Size = System::Drawing::Size(20, 13);
			this->label65->TabIndex = 0;
			this->label65->Text = L"P0";
			// 
			// toolTipC12
			// 
			this->toolTipC12->IsBalloon = true;
			this->toolTipC12->ShowAlways = true;
			// 
			// toolTipC14
			// 
			this->toolTipC14->IsBalloon = true;
			this->toolTipC14->ShowAlways = true;
			// 
			// toolTipC1
			// 
			this->toolTipC1->IsBalloon = true;
			this->toolTipC1->ShowAlways = true;
			// 
			// toolTipR31
			// 
			this->toolTipR31->IsBalloon = true;
			this->toolTipR31->ShowAlways = true;
			// 
			// toolTipR30
			// 
			this->toolTipR30->IsBalloon = true;
			this->toolTipR30->ShowAlways = true;
			// 
			// toolTipR29
			// 
			this->toolTipR29->IsBalloon = true;
			this->toolTipR29->ShowAlways = true;
			// 
			// toolTipR28
			// 
			this->toolTipR28->IsBalloon = true;
			this->toolTipR28->ShowAlways = true;
			// 
			// toolTipC8
			// 
			this->toolTipC8->IsBalloon = true;
			this->toolTipC8->ShowAlways = true;
			// 
			// toolTipR0
			// 
			this->toolTipR0->IsBalloon = true;
			this->toolTipR0->ShowAlways = true;
			// 
			// btnUpdate
			// 
			this->btnUpdate->Location = System::Drawing::Point(676, 531);
			this->btnUpdate->Name = L"btnUpdate";
			this->btnUpdate->Size = System::Drawing::Size(75, 23);
			this->btnUpdate->TabIndex = 1;
			this->btnUpdate->Text = L"Update";
			this->btnUpdate->UseVisualStyleBackColor = true;
			this->btnUpdate->Click += gcnew System::EventHandler(this, &frmRegisters::btnUpdate_Click);
			// 
			// toolTipC10
			// 
			this->toolTipC10->IsBalloon = true;
			this->toolTipC10->ShowAlways = true;
			// 
			// frmRegisters
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(767, 571);
			this->Controls->Add(this->btnUpdate);
			this->Controls->Add(this->tabControl1);
			this->Name = L"frmRegisters";
			this->Text = L"Thor - Registers";
			this->Activated += gcnew System::EventHandler(this, &frmRegisters::frmRegisters_Activated);
			this->FormClosing += gcnew System::Windows::Forms::FormClosingEventHandler(this, &frmRegisters::frmRegisters_FormClosing);
			this->tabControl1->ResumeLayout(false);
			this->tabPage1->ResumeLayout(false);
			this->tabPage1->PerformLayout();
			this->tabPage2->ResumeLayout(false);
			this->tabPage2->PerformLayout();
			this->ResumeLayout(false);

		}
#pragma endregion
	public: void UpdateForm() {
			char buf[100];
			mut->WaitOne();
			char *fmtstr = system1.cpu2._32bit ? "%08I64X": "%016I64X";
			sprintf(buf, fmtstr, system1.cpu2.gp[1]);
			txtR1->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[2]);
			txtR2->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[3]);
			txtR3->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[4]);
			txtR4->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[5]);
			txtR5->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[6]);
			txtR6->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[7]);
			txtR7->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[8]);
			txtR8->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[9]);
			txtR9->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[10]);
			txtR10->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[11]);
			txtR11->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[12]);
			txtR12->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[13]);
			txtR13->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[14]);
			txtR14->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[15]);
			txtR15->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[16]);
			txtR16->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[17]);
			txtR17->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[18]);
			txtR18->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[19]);
			txtR19->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[20]);
			txtR20->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[21]);
			txtR21->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[22]);
			txtR22->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[23]);
			txtR23->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[24]);
			txtR24->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[25]);
			txtR25->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[26]);
			txtR26->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[27]);
			txtR27->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[28]);
			txtR28->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[29]);
			txtR29->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[30]);
			txtR30->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[31]);
			txtR31->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[32]);
			txtR32->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[33]);
			txtR33->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[34]);
			txtR34->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[35]);
			txtR35->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[36]);
			txtR36->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[37]);
			txtR37->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[38]);
			txtR38->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[39]);
			txtR39->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[40]);
			txtR40->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[41]);
			txtR41->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[42]);
			txtR42->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[43]);
			txtR43->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[44]);
			txtR44->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[45]);
			txtR45->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[46]);
			txtR46->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[47]);
			txtR47->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[48]);
			txtR48->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[49]);
			txtR49->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[50]);
			txtR50->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[51]);
			txtR51->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[52]);
			txtR52->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[53]);
			txtR53->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[54]);
			txtR54->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[55]);
			txtR55->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[56]);
			txtR56->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[57]);
			txtR57->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[58]);
			txtR58->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[59]);
			txtR59->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[60]);
			txtR60->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[61]);
			txtR61->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[62]);
			txtR62->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.gp[63]);
			txtR63->Text = gcnew String(buf);

			// Predicate Registers
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[0],
				system1.cpu2.pr[0] & 4 ? '<' : ' ',
				system1.cpu2.pr[0] & 2 ? '<' : ' ',
				system1.cpu2.pr[0] & 1 ? '=' : ' '
				);
			txtP0->Text = gcnew String(buf);
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[1],
				system1.cpu2.pr[1] & 4 ? '<' : ' ',
				system1.cpu2.pr[1] & 2 ? '<' : ' ',
				system1.cpu2.pr[1] & 1 ? '=' : ' '
				);
			txtP1->Text = gcnew String(buf);
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[2],
				system1.cpu2.pr[2] & 4 ? '<' : ' ',
				system1.cpu2.pr[2] & 2 ? '<' : ' ',
				system1.cpu2.pr[2] & 1 ? '=' : ' '
				);
			txtP2->Text = gcnew String(buf);
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[3],
				system1.cpu2.pr[3] & 4 ? '<' : ' ',
				system1.cpu2.pr[3] & 2 ? '<' : ' ',
				system1.cpu2.pr[3] & 1 ? '=' : ' '
				);
			txtP3->Text = gcnew String(buf);
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[4],
				system1.cpu2.pr[4] & 4 ? '<' : ' ',
				system1.cpu2.pr[4] & 2 ? '<' : ' ',
				system1.cpu2.pr[4] & 1 ? '=' : ' '
				);
			txtP4->Text = gcnew String(buf);
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[5],
				system1.cpu2.pr[5] & 4 ? '<' : ' ',
				system1.cpu2.pr[5] & 2 ? '<' : ' ',
				system1.cpu2.pr[5] & 1 ? '=' : ' '
				);
			txtP5->Text = gcnew String(buf);
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[6],
				system1.cpu2.pr[6] & 4 ? '<' : ' ',
				system1.cpu2.pr[6] & 2 ? '<' : ' ',
				system1.cpu2.pr[6] & 1 ? '=' : ' '
				);
			txtP6->Text = gcnew String(buf);
			sprintf(buf, "%01X %c%c%c", system1.cpu2.pr[7],
				system1.cpu2.pr[7] & 4 ? '<' : ' ',
				system1.cpu2.pr[7] & 2 ? '<' : ' ',
				system1.cpu2.pr[7] & 1 ? '=' : ' '
				);
			txtP7->Text = gcnew String(buf);
			if (system1.cpu2._32bit) {
				txtP8->Enabled = false;
				txtP9->Enabled = false;
				txtP10->Enabled = false;
				txtP11->Enabled = false;
				txtP12->Enabled = false;
				txtP13->Enabled = false;
				txtP14->Enabled = false;
				txtP15->Enabled = false;
			}

			// Code address registers
			sprintf(buf, fmtstr, system1.cpu2.ca[1]);
			txtCa1->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[2]);
			txtCa2->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[3]);
			txtCa3->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[4]);
			txtCa4->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[5]);
			txtCa5->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[6]);
			txtCa6->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[7]);
			txtCa7->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[8]);
			txtCa8->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[9]);
			txtCa9->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[10]);
			txtCa10->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[11]);
			txtCa11->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[12]);
			txtCa12->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[13]);
			txtCa13->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.ca[14]);
			txtCa14->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.pc);
			txtCa15->Text = gcnew String(buf);

			sprintf(buf, fmtstr, system1.cpu2.seg_base[0]);
			txtZs->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_base[1]);
			txtDs->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_base[2]);
			txtEs->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_base[3]);
			txtFs->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_base[4]);
			txtGs->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_base[5]);
			txtHs->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_base[6]);
			txtSs->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_base[7]);
			txtCs->Text = gcnew String(buf);

			sprintf(buf, fmtstr, system1.cpu2.seg_limit[0]);
			txtZsLmt->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_limit[1]);
			txtDsLmt->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_limit[2]);
			txtEsLmt->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_limit[3]);
			txtFsLmt->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_limit[4]);
			txtGsLmt->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_limit[5]);
			txtHsLmt->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_limit[6]);
			txtSsLmt->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.seg_limit[7]);
			txtCsLmt->Text = gcnew String(buf);

			sprintf(buf, fmtstr, system1.cpu2.tick);
			txtTick->Text = gcnew String(buf);
			sprintf(buf, fmtstr, system1.cpu2.lc);
			txtLC->Text = gcnew String(buf);
			mut->ReleaseMutex();
			}
	private: System::Void label2_Click(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void textBox2_TextChanged(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void frmRegisters_FormClosing(System::Object^  sender, System::Windows::Forms::FormClosingEventArgs^  e) {
			 if (e->CloseReason==CloseReason::UserClosing)
				 e->Cancel = true;
		 }
private: System::Void btnUpdate_Click(System::Object^  sender, System::EventArgs^  e) {
			 char *str, *ep;

 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR1->Text);
			 system1.cpu2.gp[1] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR2->Text);
			 system1.cpu2.gp[2] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR3->Text);
			 system1.cpu2.gp[3] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR4->Text);
			 system1.cpu2.gp[4] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR5->Text);
			 system1.cpu2.gp[5] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR6->Text);
			 system1.cpu2.gp[6] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR7->Text);
			 system1.cpu2.gp[7] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR8->Text);
			 system1.cpu2.gp[8] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR9->Text);
			 system1.cpu2.gp[9] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR10->Text);
			 system1.cpu2.gp[10] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR11->Text);
			 system1.cpu2.gp[11] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR12->Text);
			 system1.cpu2.gp[12] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR13->Text);
			 system1.cpu2.gp[13] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR14->Text);
			 system1.cpu2.gp[14] = _strtoui64(str, &ep, 16);
 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtR15->Text);
			 system1.cpu2.gp[15] = _strtoui64(str, &ep, 16);

 	 		 str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtLC->Text);
			 system1.cpu2.lc = _strtoui64(str, &ep, 16);
		 }
private: System::Void frmRegisters_Activated(System::Object^  sender, System::EventArgs^  e) {
			 UpdateForm();
		 }
};
}
