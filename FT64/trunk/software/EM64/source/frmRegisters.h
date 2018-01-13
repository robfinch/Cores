#pragma once

namespace E64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for frmRegisters
	/// </summary>
	public ref class frmRegisters : public System::Windows::Forms::Form
	{
	public:
		frmRegisters(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
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
	private: System::Windows::Forms::TextBox^  textR0;
	private: System::Windows::Forms::TextBox^  textR1;
	private: System::Windows::Forms::TextBox^  textR2;
	private: System::Windows::Forms::TextBox^  textR3;
	private: System::Windows::Forms::TextBox^  textR4;
	private: System::Windows::Forms::TextBox^  textR5;
	private: System::Windows::Forms::TextBox^  textR6;
	private: System::Windows::Forms::TextBox^  textR7;
	private: System::Windows::Forms::TextBox^  textR15;
	protected: 

	protected: 








	private: System::Windows::Forms::TextBox^  textR14;

	private: System::Windows::Forms::TextBox^  textR13;

	private: System::Windows::Forms::TextBox^  textR12;

	private: System::Windows::Forms::TextBox^  textR11;

	private: System::Windows::Forms::TextBox^  textR10;

	private: System::Windows::Forms::TextBox^  textR9;

	private: System::Windows::Forms::TextBox^  textR8;
	private: System::Windows::Forms::TextBox^  textR23;


	private: System::Windows::Forms::TextBox^  textR22;

	private: System::Windows::Forms::TextBox^  textR21;

	private: System::Windows::Forms::TextBox^  textR20;

	private: System::Windows::Forms::TextBox^  textR19;

	private: System::Windows::Forms::TextBox^  textR18;

	private: System::Windows::Forms::TextBox^  textR17;

	private: System::Windows::Forms::TextBox^  textR16;
	private: System::Windows::Forms::TextBox^  textR31;


	private: System::Windows::Forms::TextBox^  textR30;

	private: System::Windows::Forms::TextBox^  textR29;

	private: System::Windows::Forms::TextBox^  textR28;

	private: System::Windows::Forms::TextBox^  textR27;

	private: System::Windows::Forms::TextBox^  textR26;

	private: System::Windows::Forms::TextBox^  textR25;

	private: System::Windows::Forms::TextBox^  textR24;

	private: System::Windows::Forms::Label^  lblR0;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::Label^  label4;
	private: System::Windows::Forms::Label^  label5;
	private: System::Windows::Forms::Label^  label6;
	private: System::Windows::Forms::Label^  label7;
	private: System::Windows::Forms::Label^  label8;
	private: System::Windows::Forms::Label^  label9;
	private: System::Windows::Forms::Label^  label10;
	private: System::Windows::Forms::Label^  label11;
	private: System::Windows::Forms::Label^  label12;
	private: System::Windows::Forms::Label^  label13;
	private: System::Windows::Forms::Label^  label14;
	private: System::Windows::Forms::Label^  label15;
	private: System::Windows::Forms::Label^  label16;
	private: System::Windows::Forms::Label^  label17;
	private: System::Windows::Forms::Label^  label18;
	private: System::Windows::Forms::Label^  label19;
	private: System::Windows::Forms::Label^  label20;
	private: System::Windows::Forms::Label^  label21;
	private: System::Windows::Forms::Label^  label22;
	private: System::Windows::Forms::Label^  label23;
	private: System::Windows::Forms::Label^  label24;
	private: System::Windows::Forms::Label^  label25;
	private: System::Windows::Forms::Label^  label26;
	private: System::Windows::Forms::Label^  label27;
	private: System::Windows::Forms::Label^  label28;
	private: System::Windows::Forms::Label^  label29;
	private: System::Windows::Forms::Label^  label30;
	private: System::Windows::Forms::Label^  label31;
private: System::Windows::Forms::TextBox^  textPC;
private: System::Windows::Forms::TextBox^  textIPC;
private: System::Windows::Forms::TextBox^  textDPC;
private: System::Windows::Forms::TextBox^  textEPC;
private: System::Windows::Forms::TextBox^  textISP;
private: System::Windows::Forms::TextBox^  textDSP;
private: System::Windows::Forms::TextBox^  textESP;







	private: System::Windows::Forms::Label^  label32;
	private: System::Windows::Forms::Label^  label33;
	private: System::Windows::Forms::Label^  label34;
	private: System::Windows::Forms::Label^  label35;
	private: System::Windows::Forms::Label^  label36;
	private: System::Windows::Forms::Label^  label37;
	private: System::Windows::Forms::Label^  label38;

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
			this->textR0 = (gcnew System::Windows::Forms::TextBox());
			this->textR1 = (gcnew System::Windows::Forms::TextBox());
			this->textR2 = (gcnew System::Windows::Forms::TextBox());
			this->textR3 = (gcnew System::Windows::Forms::TextBox());
			this->textR4 = (gcnew System::Windows::Forms::TextBox());
			this->textR5 = (gcnew System::Windows::Forms::TextBox());
			this->textR6 = (gcnew System::Windows::Forms::TextBox());
			this->textR7 = (gcnew System::Windows::Forms::TextBox());
			this->textR15 = (gcnew System::Windows::Forms::TextBox());
			this->textR14 = (gcnew System::Windows::Forms::TextBox());
			this->textR13 = (gcnew System::Windows::Forms::TextBox());
			this->textR12 = (gcnew System::Windows::Forms::TextBox());
			this->textR11 = (gcnew System::Windows::Forms::TextBox());
			this->textR10 = (gcnew System::Windows::Forms::TextBox());
			this->textR9 = (gcnew System::Windows::Forms::TextBox());
			this->textR8 = (gcnew System::Windows::Forms::TextBox());
			this->textR23 = (gcnew System::Windows::Forms::TextBox());
			this->textR22 = (gcnew System::Windows::Forms::TextBox());
			this->textR21 = (gcnew System::Windows::Forms::TextBox());
			this->textR20 = (gcnew System::Windows::Forms::TextBox());
			this->textR19 = (gcnew System::Windows::Forms::TextBox());
			this->textR18 = (gcnew System::Windows::Forms::TextBox());
			this->textR17 = (gcnew System::Windows::Forms::TextBox());
			this->textR16 = (gcnew System::Windows::Forms::TextBox());
			this->textR31 = (gcnew System::Windows::Forms::TextBox());
			this->textR30 = (gcnew System::Windows::Forms::TextBox());
			this->textR29 = (gcnew System::Windows::Forms::TextBox());
			this->textR28 = (gcnew System::Windows::Forms::TextBox());
			this->textR27 = (gcnew System::Windows::Forms::TextBox());
			this->textR26 = (gcnew System::Windows::Forms::TextBox());
			this->textR25 = (gcnew System::Windows::Forms::TextBox());
			this->textR24 = (gcnew System::Windows::Forms::TextBox());
			this->lblR0 = (gcnew System::Windows::Forms::Label());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->label6 = (gcnew System::Windows::Forms::Label());
			this->label7 = (gcnew System::Windows::Forms::Label());
			this->label8 = (gcnew System::Windows::Forms::Label());
			this->label9 = (gcnew System::Windows::Forms::Label());
			this->label10 = (gcnew System::Windows::Forms::Label());
			this->label11 = (gcnew System::Windows::Forms::Label());
			this->label12 = (gcnew System::Windows::Forms::Label());
			this->label13 = (gcnew System::Windows::Forms::Label());
			this->label14 = (gcnew System::Windows::Forms::Label());
			this->label15 = (gcnew System::Windows::Forms::Label());
			this->label16 = (gcnew System::Windows::Forms::Label());
			this->label17 = (gcnew System::Windows::Forms::Label());
			this->label18 = (gcnew System::Windows::Forms::Label());
			this->label19 = (gcnew System::Windows::Forms::Label());
			this->label20 = (gcnew System::Windows::Forms::Label());
			this->label21 = (gcnew System::Windows::Forms::Label());
			this->label22 = (gcnew System::Windows::Forms::Label());
			this->label23 = (gcnew System::Windows::Forms::Label());
			this->label24 = (gcnew System::Windows::Forms::Label());
			this->label25 = (gcnew System::Windows::Forms::Label());
			this->label26 = (gcnew System::Windows::Forms::Label());
			this->label27 = (gcnew System::Windows::Forms::Label());
			this->label28 = (gcnew System::Windows::Forms::Label());
			this->label29 = (gcnew System::Windows::Forms::Label());
			this->label30 = (gcnew System::Windows::Forms::Label());
			this->label31 = (gcnew System::Windows::Forms::Label());
			this->textPC = (gcnew System::Windows::Forms::TextBox());
			this->textIPC = (gcnew System::Windows::Forms::TextBox());
			this->textDPC = (gcnew System::Windows::Forms::TextBox());
			this->textEPC = (gcnew System::Windows::Forms::TextBox());
			this->textISP = (gcnew System::Windows::Forms::TextBox());
			this->textDSP = (gcnew System::Windows::Forms::TextBox());
			this->textESP = (gcnew System::Windows::Forms::TextBox());
			this->label32 = (gcnew System::Windows::Forms::Label());
			this->label33 = (gcnew System::Windows::Forms::Label());
			this->label34 = (gcnew System::Windows::Forms::Label());
			this->label35 = (gcnew System::Windows::Forms::Label());
			this->label36 = (gcnew System::Windows::Forms::Label());
			this->label37 = (gcnew System::Windows::Forms::Label());
			this->label38 = (gcnew System::Windows::Forms::Label());
			this->SuspendLayout();
			// 
			// textR0
			// 
			this->textR0->Location = System::Drawing::Point(39, 25);
			this->textR0->Name = L"textR0";
			this->textR0->ReadOnly = true;
			this->textR0->Size = System::Drawing::Size(82, 20);
			this->textR0->TabIndex = 0;
			this->textR0->TabStop = false;
			// 
			// textR1
			// 
			this->textR1->Location = System::Drawing::Point(39, 51);
			this->textR1->Name = L"textR1";
			this->textR1->Size = System::Drawing::Size(82, 20);
			this->textR1->TabIndex = 1;
			// 
			// textR2
			// 
			this->textR2->Location = System::Drawing::Point(39, 77);
			this->textR2->Name = L"textR2";
			this->textR2->Size = System::Drawing::Size(82, 20);
			this->textR2->TabIndex = 2;
			this->textR2->TextChanged += gcnew System::EventHandler(this, &frmRegisters::textBox3_TextChanged);
			// 
			// textR3
			// 
			this->textR3->Location = System::Drawing::Point(39, 103);
			this->textR3->Name = L"textR3";
			this->textR3->Size = System::Drawing::Size(82, 20);
			this->textR3->TabIndex = 3;
			// 
			// textR4
			// 
			this->textR4->Location = System::Drawing::Point(39, 129);
			this->textR4->Name = L"textR4";
			this->textR4->Size = System::Drawing::Size(82, 20);
			this->textR4->TabIndex = 4;
			// 
			// textR5
			// 
			this->textR5->Location = System::Drawing::Point(39, 155);
			this->textR5->Name = L"textR5";
			this->textR5->Size = System::Drawing::Size(82, 20);
			this->textR5->TabIndex = 5;
			// 
			// textR6
			// 
			this->textR6->Location = System::Drawing::Point(39, 181);
			this->textR6->Name = L"textR6";
			this->textR6->Size = System::Drawing::Size(82, 20);
			this->textR6->TabIndex = 6;
			// 
			// textR7
			// 
			this->textR7->Location = System::Drawing::Point(39, 207);
			this->textR7->Name = L"textR7";
			this->textR7->Size = System::Drawing::Size(82, 20);
			this->textR7->TabIndex = 7;
			// 
			// textR15
			// 
			this->textR15->Location = System::Drawing::Point(166, 207);
			this->textR15->Name = L"textR15";
			this->textR15->Size = System::Drawing::Size(82, 20);
			this->textR15->TabIndex = 15;
			// 
			// textR14
			// 
			this->textR14->Location = System::Drawing::Point(166, 181);
			this->textR14->Name = L"textR14";
			this->textR14->Size = System::Drawing::Size(82, 20);
			this->textR14->TabIndex = 14;
			// 
			// textR13
			// 
			this->textR13->Location = System::Drawing::Point(166, 155);
			this->textR13->Name = L"textR13";
			this->textR13->Size = System::Drawing::Size(82, 20);
			this->textR13->TabIndex = 13;
			// 
			// textR12
			// 
			this->textR12->Location = System::Drawing::Point(166, 129);
			this->textR12->Name = L"textR12";
			this->textR12->Size = System::Drawing::Size(82, 20);
			this->textR12->TabIndex = 12;
			// 
			// textR11
			// 
			this->textR11->Location = System::Drawing::Point(166, 103);
			this->textR11->Name = L"textR11";
			this->textR11->Size = System::Drawing::Size(82, 20);
			this->textR11->TabIndex = 11;
			// 
			// textR10
			// 
			this->textR10->Location = System::Drawing::Point(166, 77);
			this->textR10->Name = L"textR10";
			this->textR10->Size = System::Drawing::Size(82, 20);
			this->textR10->TabIndex = 10;
			// 
			// textR9
			// 
			this->textR9->Location = System::Drawing::Point(166, 51);
			this->textR9->Name = L"textR9";
			this->textR9->Size = System::Drawing::Size(82, 20);
			this->textR9->TabIndex = 9;
			// 
			// textR8
			// 
			this->textR8->Location = System::Drawing::Point(166, 25);
			this->textR8->Name = L"textR8";
			this->textR8->Size = System::Drawing::Size(82, 20);
			this->textR8->TabIndex = 8;
			// 
			// textR23
			// 
			this->textR23->Location = System::Drawing::Point(297, 207);
			this->textR23->Name = L"textR23";
			this->textR23->Size = System::Drawing::Size(82, 20);
			this->textR23->TabIndex = 23;
			// 
			// textR22
			// 
			this->textR22->Location = System::Drawing::Point(297, 181);
			this->textR22->Name = L"textR22";
			this->textR22->Size = System::Drawing::Size(82, 20);
			this->textR22->TabIndex = 22;
			// 
			// textR21
			// 
			this->textR21->Location = System::Drawing::Point(297, 155);
			this->textR21->Name = L"textR21";
			this->textR21->Size = System::Drawing::Size(82, 20);
			this->textR21->TabIndex = 21;
			// 
			// textR20
			// 
			this->textR20->Location = System::Drawing::Point(297, 129);
			this->textR20->Name = L"textR20";
			this->textR20->Size = System::Drawing::Size(82, 20);
			this->textR20->TabIndex = 20;
			// 
			// textR19
			// 
			this->textR19->Location = System::Drawing::Point(297, 103);
			this->textR19->Name = L"textR19";
			this->textR19->Size = System::Drawing::Size(82, 20);
			this->textR19->TabIndex = 19;
			// 
			// textR18
			// 
			this->textR18->Location = System::Drawing::Point(297, 77);
			this->textR18->Name = L"textR18";
			this->textR18->Size = System::Drawing::Size(82, 20);
			this->textR18->TabIndex = 18;
			// 
			// textR17
			// 
			this->textR17->Location = System::Drawing::Point(297, 51);
			this->textR17->Name = L"textR17";
			this->textR17->Size = System::Drawing::Size(82, 20);
			this->textR17->TabIndex = 17;
			// 
			// textR16
			// 
			this->textR16->Location = System::Drawing::Point(297, 25);
			this->textR16->Name = L"textR16";
			this->textR16->Size = System::Drawing::Size(82, 20);
			this->textR16->TabIndex = 16;
			// 
			// textR31
			// 
			this->textR31->Location = System::Drawing::Point(450, 207);
			this->textR31->Name = L"textR31";
			this->textR31->Size = System::Drawing::Size(82, 20);
			this->textR31->TabIndex = 31;
			// 
			// textR30
			// 
			this->textR30->Location = System::Drawing::Point(450, 181);
			this->textR30->Name = L"textR30";
			this->textR30->Size = System::Drawing::Size(82, 20);
			this->textR30->TabIndex = 30;
			// 
			// textR29
			// 
			this->textR29->Location = System::Drawing::Point(450, 155);
			this->textR29->Name = L"textR29";
			this->textR29->Size = System::Drawing::Size(82, 20);
			this->textR29->TabIndex = 29;
			// 
			// textR28
			// 
			this->textR28->Location = System::Drawing::Point(450, 129);
			this->textR28->Name = L"textR28";
			this->textR28->Size = System::Drawing::Size(82, 20);
			this->textR28->TabIndex = 28;
			// 
			// textR27
			// 
			this->textR27->Location = System::Drawing::Point(450, 103);
			this->textR27->Name = L"textR27";
			this->textR27->Size = System::Drawing::Size(82, 20);
			this->textR27->TabIndex = 27;
			// 
			// textR26
			// 
			this->textR26->Location = System::Drawing::Point(450, 77);
			this->textR26->Name = L"textR26";
			this->textR26->Size = System::Drawing::Size(82, 20);
			this->textR26->TabIndex = 26;
			// 
			// textR25
			// 
			this->textR25->Location = System::Drawing::Point(450, 51);
			this->textR25->Name = L"textR25";
			this->textR25->Size = System::Drawing::Size(82, 20);
			this->textR25->TabIndex = 25;
			// 
			// textR24
			// 
			this->textR24->Location = System::Drawing::Point(450, 25);
			this->textR24->Name = L"textR24";
			this->textR24->Size = System::Drawing::Size(82, 20);
			this->textR24->TabIndex = 24;
			// 
			// lblR0
			// 
			this->lblR0->AutoSize = true;
			this->lblR0->Location = System::Drawing::Point(12, 28);
			this->lblR0->Name = L"lblR0";
			this->lblR0->Size = System::Drawing::Size(21, 13);
			this->lblR0->TabIndex = 32;
			this->lblR0->Text = L"R0";
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(12, 54);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(21, 13);
			this->label1->TabIndex = 33;
			this->label1->Text = L"R1";
			this->label1->Click += gcnew System::EventHandler(this, &frmRegisters::label1_Click);
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(12, 80);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(21, 13);
			this->label2->TabIndex = 34;
			this->label2->Text = L"R2";
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(12, 106);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(21, 13);
			this->label3->TabIndex = 35;
			this->label3->Text = L"R3";
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(12, 132);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(21, 13);
			this->label4->TabIndex = 36;
			this->label4->Text = L"R4";
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Location = System::Drawing::Point(12, 158);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(21, 13);
			this->label5->TabIndex = 37;
			this->label5->Text = L"R5";
			// 
			// label6
			// 
			this->label6->AutoSize = true;
			this->label6->Location = System::Drawing::Point(12, 184);
			this->label6->Name = L"label6";
			this->label6->Size = System::Drawing::Size(21, 13);
			this->label6->TabIndex = 38;
			this->label6->Text = L"R6";
			// 
			// label7
			// 
			this->label7->AutoSize = true;
			this->label7->Location = System::Drawing::Point(12, 210);
			this->label7->Name = L"label7";
			this->label7->Size = System::Drawing::Size(21, 13);
			this->label7->TabIndex = 39;
			this->label7->Text = L"R7";
			// 
			// label8
			// 
			this->label8->AutoSize = true;
			this->label8->Location = System::Drawing::Point(139, 28);
			this->label8->Name = L"label8";
			this->label8->Size = System::Drawing::Size(21, 13);
			this->label8->TabIndex = 40;
			this->label8->Text = L"R8";
			// 
			// label9
			// 
			this->label9->AutoSize = true;
			this->label9->Location = System::Drawing::Point(139, 54);
			this->label9->Name = L"label9";
			this->label9->Size = System::Drawing::Size(21, 13);
			this->label9->TabIndex = 41;
			this->label9->Text = L"R9";
			// 
			// label10
			// 
			this->label10->AutoSize = true;
			this->label10->Location = System::Drawing::Point(139, 80);
			this->label10->Name = L"label10";
			this->label10->Size = System::Drawing::Size(27, 13);
			this->label10->TabIndex = 42;
			this->label10->Text = L"R10";
			// 
			// label11
			// 
			this->label11->AutoSize = true;
			this->label11->Location = System::Drawing::Point(139, 106);
			this->label11->Name = L"label11";
			this->label11->Size = System::Drawing::Size(27, 13);
			this->label11->TabIndex = 43;
			this->label11->Text = L"R11";
			// 
			// label12
			// 
			this->label12->AutoSize = true;
			this->label12->Location = System::Drawing::Point(139, 132);
			this->label12->Name = L"label12";
			this->label12->Size = System::Drawing::Size(27, 13);
			this->label12->TabIndex = 44;
			this->label12->Text = L"R12";
			// 
			// label13
			// 
			this->label13->AutoSize = true;
			this->label13->Location = System::Drawing::Point(139, 158);
			this->label13->Name = L"label13";
			this->label13->Size = System::Drawing::Size(27, 13);
			this->label13->TabIndex = 45;
			this->label13->Text = L"R13";
			// 
			// label14
			// 
			this->label14->AutoSize = true;
			this->label14->Location = System::Drawing::Point(139, 184);
			this->label14->Name = L"label14";
			this->label14->Size = System::Drawing::Size(27, 13);
			this->label14->TabIndex = 46;
			this->label14->Text = L"R14";
			// 
			// label15
			// 
			this->label15->AutoSize = true;
			this->label15->Location = System::Drawing::Point(139, 210);
			this->label15->Name = L"label15";
			this->label15->Size = System::Drawing::Size(27, 13);
			this->label15->TabIndex = 47;
			this->label15->Text = L"R15";
			// 
			// label16
			// 
			this->label16->AutoSize = true;
			this->label16->Location = System::Drawing::Point(264, 28);
			this->label16->Name = L"label16";
			this->label16->Size = System::Drawing::Size(27, 13);
			this->label16->TabIndex = 48;
			this->label16->Text = L"R16";
			// 
			// label17
			// 
			this->label17->AutoSize = true;
			this->label17->Location = System::Drawing::Point(264, 54);
			this->label17->Name = L"label17";
			this->label17->Size = System::Drawing::Size(27, 13);
			this->label17->TabIndex = 49;
			this->label17->Text = L"R17";
			// 
			// label18
			// 
			this->label18->AutoSize = true;
			this->label18->Location = System::Drawing::Point(264, 80);
			this->label18->Name = L"label18";
			this->label18->Size = System::Drawing::Size(27, 13);
			this->label18->TabIndex = 50;
			this->label18->Text = L"R18";
			// 
			// label19
			// 
			this->label19->AutoSize = true;
			this->label19->Location = System::Drawing::Point(264, 106);
			this->label19->Name = L"label19";
			this->label19->Size = System::Drawing::Size(27, 13);
			this->label19->TabIndex = 51;
			this->label19->Text = L"R19";
			// 
			// label20
			// 
			this->label20->AutoSize = true;
			this->label20->Location = System::Drawing::Point(264, 132);
			this->label20->Name = L"label20";
			this->label20->Size = System::Drawing::Size(27, 13);
			this->label20->TabIndex = 52;
			this->label20->Text = L"R20";
			// 
			// label21
			// 
			this->label21->AutoSize = true;
			this->label21->Location = System::Drawing::Point(264, 210);
			this->label21->Name = L"label21";
			this->label21->Size = System::Drawing::Size(27, 13);
			this->label21->TabIndex = 53;
			this->label21->Text = L"R23";
			// 
			// label22
			// 
			this->label22->AutoSize = true;
			this->label22->Location = System::Drawing::Point(264, 158);
			this->label22->Name = L"label22";
			this->label22->Size = System::Drawing::Size(27, 13);
			this->label22->TabIndex = 53;
			this->label22->Text = L"R21";
			// 
			// label23
			// 
			this->label23->AutoSize = true;
			this->label23->Location = System::Drawing::Point(264, 184);
			this->label23->Name = L"label23";
			this->label23->Size = System::Drawing::Size(27, 13);
			this->label23->TabIndex = 54;
			this->label23->Text = L"R22";
			// 
			// label24
			// 
			this->label24->AutoSize = true;
			this->label24->Location = System::Drawing::Point(394, 28);
			this->label24->Name = L"label24";
			this->label24->Size = System::Drawing::Size(47, 13);
			this->label24->TabIndex = 55;
			this->label24->Text = L"R24/TR";
			// 
			// label25
			// 
			this->label25->AutoSize = true;
			this->label25->Location = System::Drawing::Point(394, 54);
			this->label25->Name = L"label25";
			this->label25->Size = System::Drawing::Size(27, 13);
			this->label25->TabIndex = 56;
			this->label25->Text = L"R25";
			// 
			// label26
			// 
			this->label26->AutoSize = true;
			this->label26->Location = System::Drawing::Point(394, 80);
			this->label26->Name = L"label26";
			this->label26->Size = System::Drawing::Size(27, 13);
			this->label26->TabIndex = 57;
			this->label26->Text = L"R26";
			// 
			// label27
			// 
			this->label27->AutoSize = true;
			this->label27->Location = System::Drawing::Point(394, 106);
			this->label27->Name = L"label27";
			this->label27->Size = System::Drawing::Size(46, 13);
			this->label27->TabIndex = 58;
			this->label27->Text = L"R27/BP";
			// 
			// label28
			// 
			this->label28->AutoSize = true;
			this->label28->Location = System::Drawing::Point(394, 132);
			this->label28->Name = L"label28";
			this->label28->Size = System::Drawing::Size(53, 13);
			this->label28->TabIndex = 59;
			this->label28->Text = L"R28/XLR";
			this->label28->Click += gcnew System::EventHandler(this, &frmRegisters::label28_Click);
			// 
			// label29
			// 
			this->label29->AutoSize = true;
			this->label29->Location = System::Drawing::Point(394, 158);
			this->label29->Name = L"label29";
			this->label29->Size = System::Drawing::Size(27, 13);
			this->label29->TabIndex = 60;
			this->label29->Text = L"R29";
			// 
			// label30
			// 
			this->label30->AutoSize = true;
			this->label30->Location = System::Drawing::Point(394, 184);
			this->label30->Name = L"label30";
			this->label30->Size = System::Drawing::Size(46, 13);
			this->label30->TabIndex = 61;
			this->label30->Text = L"R30/SP";
			// 
			// label31
			// 
			this->label31->AutoSize = true;
			this->label31->Location = System::Drawing::Point(394, 210);
			this->label31->Name = L"label31";
			this->label31->Size = System::Drawing::Size(46, 13);
			this->label31->TabIndex = 62;
			this->label31->Text = L"R31/LR";
			// 
			// textPC
			// 
			this->textPC->Location = System::Drawing::Point(39, 257);
			this->textPC->Name = L"textPC";
			this->textPC->Size = System::Drawing::Size(82, 20);
			this->textPC->TabIndex = 63;
			// 
			// textIPC
			// 
			this->textIPC->Location = System::Drawing::Point(39, 283);
			this->textIPC->Name = L"textIPC";
			this->textIPC->Size = System::Drawing::Size(82, 20);
			this->textIPC->TabIndex = 64;
			// 
			// textDPC
			// 
			this->textDPC->Location = System::Drawing::Point(39, 309);
			this->textDPC->Name = L"textDPC";
			this->textDPC->Size = System::Drawing::Size(82, 20);
			this->textDPC->TabIndex = 65;
			// 
			// textEPC
			// 
			this->textEPC->Location = System::Drawing::Point(39, 335);
			this->textEPC->Name = L"textEPC";
			this->textEPC->Size = System::Drawing::Size(82, 20);
			this->textEPC->TabIndex = 66;
			// 
			// textISP
			// 
			this->textISP->Location = System::Drawing::Point(166, 283);
			this->textISP->Name = L"textISP";
			this->textISP->Size = System::Drawing::Size(82, 20);
			this->textISP->TabIndex = 67;
			// 
			// textDSP
			// 
			this->textDSP->Location = System::Drawing::Point(166, 309);
			this->textDSP->Name = L"textDSP";
			this->textDSP->Size = System::Drawing::Size(82, 20);
			this->textDSP->TabIndex = 68;
			// 
			// textESP
			// 
			this->textESP->Location = System::Drawing::Point(166, 335);
			this->textESP->Name = L"textESP";
			this->textESP->Size = System::Drawing::Size(82, 20);
			this->textESP->TabIndex = 69;
			// 
			// label32
			// 
			this->label32->AutoSize = true;
			this->label32->Location = System::Drawing::Point(12, 260);
			this->label32->Name = L"label32";
			this->label32->Size = System::Drawing::Size(21, 13);
			this->label32->TabIndex = 70;
			this->label32->Text = L"PC";
			// 
			// label33
			// 
			this->label33->AutoSize = true;
			this->label33->Location = System::Drawing::Point(12, 286);
			this->label33->Name = L"label33";
			this->label33->Size = System::Drawing::Size(24, 13);
			this->label33->TabIndex = 71;
			this->label33->Text = L"IPC";
			// 
			// label34
			// 
			this->label34->AutoSize = true;
			this->label34->Location = System::Drawing::Point(12, 312);
			this->label34->Name = L"label34";
			this->label34->Size = System::Drawing::Size(29, 13);
			this->label34->TabIndex = 72;
			this->label34->Text = L"DPC";
			// 
			// label35
			// 
			this->label35->AutoSize = true;
			this->label35->Location = System::Drawing::Point(12, 338);
			this->label35->Name = L"label35";
			this->label35->Size = System::Drawing::Size(28, 13);
			this->label35->TabIndex = 73;
			this->label35->Text = L"EPC";
			// 
			// label36
			// 
			this->label36->AutoSize = true;
			this->label36->Location = System::Drawing::Point(139, 286);
			this->label36->Name = L"label36";
			this->label36->Size = System::Drawing::Size(24, 13);
			this->label36->TabIndex = 74;
			this->label36->Text = L"ISP";
			// 
			// label37
			// 
			this->label37->AutoSize = true;
			this->label37->Location = System::Drawing::Point(139, 312);
			this->label37->Name = L"label37";
			this->label37->Size = System::Drawing::Size(29, 13);
			this->label37->TabIndex = 75;
			this->label37->Text = L"DSP";
			// 
			// label38
			// 
			this->label38->AutoSize = true;
			this->label38->Location = System::Drawing::Point(139, 338);
			this->label38->Name = L"label38";
			this->label38->Size = System::Drawing::Size(28, 13);
			this->label38->TabIndex = 76;
			this->label38->Text = L"ESP";
			// 
			// frmRegisters
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(553, 369);
			this->Controls->Add(this->label38);
			this->Controls->Add(this->label37);
			this->Controls->Add(this->label36);
			this->Controls->Add(this->label35);
			this->Controls->Add(this->label34);
			this->Controls->Add(this->label33);
			this->Controls->Add(this->label32);
			this->Controls->Add(this->textESP);
			this->Controls->Add(this->textDSP);
			this->Controls->Add(this->textISP);
			this->Controls->Add(this->textEPC);
			this->Controls->Add(this->textDPC);
			this->Controls->Add(this->textIPC);
			this->Controls->Add(this->textPC);
			this->Controls->Add(this->label31);
			this->Controls->Add(this->label30);
			this->Controls->Add(this->label29);
			this->Controls->Add(this->label28);
			this->Controls->Add(this->label27);
			this->Controls->Add(this->label26);
			this->Controls->Add(this->label25);
			this->Controls->Add(this->label24);
			this->Controls->Add(this->label23);
			this->Controls->Add(this->label22);
			this->Controls->Add(this->label21);
			this->Controls->Add(this->label20);
			this->Controls->Add(this->label19);
			this->Controls->Add(this->label18);
			this->Controls->Add(this->label17);
			this->Controls->Add(this->label16);
			this->Controls->Add(this->label15);
			this->Controls->Add(this->label14);
			this->Controls->Add(this->label13);
			this->Controls->Add(this->label12);
			this->Controls->Add(this->label11);
			this->Controls->Add(this->label10);
			this->Controls->Add(this->label9);
			this->Controls->Add(this->label8);
			this->Controls->Add(this->label7);
			this->Controls->Add(this->label6);
			this->Controls->Add(this->label5);
			this->Controls->Add(this->label4);
			this->Controls->Add(this->label3);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->lblR0);
			this->Controls->Add(this->textR31);
			this->Controls->Add(this->textR30);
			this->Controls->Add(this->textR29);
			this->Controls->Add(this->textR28);
			this->Controls->Add(this->textR27);
			this->Controls->Add(this->textR26);
			this->Controls->Add(this->textR25);
			this->Controls->Add(this->textR24);
			this->Controls->Add(this->textR23);
			this->Controls->Add(this->textR22);
			this->Controls->Add(this->textR21);
			this->Controls->Add(this->textR20);
			this->Controls->Add(this->textR19);
			this->Controls->Add(this->textR18);
			this->Controls->Add(this->textR17);
			this->Controls->Add(this->textR16);
			this->Controls->Add(this->textR15);
			this->Controls->Add(this->textR14);
			this->Controls->Add(this->textR13);
			this->Controls->Add(this->textR12);
			this->Controls->Add(this->textR11);
			this->Controls->Add(this->textR10);
			this->Controls->Add(this->textR9);
			this->Controls->Add(this->textR8);
			this->Controls->Add(this->textR7);
			this->Controls->Add(this->textR6);
			this->Controls->Add(this->textR5);
			this->Controls->Add(this->textR4);
			this->Controls->Add(this->textR3);
			this->Controls->Add(this->textR2);
			this->Controls->Add(this->textR1);
			this->Controls->Add(this->textR0);
			this->Name = L"frmRegisters";
			this->Text = L"Registers";
			this->Load += gcnew System::EventHandler(this, &frmRegisters::frmRegisters_Load);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void label1_Click(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void label28_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void textBox3_TextChanged(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void frmRegisters_Load(System::Object^  sender, System::EventArgs^  e) {
		 }
};
}

