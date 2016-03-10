#pragma once
// Allows the user to disable / enable interrupts via the gui.
// The could be interrupt control on the Form associated with the device
// but it's more convenient to place all the interrupt related controls
// on a single form for the user.
// Timers are used to emulate the hard-wired interrupt clock sources in the
// test system.
extern bool irq1024Hz;
extern bool irq30Hz;
extern bool irqKeyboard;
extern bool irqUart;
extern bool trigger30;
extern bool trigger1024;
extern volatile unsigned int interval1024;
extern volatile unsigned int interval30;

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Threading;

	/// <summary>
	/// Summary for frmInterrupts
	/// </summary>
	public ref class frmInterrupts : public System::Windows::Forms::Form
	{
	public:
		Mutex^ mut;
		frmInterrupts(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			UpdateForm();
		}
		frmInterrupts(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			char buf[20];

			mut->WaitOne();
			system1.pic1.Step();
			trigger30 = false;
			trigger1024 = false;
			checkBox0En->Checked = system1.pic1.enables[0];
			checkBox1En->Checked = system1.pic1.enables[1];
			checkBox2En->Checked = system1.pic1.enables[2];
			checkBox3En->Checked = system1.pic1.enables[3];
			checkBox7En->Checked = system1.pic1.enables[7];
			checkBox1Act->Checked = system1.pic1.irq1024Hz;
			checkBox2Act->Checked = system1.pic1.irq30Hz;
			checkBox3Act->Checked = system1.pic1.irqKeyboard;
			checkBox7Act->Checked = system1.pic1.irqUart;
			checkBoxIRQOut->Checked = system1.pic1.irq;
			sprintf(buf, "%d (%02X)", system1.pic1.vecno, system1.pic1.vecno);
			mut->ReleaseMutex();
			textBoxVecno->Text = gcnew String(buf);
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmInterrupts()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::Button^  btnOK;
	protected: 
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Button^  btnTrigger30;
	private: System::Windows::Forms::ComboBox^  comboBox30;
	private: System::Windows::Forms::Button^  btnTrigger1024;
	private: System::Windows::Forms::ComboBox^  comboBox1024;
	private: System::Windows::Forms::CheckBox^  checkBox1024;
	private: System::Windows::Forms::CheckBox^  checkBoxKeyboard;
	private: System::Windows::Forms::CheckBox^  checkBox30;
	private: System::Windows::Forms::CheckBox^  checkBoxUart;
	private: System::Windows::Forms::GroupBox^  groupBox1;
	private: System::Windows::Forms::Label^  label6;
	private: System::Windows::Forms::Label^  label5;
	private: System::Windows::Forms::TextBox^  textBoxVecno;
	private: System::Windows::Forms::CheckBox^  checkBoxIRQOut;


	private: System::Windows::Forms::CheckBox^  checkBoxNMIOut;

	private: System::Windows::Forms::Label^  label4;
	private: System::Windows::Forms::CheckBox^  checkBox17;
	private: System::Windows::Forms::CheckBox^  checkBox18;
	private: System::Windows::Forms::CheckBox^  checkBox19;
	private: System::Windows::Forms::CheckBox^  checkBox20;
	private: System::Windows::Forms::CheckBox^  checkBox21;
	private: System::Windows::Forms::CheckBox^  checkBox22;
	private: System::Windows::Forms::CheckBox^  checkBox23;
	private: System::Windows::Forms::CheckBox^  checkBox24;
	private: System::Windows::Forms::CheckBox^  checkBox7Act;

	private: System::Windows::Forms::CheckBox^  checkBox26;
	private: System::Windows::Forms::CheckBox^  checkBox27;
	private: System::Windows::Forms::CheckBox^  checkBox28;
	private: System::Windows::Forms::CheckBox^  checkBox3Act;

	private: System::Windows::Forms::CheckBox^  checkBox2Act;

	private: System::Windows::Forms::CheckBox^  checkBox1Act;

	private: System::Windows::Forms::CheckBox^  checkBox0Act;

	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::CheckBox^  checkBox16;
	private: System::Windows::Forms::CheckBox^  checkBox15;
	private: System::Windows::Forms::CheckBox^  checkBox14;
	private: System::Windows::Forms::CheckBox^  checkBox13;
	private: System::Windows::Forms::CheckBox^  checkBox12;
	private: System::Windows::Forms::CheckBox^  checkBox11;
	private: System::Windows::Forms::CheckBox^  checkBox10;
	private: System::Windows::Forms::CheckBox^  checkBox9;
	private: System::Windows::Forms::CheckBox^  checkBox7En;

	private: System::Windows::Forms::CheckBox^  checkBox7;
	private: System::Windows::Forms::CheckBox^  checkBox6;
	private: System::Windows::Forms::CheckBox^  checkBox4En;

	private: System::Windows::Forms::CheckBox^  checkBox3En;

	private: System::Windows::Forms::CheckBox^  checkBox2En;

	private: System::Windows::Forms::CheckBox^  checkBox1En;

	private: System::Windows::Forms::CheckBox^  checkBox0En;
private: System::Windows::Forms::Label^  label7;
private: System::Windows::Forms::CheckBox^  checkBox1;
private: System::Windows::Forms::CheckBox^  checkBox2;
private: System::Windows::Forms::CheckBox^  checkBox3;
private: System::Windows::Forms::CheckBox^  checkBox4;
private: System::Windows::Forms::CheckBox^  checkBox5;
private: System::Windows::Forms::CheckBox^  checkBox8;
private: System::Windows::Forms::CheckBox^  checkBox25;
private: System::Windows::Forms::CheckBox^  checkBox29;
private: System::Windows::Forms::CheckBox^  checkBox7Edge;

private: System::Windows::Forms::CheckBox^  checkBox32;
private: System::Windows::Forms::CheckBox^  checkBox33;
private: System::Windows::Forms::CheckBox^  checkBox34;
private: System::Windows::Forms::CheckBox^  checkBox3Edge;

private: System::Windows::Forms::CheckBox^  checkBox2Edge;

private: System::Windows::Forms::CheckBox^  checkBox1Edge;

private: System::Windows::Forms::CheckBox^  checkBox0Edge;



	private:
		/// <summary>
		/// Required designer variable.
		/// </summary>
		System::ComponentModel::Container ^components;

#pragma region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		void InitializeComponent(void)
		{
			this->btnOK = (gcnew System::Windows::Forms::Button());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->btnTrigger30 = (gcnew System::Windows::Forms::Button());
			this->comboBox30 = (gcnew System::Windows::Forms::ComboBox());
			this->btnTrigger1024 = (gcnew System::Windows::Forms::Button());
			this->comboBox1024 = (gcnew System::Windows::Forms::ComboBox());
			this->checkBox1024 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBoxKeyboard = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox30 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBoxUart = (gcnew System::Windows::Forms::CheckBox());
			this->groupBox1 = (gcnew System::Windows::Forms::GroupBox());
			this->label7 = (gcnew System::Windows::Forms::Label());
			this->checkBox1 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox2 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox3 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox4 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox5 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox8 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox25 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox29 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox7Edge = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox32 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox33 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox34 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox3Edge = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox2Edge = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox1Edge = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox0Edge = (gcnew System::Windows::Forms::CheckBox());
			this->label6 = (gcnew System::Windows::Forms::Label());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->textBoxVecno = (gcnew System::Windows::Forms::TextBox());
			this->checkBoxIRQOut = (gcnew System::Windows::Forms::CheckBox());
			this->checkBoxNMIOut = (gcnew System::Windows::Forms::CheckBox());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->checkBox17 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox18 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox19 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox20 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox21 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox22 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox23 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox24 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox7Act = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox26 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox27 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox28 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox3Act = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox2Act = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox1Act = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox0Act = (gcnew System::Windows::Forms::CheckBox());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->checkBox16 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox15 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox14 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox13 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox12 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox11 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox10 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox9 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox7En = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox7 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox6 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox4En = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox3En = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox2En = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox1En = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox0En = (gcnew System::Windows::Forms::CheckBox());
			this->groupBox1->SuspendLayout();
			this->SuspendLayout();
			// 
			// btnOK
			// 
			this->btnOK->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->btnOK->Location = System::Drawing::Point(247, 137);
			this->btnOK->Name = L"btnOK";
			this->btnOK->Size = System::Drawing::Size(75, 23);
			this->btnOK->TabIndex = 19;
			this->btnOK->Text = L"OK";
			this->btnOK->UseVisualStyleBackColor = true;
			this->btnOK->Click += gcnew System::EventHandler(this, &frmInterrupts::btnOK_Click);
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(107, 43);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(57, 13);
			this->label2->TabIndex = 18;
			this->label2->Text = L"Frequency";
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(10, 43);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(77, 13);
			this->label1->TabIndex = 17;
			this->label1->Text = L"Source Enable";
			// 
			// btnTrigger30
			// 
			this->btnTrigger30->Location = System::Drawing::Point(247, 92);
			this->btnTrigger30->Name = L"btnTrigger30";
			this->btnTrigger30->Size = System::Drawing::Size(75, 23);
			this->btnTrigger30->TabIndex = 16;
			this->btnTrigger30->Text = L"Trigger";
			this->btnTrigger30->UseVisualStyleBackColor = true;
			this->btnTrigger30->Click += gcnew System::EventHandler(this, &frmInterrupts::btnTrigger30_Click);
			// 
			// comboBox30
			// 
			this->comboBox30->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->comboBox30->FormattingEnabled = true;
			this->comboBox30->Items->AddRange(gcnew cli::array< System::Object^  >(5) {L"30Hz", L"3 Hz", L"Every 3 seconds", L"Every 30 Seconds", 
				L"One shot"});
			this->comboBox30->Location = System::Drawing::Point(110, 94);
			this->comboBox30->Name = L"comboBox30";
			this->comboBox30->Size = System::Drawing::Size(121, 21);
			this->comboBox30->TabIndex = 15;
			// 
			// btnTrigger1024
			// 
			this->btnTrigger1024->Location = System::Drawing::Point(247, 63);
			this->btnTrigger1024->Name = L"btnTrigger1024";
			this->btnTrigger1024->Size = System::Drawing::Size(75, 23);
			this->btnTrigger1024->TabIndex = 14;
			this->btnTrigger1024->Text = L"Trigger";
			this->btnTrigger1024->UseVisualStyleBackColor = true;
			this->btnTrigger1024->Click += gcnew System::EventHandler(this, &frmInterrupts::btnTrigger1024_Click);
			// 
			// comboBox1024
			// 
			this->comboBox1024->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->comboBox1024->FormattingEnabled = true;
			this->comboBox1024->Items->AddRange(gcnew cli::array< System::Object^  >(3) {L"102 Hz", L"1 Hz", L"One shot"});
			this->comboBox1024->Location = System::Drawing::Point(110, 65);
			this->comboBox1024->Name = L"comboBox1024";
			this->comboBox1024->Size = System::Drawing::Size(121, 21);
			this->comboBox1024->TabIndex = 13;
			// 
			// checkBox1024
			// 
			this->checkBox1024->AutoSize = true;
			this->checkBox1024->Location = System::Drawing::Point(13, 69);
			this->checkBox1024->Name = L"checkBox1024";
			this->checkBox1024->Size = System::Drawing::Size(63, 17);
			this->checkBox1024->TabIndex = 12;
			this->checkBox1024->Text = L"1024Hz";
			this->checkBox1024->UseVisualStyleBackColor = true;
			// 
			// checkBoxKeyboard
			// 
			this->checkBoxKeyboard->AutoSize = true;
			this->checkBoxKeyboard->Enabled = false;
			this->checkBoxKeyboard->Location = System::Drawing::Point(13, 115);
			this->checkBoxKeyboard->Name = L"checkBoxKeyboard";
			this->checkBoxKeyboard->Size = System::Drawing::Size(71, 17);
			this->checkBoxKeyboard->TabIndex = 11;
			this->checkBoxKeyboard->Text = L"Keyboard";
			this->checkBoxKeyboard->UseVisualStyleBackColor = true;
			// 
			// checkBox30
			// 
			this->checkBox30->AutoSize = true;
			this->checkBox30->Location = System::Drawing::Point(13, 92);
			this->checkBox30->Name = L"checkBox30";
			this->checkBox30->Size = System::Drawing::Size(51, 17);
			this->checkBox30->TabIndex = 10;
			this->checkBox30->Text = L"30Hz";
			this->checkBox30->UseVisualStyleBackColor = true;
			// 
			// checkBoxUart
			// 
			this->checkBoxUart->AutoSize = true;
			this->checkBoxUart->Enabled = false;
			this->checkBoxUart->Location = System::Drawing::Point(13, 138);
			this->checkBoxUart->Name = L"checkBoxUart";
			this->checkBoxUart->Size = System::Drawing::Size(46, 17);
			this->checkBoxUart->TabIndex = 20;
			this->checkBoxUart->Text = L"Uart";
			this->checkBoxUart->UseVisualStyleBackColor = true;
			// 
			// groupBox1
			// 
			this->groupBox1->Controls->Add(this->label7);
			this->groupBox1->Controls->Add(this->checkBox1);
			this->groupBox1->Controls->Add(this->checkBox2);
			this->groupBox1->Controls->Add(this->checkBox3);
			this->groupBox1->Controls->Add(this->checkBox4);
			this->groupBox1->Controls->Add(this->checkBox5);
			this->groupBox1->Controls->Add(this->checkBox8);
			this->groupBox1->Controls->Add(this->checkBox25);
			this->groupBox1->Controls->Add(this->checkBox29);
			this->groupBox1->Controls->Add(this->checkBox7Edge);
			this->groupBox1->Controls->Add(this->checkBox32);
			this->groupBox1->Controls->Add(this->checkBox33);
			this->groupBox1->Controls->Add(this->checkBox34);
			this->groupBox1->Controls->Add(this->checkBox3Edge);
			this->groupBox1->Controls->Add(this->checkBox2Edge);
			this->groupBox1->Controls->Add(this->checkBox1Edge);
			this->groupBox1->Controls->Add(this->checkBox0Edge);
			this->groupBox1->Controls->Add(this->label6);
			this->groupBox1->Controls->Add(this->label5);
			this->groupBox1->Controls->Add(this->textBoxVecno);
			this->groupBox1->Controls->Add(this->checkBoxIRQOut);
			this->groupBox1->Controls->Add(this->checkBoxNMIOut);
			this->groupBox1->Controls->Add(this->label4);
			this->groupBox1->Controls->Add(this->checkBox17);
			this->groupBox1->Controls->Add(this->checkBox18);
			this->groupBox1->Controls->Add(this->checkBox19);
			this->groupBox1->Controls->Add(this->checkBox20);
			this->groupBox1->Controls->Add(this->checkBox21);
			this->groupBox1->Controls->Add(this->checkBox22);
			this->groupBox1->Controls->Add(this->checkBox23);
			this->groupBox1->Controls->Add(this->checkBox24);
			this->groupBox1->Controls->Add(this->checkBox7Act);
			this->groupBox1->Controls->Add(this->checkBox26);
			this->groupBox1->Controls->Add(this->checkBox27);
			this->groupBox1->Controls->Add(this->checkBox28);
			this->groupBox1->Controls->Add(this->checkBox3Act);
			this->groupBox1->Controls->Add(this->checkBox2Act);
			this->groupBox1->Controls->Add(this->checkBox1Act);
			this->groupBox1->Controls->Add(this->checkBox0Act);
			this->groupBox1->Controls->Add(this->label3);
			this->groupBox1->Controls->Add(this->checkBox16);
			this->groupBox1->Controls->Add(this->checkBox15);
			this->groupBox1->Controls->Add(this->checkBox14);
			this->groupBox1->Controls->Add(this->checkBox13);
			this->groupBox1->Controls->Add(this->checkBox12);
			this->groupBox1->Controls->Add(this->checkBox11);
			this->groupBox1->Controls->Add(this->checkBox10);
			this->groupBox1->Controls->Add(this->checkBox9);
			this->groupBox1->Controls->Add(this->checkBox7En);
			this->groupBox1->Controls->Add(this->checkBox7);
			this->groupBox1->Controls->Add(this->checkBox6);
			this->groupBox1->Controls->Add(this->checkBox4En);
			this->groupBox1->Controls->Add(this->checkBox3En);
			this->groupBox1->Controls->Add(this->checkBox2En);
			this->groupBox1->Controls->Add(this->checkBox1En);
			this->groupBox1->Controls->Add(this->checkBox0En);
			this->groupBox1->Location = System::Drawing::Point(12, 166);
			this->groupBox1->Name = L"groupBox1";
			this->groupBox1->Size = System::Drawing::Size(310, 414);
			this->groupBox1->TabIndex = 21;
			this->groupBox1->TabStop = false;
			this->groupBox1->Text = L"PIC State";
			// 
			// label7
			// 
			this->label7->AutoSize = true;
			this->label7->Location = System::Drawing::Point(57, 26);
			this->label7->Name = L"label7";
			this->label7->Size = System::Drawing::Size(32, 13);
			this->label7->TabIndex = 55;
			this->label7->Text = L"Edge";
			// 
			// checkBox1
			// 
			this->checkBox1->AutoSize = true;
			this->checkBox1->Enabled = false;
			this->checkBox1->Location = System::Drawing::Point(60, 390);
			this->checkBox1->Name = L"checkBox1";
			this->checkBox1->Size = System::Drawing::Size(15, 14);
			this->checkBox1->TabIndex = 54;
			this->checkBox1->UseVisualStyleBackColor = true;
			// 
			// checkBox2
			// 
			this->checkBox2->AutoSize = true;
			this->checkBox2->Enabled = false;
			this->checkBox2->Location = System::Drawing::Point(60, 367);
			this->checkBox2->Name = L"checkBox2";
			this->checkBox2->Size = System::Drawing::Size(15, 14);
			this->checkBox2->TabIndex = 53;
			this->checkBox2->UseVisualStyleBackColor = true;
			// 
			// checkBox3
			// 
			this->checkBox3->AutoSize = true;
			this->checkBox3->Enabled = false;
			this->checkBox3->Location = System::Drawing::Point(60, 344);
			this->checkBox3->Name = L"checkBox3";
			this->checkBox3->Size = System::Drawing::Size(15, 14);
			this->checkBox3->TabIndex = 52;
			this->checkBox3->UseVisualStyleBackColor = true;
			// 
			// checkBox4
			// 
			this->checkBox4->AutoSize = true;
			this->checkBox4->Enabled = false;
			this->checkBox4->Location = System::Drawing::Point(60, 321);
			this->checkBox4->Name = L"checkBox4";
			this->checkBox4->Size = System::Drawing::Size(15, 14);
			this->checkBox4->TabIndex = 51;
			this->checkBox4->UseVisualStyleBackColor = true;
			// 
			// checkBox5
			// 
			this->checkBox5->AutoSize = true;
			this->checkBox5->Enabled = false;
			this->checkBox5->Location = System::Drawing::Point(60, 299);
			this->checkBox5->Name = L"checkBox5";
			this->checkBox5->Size = System::Drawing::Size(15, 14);
			this->checkBox5->TabIndex = 50;
			this->checkBox5->UseVisualStyleBackColor = true;
			// 
			// checkBox8
			// 
			this->checkBox8->AutoSize = true;
			this->checkBox8->Enabled = false;
			this->checkBox8->Location = System::Drawing::Point(60, 276);
			this->checkBox8->Name = L"checkBox8";
			this->checkBox8->Size = System::Drawing::Size(15, 14);
			this->checkBox8->TabIndex = 49;
			this->checkBox8->UseVisualStyleBackColor = true;
			// 
			// checkBox25
			// 
			this->checkBox25->AutoSize = true;
			this->checkBox25->Enabled = false;
			this->checkBox25->Location = System::Drawing::Point(60, 253);
			this->checkBox25->Name = L"checkBox25";
			this->checkBox25->Size = System::Drawing::Size(15, 14);
			this->checkBox25->TabIndex = 48;
			this->checkBox25->UseVisualStyleBackColor = true;
			// 
			// checkBox29
			// 
			this->checkBox29->AutoSize = true;
			this->checkBox29->Enabled = false;
			this->checkBox29->Location = System::Drawing::Point(60, 230);
			this->checkBox29->Name = L"checkBox29";
			this->checkBox29->Size = System::Drawing::Size(15, 14);
			this->checkBox29->TabIndex = 47;
			this->checkBox29->UseVisualStyleBackColor = true;
			// 
			// checkBox7Edge
			// 
			this->checkBox7Edge->AutoSize = true;
			this->checkBox7Edge->Enabled = false;
			this->checkBox7Edge->Location = System::Drawing::Point(60, 207);
			this->checkBox7Edge->Name = L"checkBox7Edge";
			this->checkBox7Edge->Size = System::Drawing::Size(15, 14);
			this->checkBox7Edge->TabIndex = 46;
			this->checkBox7Edge->UseVisualStyleBackColor = true;
			// 
			// checkBox32
			// 
			this->checkBox32->AutoSize = true;
			this->checkBox32->Enabled = false;
			this->checkBox32->Location = System::Drawing::Point(60, 184);
			this->checkBox32->Name = L"checkBox32";
			this->checkBox32->Size = System::Drawing::Size(15, 14);
			this->checkBox32->TabIndex = 45;
			this->checkBox32->UseVisualStyleBackColor = true;
			// 
			// checkBox33
			// 
			this->checkBox33->AutoSize = true;
			this->checkBox33->Enabled = false;
			this->checkBox33->Location = System::Drawing::Point(60, 161);
			this->checkBox33->Name = L"checkBox33";
			this->checkBox33->Size = System::Drawing::Size(15, 14);
			this->checkBox33->TabIndex = 44;
			this->checkBox33->UseVisualStyleBackColor = true;
			// 
			// checkBox34
			// 
			this->checkBox34->AutoSize = true;
			this->checkBox34->Enabled = false;
			this->checkBox34->Location = System::Drawing::Point(60, 138);
			this->checkBox34->Name = L"checkBox34";
			this->checkBox34->Size = System::Drawing::Size(15, 14);
			this->checkBox34->TabIndex = 43;
			this->checkBox34->UseVisualStyleBackColor = true;
			// 
			// checkBox3Edge
			// 
			this->checkBox3Edge->AutoSize = true;
			this->checkBox3Edge->Enabled = false;
			this->checkBox3Edge->Location = System::Drawing::Point(60, 115);
			this->checkBox3Edge->Name = L"checkBox3Edge";
			this->checkBox3Edge->Size = System::Drawing::Size(15, 14);
			this->checkBox3Edge->TabIndex = 42;
			this->checkBox3Edge->UseVisualStyleBackColor = true;
			// 
			// checkBox2Edge
			// 
			this->checkBox2Edge->AutoSize = true;
			this->checkBox2Edge->Enabled = false;
			this->checkBox2Edge->Location = System::Drawing::Point(60, 92);
			this->checkBox2Edge->Name = L"checkBox2Edge";
			this->checkBox2Edge->Size = System::Drawing::Size(15, 14);
			this->checkBox2Edge->TabIndex = 41;
			this->checkBox2Edge->UseVisualStyleBackColor = true;
			// 
			// checkBox1Edge
			// 
			this->checkBox1Edge->AutoSize = true;
			this->checkBox1Edge->Enabled = false;
			this->checkBox1Edge->Location = System::Drawing::Point(60, 69);
			this->checkBox1Edge->Name = L"checkBox1Edge";
			this->checkBox1Edge->Size = System::Drawing::Size(15, 14);
			this->checkBox1Edge->TabIndex = 40;
			this->checkBox1Edge->UseVisualStyleBackColor = true;
			// 
			// checkBox0Edge
			// 
			this->checkBox0Edge->AutoSize = true;
			this->checkBox0Edge->Enabled = false;
			this->checkBox0Edge->Location = System::Drawing::Point(60, 46);
			this->checkBox0Edge->Name = L"checkBox0Edge";
			this->checkBox0Edge->Size = System::Drawing::Size(15, 14);
			this->checkBox0Edge->TabIndex = 39;
			this->checkBox0Edge->UseVisualStyleBackColor = true;
			// 
			// label6
			// 
			this->label6->AutoSize = true;
			this->label6->Location = System::Drawing::Point(232, 26);
			this->label6->Name = L"label6";
			this->label6->Size = System::Drawing::Size(59, 13);
			this->label6->TabIndex = 38;
			this->label6->Text = L"PIC Output";
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Enabled = false;
			this->label5->Location = System::Drawing::Point(232, 93);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(38, 13);
			this->label5->TabIndex = 37;
			this->label5->Text = L"Vecno";
			// 
			// textBoxVecno
			// 
			this->textBoxVecno->Enabled = false;
			this->textBoxVecno->Location = System::Drawing::Point(235, 112);
			this->textBoxVecno->Name = L"textBoxVecno";
			this->textBoxVecno->Size = System::Drawing::Size(56, 20);
			this->textBoxVecno->TabIndex = 36;
			// 
			// checkBoxIRQOut
			// 
			this->checkBoxIRQOut->AutoSize = true;
			this->checkBoxIRQOut->Enabled = false;
			this->checkBoxIRQOut->Location = System::Drawing::Point(235, 69);
			this->checkBoxIRQOut->Name = L"checkBoxIRQOut";
			this->checkBoxIRQOut->Size = System::Drawing::Size(45, 17);
			this->checkBoxIRQOut->TabIndex = 35;
			this->checkBoxIRQOut->Text = L"IRQ";
			this->checkBoxIRQOut->UseVisualStyleBackColor = true;
			// 
			// checkBoxNMIOut
			// 
			this->checkBoxNMIOut->AutoSize = true;
			this->checkBoxNMIOut->Enabled = false;
			this->checkBoxNMIOut->Location = System::Drawing::Point(235, 46);
			this->checkBoxNMIOut->Name = L"checkBoxNMIOut";
			this->checkBoxNMIOut->Size = System::Drawing::Size(46, 17);
			this->checkBoxNMIOut->TabIndex = 34;
			this->checkBoxNMIOut->Text = L"NMI";
			this->checkBoxNMIOut->UseVisualStyleBackColor = true;
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(119, 26);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(64, 13);
			this->label4->TabIndex = 33;
			this->label4->Text = L"Input Active";
			// 
			// checkBox17
			// 
			this->checkBox17->AutoSize = true;
			this->checkBox17->Enabled = false;
			this->checkBox17->Location = System::Drawing::Point(119, 390);
			this->checkBox17->Name = L"checkBox17";
			this->checkBox17->Size = System::Drawing::Size(97, 17);
			this->checkBox17->TabIndex = 32;
			this->checkBox17->Text = L"15 Unassigned";
			this->checkBox17->UseVisualStyleBackColor = true;
			// 
			// checkBox18
			// 
			this->checkBox18->AutoSize = true;
			this->checkBox18->Enabled = false;
			this->checkBox18->Location = System::Drawing::Point(119, 367);
			this->checkBox18->Name = L"checkBox18";
			this->checkBox18->Size = System::Drawing::Size(97, 17);
			this->checkBox18->TabIndex = 31;
			this->checkBox18->Text = L"14 Unassigned";
			this->checkBox18->UseVisualStyleBackColor = true;
			// 
			// checkBox19
			// 
			this->checkBox19->AutoSize = true;
			this->checkBox19->Enabled = false;
			this->checkBox19->Location = System::Drawing::Point(119, 344);
			this->checkBox19->Name = L"checkBox19";
			this->checkBox19->Size = System::Drawing::Size(97, 17);
			this->checkBox19->TabIndex = 30;
			this->checkBox19->Text = L"13 Unassigned";
			this->checkBox19->UseVisualStyleBackColor = true;
			// 
			// checkBox20
			// 
			this->checkBox20->AutoSize = true;
			this->checkBox20->Enabled = false;
			this->checkBox20->Location = System::Drawing::Point(119, 321);
			this->checkBox20->Name = L"checkBox20";
			this->checkBox20->Size = System::Drawing::Size(97, 17);
			this->checkBox20->TabIndex = 29;
			this->checkBox20->Text = L"12 Unassigned";
			this->checkBox20->UseVisualStyleBackColor = true;
			// 
			// checkBox21
			// 
			this->checkBox21->AutoSize = true;
			this->checkBox21->Enabled = false;
			this->checkBox21->Location = System::Drawing::Point(119, 299);
			this->checkBox21->Name = L"checkBox21";
			this->checkBox21->Size = System::Drawing::Size(97, 17);
			this->checkBox21->TabIndex = 28;
			this->checkBox21->Text = L"11 Unassigned";
			this->checkBox21->UseVisualStyleBackColor = true;
			// 
			// checkBox22
			// 
			this->checkBox22->AutoSize = true;
			this->checkBox22->Enabled = false;
			this->checkBox22->Location = System::Drawing::Point(119, 276);
			this->checkBox22->Name = L"checkBox22";
			this->checkBox22->Size = System::Drawing::Size(97, 17);
			this->checkBox22->TabIndex = 27;
			this->checkBox22->Text = L"10 Unassigned";
			this->checkBox22->UseVisualStyleBackColor = true;
			// 
			// checkBox23
			// 
			this->checkBox23->AutoSize = true;
			this->checkBox23->Enabled = false;
			this->checkBox23->Location = System::Drawing::Point(119, 253);
			this->checkBox23->Name = L"checkBox23";
			this->checkBox23->Size = System::Drawing::Size(91, 17);
			this->checkBox23->TabIndex = 26;
			this->checkBox23->Text = L"9 Unassigned";
			this->checkBox23->UseVisualStyleBackColor = true;
			// 
			// checkBox24
			// 
			this->checkBox24->AutoSize = true;
			this->checkBox24->Enabled = false;
			this->checkBox24->Location = System::Drawing::Point(119, 230);
			this->checkBox24->Name = L"checkBox24";
			this->checkBox24->Size = System::Drawing::Size(91, 17);
			this->checkBox24->TabIndex = 25;
			this->checkBox24->Text = L"8 Unassigned";
			this->checkBox24->UseVisualStyleBackColor = true;
			// 
			// checkBox7Act
			// 
			this->checkBox7Act->AutoSize = true;
			this->checkBox7Act->Enabled = false;
			this->checkBox7Act->Location = System::Drawing::Point(119, 207);
			this->checkBox7Act->Name = L"checkBox7Act";
			this->checkBox7Act->Size = System::Drawing::Size(55, 17);
			this->checkBox7Act->TabIndex = 24;
			this->checkBox7Act->Text = L"7 Uart";
			this->checkBox7Act->UseVisualStyleBackColor = true;
			// 
			// checkBox26
			// 
			this->checkBox26->AutoSize = true;
			this->checkBox26->Enabled = false;
			this->checkBox26->Location = System::Drawing::Point(119, 184);
			this->checkBox26->Name = L"checkBox26";
			this->checkBox26->Size = System::Drawing::Size(91, 17);
			this->checkBox26->TabIndex = 23;
			this->checkBox26->Text = L"6 Unassigned";
			this->checkBox26->UseVisualStyleBackColor = true;
			// 
			// checkBox27
			// 
			this->checkBox27->AutoSize = true;
			this->checkBox27->Enabled = false;
			this->checkBox27->Location = System::Drawing::Point(119, 161);
			this->checkBox27->Name = L"checkBox27";
			this->checkBox27->Size = System::Drawing::Size(91, 17);
			this->checkBox27->TabIndex = 22;
			this->checkBox27->Text = L"5 Unassigned";
			this->checkBox27->UseVisualStyleBackColor = true;
			// 
			// checkBox28
			// 
			this->checkBox28->AutoSize = true;
			this->checkBox28->Enabled = false;
			this->checkBox28->Location = System::Drawing::Point(119, 138);
			this->checkBox28->Name = L"checkBox28";
			this->checkBox28->Size = System::Drawing::Size(91, 17);
			this->checkBox28->TabIndex = 21;
			this->checkBox28->Text = L"4 Unassigned";
			this->checkBox28->UseVisualStyleBackColor = true;
			// 
			// checkBox3Act
			// 
			this->checkBox3Act->AutoSize = true;
			this->checkBox3Act->Enabled = false;
			this->checkBox3Act->Location = System::Drawing::Point(119, 115);
			this->checkBox3Act->Name = L"checkBox3Act";
			this->checkBox3Act->Size = System::Drawing::Size(80, 17);
			this->checkBox3Act->TabIndex = 20;
			this->checkBox3Act->Text = L"3 Keyboard";
			this->checkBox3Act->UseVisualStyleBackColor = true;
			// 
			// checkBox2Act
			// 
			this->checkBox2Act->AutoSize = true;
			this->checkBox2Act->Enabled = false;
			this->checkBox2Act->Location = System::Drawing::Point(119, 92);
			this->checkBox2Act->Name = L"checkBox2Act";
			this->checkBox2Act->Size = System::Drawing::Size(60, 17);
			this->checkBox2Act->TabIndex = 19;
			this->checkBox2Act->Text = L"2 30Hz";
			this->checkBox2Act->UseVisualStyleBackColor = true;
			// 
			// checkBox1Act
			// 
			this->checkBox1Act->AutoSize = true;
			this->checkBox1Act->Enabled = false;
			this->checkBox1Act->Location = System::Drawing::Point(119, 69);
			this->checkBox1Act->Name = L"checkBox1Act";
			this->checkBox1Act->Size = System::Drawing::Size(72, 17);
			this->checkBox1Act->TabIndex = 18;
			this->checkBox1Act->Text = L"1 1024Hz";
			this->checkBox1Act->UseVisualStyleBackColor = true;
			// 
			// checkBox0Act
			// 
			this->checkBox0Act->AutoSize = true;
			this->checkBox0Act->Enabled = false;
			this->checkBox0Act->Location = System::Drawing::Point(119, 46);
			this->checkBox0Act->Name = L"checkBox0Act";
			this->checkBox0Act->Size = System::Drawing::Size(55, 17);
			this->checkBox0Act->TabIndex = 17;
			this->checkBox0Act->Text = L"0 NMI";
			this->checkBox0Act->UseVisualStyleBackColor = true;
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(6, 26);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(46, 13);
			this->label3->TabIndex = 16;
			this->label3->Text = L"Enabled";
			// 
			// checkBox16
			// 
			this->checkBox16->AutoSize = true;
			this->checkBox16->Enabled = false;
			this->checkBox16->Location = System::Drawing::Point(6, 390);
			this->checkBox16->Name = L"checkBox16";
			this->checkBox16->Size = System::Drawing::Size(15, 14);
			this->checkBox16->TabIndex = 15;
			this->checkBox16->UseVisualStyleBackColor = true;
			// 
			// checkBox15
			// 
			this->checkBox15->AutoSize = true;
			this->checkBox15->Enabled = false;
			this->checkBox15->Location = System::Drawing::Point(6, 367);
			this->checkBox15->Name = L"checkBox15";
			this->checkBox15->Size = System::Drawing::Size(15, 14);
			this->checkBox15->TabIndex = 14;
			this->checkBox15->UseVisualStyleBackColor = true;
			// 
			// checkBox14
			// 
			this->checkBox14->AutoSize = true;
			this->checkBox14->Enabled = false;
			this->checkBox14->Location = System::Drawing::Point(6, 344);
			this->checkBox14->Name = L"checkBox14";
			this->checkBox14->Size = System::Drawing::Size(15, 14);
			this->checkBox14->TabIndex = 13;
			this->checkBox14->UseVisualStyleBackColor = true;
			// 
			// checkBox13
			// 
			this->checkBox13->AutoSize = true;
			this->checkBox13->Enabled = false;
			this->checkBox13->Location = System::Drawing::Point(6, 321);
			this->checkBox13->Name = L"checkBox13";
			this->checkBox13->Size = System::Drawing::Size(15, 14);
			this->checkBox13->TabIndex = 12;
			this->checkBox13->UseVisualStyleBackColor = true;
			// 
			// checkBox12
			// 
			this->checkBox12->AutoSize = true;
			this->checkBox12->Enabled = false;
			this->checkBox12->Location = System::Drawing::Point(6, 299);
			this->checkBox12->Name = L"checkBox12";
			this->checkBox12->Size = System::Drawing::Size(15, 14);
			this->checkBox12->TabIndex = 11;
			this->checkBox12->UseVisualStyleBackColor = true;
			// 
			// checkBox11
			// 
			this->checkBox11->AutoSize = true;
			this->checkBox11->Enabled = false;
			this->checkBox11->Location = System::Drawing::Point(6, 276);
			this->checkBox11->Name = L"checkBox11";
			this->checkBox11->Size = System::Drawing::Size(15, 14);
			this->checkBox11->TabIndex = 10;
			this->checkBox11->UseVisualStyleBackColor = true;
			// 
			// checkBox10
			// 
			this->checkBox10->AutoSize = true;
			this->checkBox10->Enabled = false;
			this->checkBox10->Location = System::Drawing::Point(6, 253);
			this->checkBox10->Name = L"checkBox10";
			this->checkBox10->Size = System::Drawing::Size(15, 14);
			this->checkBox10->TabIndex = 9;
			this->checkBox10->UseVisualStyleBackColor = true;
			// 
			// checkBox9
			// 
			this->checkBox9->AutoSize = true;
			this->checkBox9->Enabled = false;
			this->checkBox9->Location = System::Drawing::Point(6, 230);
			this->checkBox9->Name = L"checkBox9";
			this->checkBox9->Size = System::Drawing::Size(15, 14);
			this->checkBox9->TabIndex = 8;
			this->checkBox9->UseVisualStyleBackColor = true;
			// 
			// checkBox7En
			// 
			this->checkBox7En->AutoSize = true;
			this->checkBox7En->Enabled = false;
			this->checkBox7En->Location = System::Drawing::Point(6, 207);
			this->checkBox7En->Name = L"checkBox7En";
			this->checkBox7En->Size = System::Drawing::Size(15, 14);
			this->checkBox7En->TabIndex = 7;
			this->checkBox7En->UseVisualStyleBackColor = true;
			// 
			// checkBox7
			// 
			this->checkBox7->AutoSize = true;
			this->checkBox7->Enabled = false;
			this->checkBox7->Location = System::Drawing::Point(6, 184);
			this->checkBox7->Name = L"checkBox7";
			this->checkBox7->Size = System::Drawing::Size(15, 14);
			this->checkBox7->TabIndex = 6;
			this->checkBox7->UseVisualStyleBackColor = true;
			// 
			// checkBox6
			// 
			this->checkBox6->AutoSize = true;
			this->checkBox6->Enabled = false;
			this->checkBox6->Location = System::Drawing::Point(6, 161);
			this->checkBox6->Name = L"checkBox6";
			this->checkBox6->Size = System::Drawing::Size(15, 14);
			this->checkBox6->TabIndex = 5;
			this->checkBox6->UseVisualStyleBackColor = true;
			// 
			// checkBox4En
			// 
			this->checkBox4En->AutoSize = true;
			this->checkBox4En->Enabled = false;
			this->checkBox4En->Location = System::Drawing::Point(6, 138);
			this->checkBox4En->Name = L"checkBox4En";
			this->checkBox4En->Size = System::Drawing::Size(15, 14);
			this->checkBox4En->TabIndex = 4;
			this->checkBox4En->UseVisualStyleBackColor = true;
			// 
			// checkBox3En
			// 
			this->checkBox3En->AutoSize = true;
			this->checkBox3En->Enabled = false;
			this->checkBox3En->Location = System::Drawing::Point(6, 115);
			this->checkBox3En->Name = L"checkBox3En";
			this->checkBox3En->Size = System::Drawing::Size(15, 14);
			this->checkBox3En->TabIndex = 3;
			this->checkBox3En->UseVisualStyleBackColor = true;
			// 
			// checkBox2En
			// 
			this->checkBox2En->AutoSize = true;
			this->checkBox2En->Enabled = false;
			this->checkBox2En->Location = System::Drawing::Point(6, 92);
			this->checkBox2En->Name = L"checkBox2En";
			this->checkBox2En->Size = System::Drawing::Size(15, 14);
			this->checkBox2En->TabIndex = 2;
			this->checkBox2En->UseVisualStyleBackColor = true;
			// 
			// checkBox1En
			// 
			this->checkBox1En->AutoSize = true;
			this->checkBox1En->Enabled = false;
			this->checkBox1En->Location = System::Drawing::Point(6, 69);
			this->checkBox1En->Name = L"checkBox1En";
			this->checkBox1En->Size = System::Drawing::Size(15, 14);
			this->checkBox1En->TabIndex = 1;
			this->checkBox1En->UseVisualStyleBackColor = true;
			// 
			// checkBox0En
			// 
			this->checkBox0En->AutoSize = true;
			this->checkBox0En->Enabled = false;
			this->checkBox0En->Location = System::Drawing::Point(6, 46);
			this->checkBox0En->Name = L"checkBox0En";
			this->checkBox0En->Size = System::Drawing::Size(15, 14);
			this->checkBox0En->TabIndex = 0;
			this->checkBox0En->UseVisualStyleBackColor = true;
			// 
			// frmInterrupts
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(331, 592);
			this->Controls->Add(this->groupBox1);
			this->Controls->Add(this->checkBoxUart);
			this->Controls->Add(this->btnOK);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->btnTrigger30);
			this->Controls->Add(this->comboBox30);
			this->Controls->Add(this->btnTrigger1024);
			this->Controls->Add(this->comboBox1024);
			this->Controls->Add(this->checkBox1024);
			this->Controls->Add(this->checkBoxKeyboard);
			this->Controls->Add(this->checkBox30);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedSingle;
			this->Name = L"frmInterrupts";
			this->SizeGripStyle = System::Windows::Forms::SizeGripStyle::Hide;
			this->Text = L"emuThor - Interrupts";
			this->FormClosing += gcnew System::Windows::Forms::FormClosingEventHandler(this, &frmInterrupts::frmInterrupts_FormClosing);
			this->Load += gcnew System::EventHandler(this, &frmInterrupts::frmInterrupts_Load);
			this->groupBox1->ResumeLayout(false);
			this->groupBox1->PerformLayout();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void btnOK_Click(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void btnTrigger1024_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (this->checkBox1024->Checked) {
			 mut->WaitOne();
			 switch(this->comboBox30->SelectedIndex) {
			 case 0: interval1024 = 98; break;
			 case 1: interval1024 = 977; break;
			 case 2: interval1024 = -1; break;
			 default: interval1024 = 977; break;
			 }
			 trigger1024 = true;
			 mut->ReleaseMutex();
			 }
		 }
private: System::Void btnTrigger30_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (this->checkBox30->Checked) {
		     mut->WaitOne();
			 switch(this->comboBox30->SelectedIndex) {
			 case 0: interval30 = 33; break;
			 case 1: interval30 = 333; break;
			 case 2: interval30 = 3333; break;
			 case 3: interval30 = 33333; break;
			 case 4: interval30 = -1; break;
			 default: interval30 = 33333; break;
			 }
			 trigger30 = true;
			 mut->ReleaseMutex();
			 }
		 }
public: void UpdateForm()
		 {
			char buf[20];

			mut->WaitOne();
			system1.pic1.Step();
			trigger30 = false;
			trigger1024 = false;
			checkBox0En->Checked = system1.pic1.enables[0];
			checkBox1En->Checked = system1.pic1.enables[1];
			checkBox2En->Checked = system1.pic1.enables[2];
			checkBox3En->Checked = system1.pic1.enables[3];
			checkBox7En->Checked = system1.pic1.enables[7];
			checkBox0Edge->Checked = system1.pic1.edges[0];
			checkBox1Edge->Checked = system1.pic1.edges[1];
			checkBox2Edge->Checked = system1.pic1.edges[2];
			checkBox3Edge->Checked = system1.pic1.edges[3];
			checkBox7Edge->Checked = system1.pic1.edges[7];
			checkBox1Act->Checked = system1.pic1.irq1024Hz;
			checkBox2Act->Checked = system1.pic1.irq30Hz;
			checkBox3Act->Checked = system1.pic1.irqKeyboard;
			checkBox7Act->Checked = system1.pic1.irqUart;
			checkBoxIRQOut->Checked = system1.pic1.irq;
			sprintf(buf, "%d (%02X)", system1.pic1.vecno, system1.pic1.vecno);
			mut->ReleaseMutex();
			textBoxVecno->Text = gcnew String(buf);
		 }
private: System::Void frmInterrupts_Load(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void frmInterrupts_FormClosing(System::Object^  sender, System::Windows::Forms::FormClosingEventArgs^  e) {
			 if (e->CloseReason==CloseReason::UserClosing)
				 e->Cancel = true;
		 }
};
}
