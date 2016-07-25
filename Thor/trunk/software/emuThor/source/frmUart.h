#pragma once
#include "stdafx.h"
extern clsSystem system1;

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Runtime::InteropServices;
	using namespace System::Threading;

	/// <summary>
	/// Summary for frmUart
	/// </summary>
	public ref class frmUart : public System::Windows::Forms::Form
	{
	public:
		frmUart(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			do_send = false;
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmUart()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TextBox^  txtToUart;
	protected: 

	protected: 
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::TextBox^  txtFromUart;


	private: System::Windows::Forms::Button^  button2;
	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::TextBox^  txtCM0;
	private: System::Windows::Forms::TextBox^  txtCM1;


	private: System::Windows::Forms::Label^  label4;
	private: System::Windows::Forms::TextBox^  txtCM2;

	private: System::Windows::Forms::Label^  label5;
	private: System::Windows::Forms::TextBox^  txtCM3;

	private: System::Windows::Forms::Label^  label6;
	private: System::Windows::Forms::Label^  label7;
	private: System::Windows::Forms::TextBox^  txtTB;
	private: System::Windows::Forms::TextBox^  txtLS;


	private: System::Windows::Forms::Label^  label8;
	private: System::Windows::Forms::TextBox^  txtMS;

	private: System::Windows::Forms::Label^  label9;
	private: System::Windows::Forms::TextBox^  txtIS;


	private: System::Windows::Forms::Label^  label10;
	private: System::Windows::Forms::TextBox^  txtIER;
	private: System::Windows::Forms::Label^  label11;
	private: System::Windows::Forms::TextBox^  txtFF;

	private: System::Windows::Forms::Label^  label12;
	private: System::Windows::Forms::TextBox^  txtMC;

	private: System::Windows::Forms::Label^  label13;
	private: System::Windows::Forms::TextBox^  txtCTRL;

	private: System::Windows::Forms::Label^  label14;
	private: System::Windows::Forms::TextBox^  txtFC;

	private: System::Windows::Forms::Label^  label15;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::Windows::Forms::CheckBox^  checkBox1;
	private: System::Windows::Forms::CheckBox^  checkBox2;
	private: System::Windows::Forms::CheckBox^  checkBox3;
	private: System::Windows::Forms::TextBox^  txtRB;

	private: System::Windows::Forms::Label^  label16;
	private: System::ComponentModel::IContainer^  components;

	private:
		/// <summary>
		/// Required designer variable.
		/// </summary>
	private: bool do_send;
	private: Mutex^ mut;

#pragma region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		void InitializeComponent(void)
		{
			this->components = (gcnew System::ComponentModel::Container());
			this->txtToUart = (gcnew System::Windows::Forms::TextBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->txtFromUart = (gcnew System::Windows::Forms::TextBox());
			this->button2 = (gcnew System::Windows::Forms::Button());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->txtCM0 = (gcnew System::Windows::Forms::TextBox());
			this->txtCM1 = (gcnew System::Windows::Forms::TextBox());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->txtCM2 = (gcnew System::Windows::Forms::TextBox());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->txtCM3 = (gcnew System::Windows::Forms::TextBox());
			this->label6 = (gcnew System::Windows::Forms::Label());
			this->label7 = (gcnew System::Windows::Forms::Label());
			this->txtTB = (gcnew System::Windows::Forms::TextBox());
			this->txtLS = (gcnew System::Windows::Forms::TextBox());
			this->label8 = (gcnew System::Windows::Forms::Label());
			this->txtMS = (gcnew System::Windows::Forms::TextBox());
			this->label9 = (gcnew System::Windows::Forms::Label());
			this->txtIS = (gcnew System::Windows::Forms::TextBox());
			this->label10 = (gcnew System::Windows::Forms::Label());
			this->txtIER = (gcnew System::Windows::Forms::TextBox());
			this->label11 = (gcnew System::Windows::Forms::Label());
			this->txtFF = (gcnew System::Windows::Forms::TextBox());
			this->label12 = (gcnew System::Windows::Forms::Label());
			this->txtMC = (gcnew System::Windows::Forms::TextBox());
			this->label13 = (gcnew System::Windows::Forms::Label());
			this->txtCTRL = (gcnew System::Windows::Forms::TextBox());
			this->label14 = (gcnew System::Windows::Forms::Label());
			this->txtFC = (gcnew System::Windows::Forms::TextBox());
			this->label15 = (gcnew System::Windows::Forms::Label());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->checkBox1 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox2 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox3 = (gcnew System::Windows::Forms::CheckBox());
			this->txtRB = (gcnew System::Windows::Forms::TextBox());
			this->label16 = (gcnew System::Windows::Forms::Label());
			this->SuspendLayout();
			// 
			// txtToUart
			// 
			this->txtToUart->Location = System::Drawing::Point(27, 67);
			this->txtToUart->Multiline = true;
			this->txtToUart->Name = L"txtToUart";
			this->txtToUart->ScrollBars = System::Windows::Forms::ScrollBars::Both;
			this->txtToUart->Size = System::Drawing::Size(318, 124);
			this->txtToUart->TabIndex = 0;
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(24, 51);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(53, 13);
			this->label1->TabIndex = 1;
			this->label1->Text = L"To UART";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(24, 209);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(95, 13);
			this->label2->TabIndex = 2;
			this->label2->Text = L"UART Transmitted";
			// 
			// txtFromUart
			// 
			this->txtFromUart->Location = System::Drawing::Point(27, 225);
			this->txtFromUart->Multiline = true;
			this->txtFromUart->Name = L"txtFromUart";
			this->txtFromUart->ReadOnly = true;
			this->txtFromUart->ScrollBars = System::Windows::Forms::ScrollBars::Both;
			this->txtFromUart->Size = System::Drawing::Size(318, 124);
			this->txtFromUart->TabIndex = 3;
			// 
			// button2
			// 
			this->button2->Location = System::Drawing::Point(351, 65);
			this->button2->Name = L"button2";
			this->button2->Size = System::Drawing::Size(75, 23);
			this->button2->TabIndex = 5;
			this->button2->Text = L"Send";
			this->button2->UseVisualStyleBackColor = true;
			this->button2->Click += gcnew System::EventHandler(this, &frmUart::button2_Click);
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(471, 112);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(29, 13);
			this->label3->TabIndex = 6;
			this->label3->Text = L"CM0";
			// 
			// txtCM0
			// 
			this->txtCM0->Location = System::Drawing::Point(506, 109);
			this->txtCM0->Name = L"txtCM0";
			this->txtCM0->ReadOnly = true;
			this->txtCM0->Size = System::Drawing::Size(39, 20);
			this->txtCM0->TabIndex = 7;
			this->txtCM0->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtCM1
			// 
			this->txtCM1->Location = System::Drawing::Point(506, 135);
			this->txtCM1->Name = L"txtCM1";
			this->txtCM1->ReadOnly = true;
			this->txtCM1->Size = System::Drawing::Size(39, 20);
			this->txtCM1->TabIndex = 9;
			this->txtCM1->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(471, 138);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(29, 13);
			this->label4->TabIndex = 8;
			this->label4->Text = L"CM1";
			// 
			// txtCM2
			// 
			this->txtCM2->Location = System::Drawing::Point(506, 161);
			this->txtCM2->Name = L"txtCM2";
			this->txtCM2->ReadOnly = true;
			this->txtCM2->Size = System::Drawing::Size(39, 20);
			this->txtCM2->TabIndex = 11;
			this->txtCM2->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Location = System::Drawing::Point(471, 164);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(29, 13);
			this->label5->TabIndex = 10;
			this->label5->Text = L"CM2";
			// 
			// txtCM3
			// 
			this->txtCM3->Location = System::Drawing::Point(506, 187);
			this->txtCM3->Name = L"txtCM3";
			this->txtCM3->ReadOnly = true;
			this->txtCM3->Size = System::Drawing::Size(39, 20);
			this->txtCM3->TabIndex = 13;
			this->txtCM3->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label6
			// 
			this->label6->AutoSize = true;
			this->label6->Location = System::Drawing::Point(471, 190);
			this->label6->Name = L"label6";
			this->label6->Size = System::Drawing::Size(29, 13);
			this->label6->TabIndex = 12;
			this->label6->Text = L"CM3";
			// 
			// label7
			// 
			this->label7->AutoSize = true;
			this->label7->Location = System::Drawing::Point(374, 112);
			this->label7->Name = L"label7";
			this->label7->Size = System::Drawing::Size(21, 13);
			this->label7->TabIndex = 14;
			this->label7->Text = L"TB";
			// 
			// txtTB
			// 
			this->txtTB->Location = System::Drawing::Point(409, 109);
			this->txtTB->Name = L"txtTB";
			this->txtTB->ReadOnly = true;
			this->txtTB->Size = System::Drawing::Size(39, 20);
			this->txtTB->TabIndex = 15;
			this->txtTB->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// txtLS
			// 
			this->txtLS->Location = System::Drawing::Point(409, 164);
			this->txtLS->Name = L"txtLS";
			this->txtLS->ReadOnly = true;
			this->txtLS->Size = System::Drawing::Size(39, 20);
			this->txtLS->TabIndex = 17;
			this->txtLS->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label8
			// 
			this->label8->AutoSize = true;
			this->label8->Location = System::Drawing::Point(374, 167);
			this->label8->Name = L"label8";
			this->label8->Size = System::Drawing::Size(20, 13);
			this->label8->TabIndex = 16;
			this->label8->Text = L"LS";
			// 
			// txtMS
			// 
			this->txtMS->Location = System::Drawing::Point(409, 190);
			this->txtMS->Name = L"txtMS";
			this->txtMS->ReadOnly = true;
			this->txtMS->Size = System::Drawing::Size(39, 20);
			this->txtMS->TabIndex = 19;
			this->txtMS->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label9
			// 
			this->label9->AutoSize = true;
			this->label9->Location = System::Drawing::Point(374, 193);
			this->label9->Name = L"label9";
			this->label9->Size = System::Drawing::Size(23, 13);
			this->label9->TabIndex = 18;
			this->label9->Text = L"MS";
			// 
			// txtIS
			// 
			this->txtIS->Location = System::Drawing::Point(409, 216);
			this->txtIS->Name = L"txtIS";
			this->txtIS->ReadOnly = true;
			this->txtIS->Size = System::Drawing::Size(39, 20);
			this->txtIS->TabIndex = 21;
			this->txtIS->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label10
			// 
			this->label10->AutoSize = true;
			this->label10->Location = System::Drawing::Point(374, 219);
			this->label10->Name = L"label10";
			this->label10->Size = System::Drawing::Size(17, 13);
			this->label10->TabIndex = 20;
			this->label10->Text = L"IS";
			// 
			// txtIER
			// 
			this->txtIER->Location = System::Drawing::Point(409, 242);
			this->txtIER->Name = L"txtIER";
			this->txtIER->Size = System::Drawing::Size(39, 20);
			this->txtIER->TabIndex = 23;
			this->txtIER->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label11
			// 
			this->label11->AutoSize = true;
			this->label11->Location = System::Drawing::Point(374, 245);
			this->label11->Name = L"label11";
			this->label11->Size = System::Drawing::Size(25, 13);
			this->label11->TabIndex = 22;
			this->label11->Text = L"IER";
			// 
			// txtFF
			// 
			this->txtFF->Location = System::Drawing::Point(409, 268);
			this->txtFF->Name = L"txtFF";
			this->txtFF->Size = System::Drawing::Size(39, 20);
			this->txtFF->TabIndex = 25;
			this->txtFF->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label12
			// 
			this->label12->AutoSize = true;
			this->label12->Location = System::Drawing::Point(374, 271);
			this->label12->Name = L"label12";
			this->label12->Size = System::Drawing::Size(19, 13);
			this->label12->TabIndex = 24;
			this->label12->Text = L"FF";
			// 
			// txtMC
			// 
			this->txtMC->Location = System::Drawing::Point(409, 294);
			this->txtMC->Name = L"txtMC";
			this->txtMC->Size = System::Drawing::Size(39, 20);
			this->txtMC->TabIndex = 27;
			this->txtMC->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label13
			// 
			this->label13->AutoSize = true;
			this->label13->Location = System::Drawing::Point(374, 297);
			this->label13->Name = L"label13";
			this->label13->Size = System::Drawing::Size(23, 13);
			this->label13->TabIndex = 26;
			this->label13->Text = L"MC";
			// 
			// txtCTRL
			// 
			this->txtCTRL->Location = System::Drawing::Point(409, 320);
			this->txtCTRL->Name = L"txtCTRL";
			this->txtCTRL->Size = System::Drawing::Size(39, 20);
			this->txtCTRL->TabIndex = 29;
			this->txtCTRL->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label14
			// 
			this->label14->AutoSize = true;
			this->label14->Location = System::Drawing::Point(374, 323);
			this->label14->Name = L"label14";
			this->label14->Size = System::Drawing::Size(35, 13);
			this->label14->TabIndex = 28;
			this->label14->Text = L"CTRL";
			// 
			// txtFC
			// 
			this->txtFC->Location = System::Drawing::Point(506, 216);
			this->txtFC->Name = L"txtFC";
			this->txtFC->Size = System::Drawing::Size(39, 20);
			this->txtFC->TabIndex = 31;
			this->txtFC->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label15
			// 
			this->label15->AutoSize = true;
			this->label15->Location = System::Drawing::Point(471, 219);
			this->label15->Name = L"label15";
			this->label15->Size = System::Drawing::Size(20, 13);
			this->label15->TabIndex = 30;
			this->label15->Text = L"FC";
			// 
			// timer1
			// 
			this->timer1->Enabled = true;
			this->timer1->Tick += gcnew System::EventHandler(this, &frmUart::timer1_Tick);
			// 
			// checkBox1
			// 
			this->checkBox1->AutoSize = true;
			this->checkBox1->Checked = true;
			this->checkBox1->CheckState = System::Windows::Forms::CheckState::Checked;
			this->checkBox1->Location = System::Drawing::Point(27, 355);
			this->checkBox1->Name = L"checkBox1";
			this->checkBox1->Size = System::Drawing::Size(47, 17);
			this->checkBox1->TabIndex = 32;
			this->checkBox1->Text = L"CTS";
			this->checkBox1->UseVisualStyleBackColor = true;
			// 
			// checkBox2
			// 
			this->checkBox2->AutoSize = true;
			this->checkBox2->Checked = true;
			this->checkBox2->CheckState = System::Windows::Forms::CheckState::Checked;
			this->checkBox2->Location = System::Drawing::Point(27, 378);
			this->checkBox2->Name = L"checkBox2";
			this->checkBox2->Size = System::Drawing::Size(49, 17);
			this->checkBox2->TabIndex = 33;
			this->checkBox2->Text = L"DSR";
			this->checkBox2->UseVisualStyleBackColor = true;
			// 
			// checkBox3
			// 
			this->checkBox3->AutoSize = true;
			this->checkBox3->Checked = true;
			this->checkBox3->CheckState = System::Windows::Forms::CheckState::Checked;
			this->checkBox3->Location = System::Drawing::Point(27, 401);
			this->checkBox3->Name = L"checkBox3";
			this->checkBox3->Size = System::Drawing::Size(49, 17);
			this->checkBox3->TabIndex = 34;
			this->checkBox3->Text = L"DCD";
			this->checkBox3->UseVisualStyleBackColor = true;
			// 
			// txtRB
			// 
			this->txtRB->Location = System::Drawing::Point(409, 135);
			this->txtRB->Name = L"txtRB";
			this->txtRB->ReadOnly = true;
			this->txtRB->Size = System::Drawing::Size(39, 20);
			this->txtRB->TabIndex = 36;
			this->txtRB->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label16
			// 
			this->label16->AutoSize = true;
			this->label16->Location = System::Drawing::Point(374, 138);
			this->label16->Name = L"label16";
			this->label16->Size = System::Drawing::Size(22, 13);
			this->label16->TabIndex = 35;
			this->label16->Text = L"RB";
			// 
			// frmUart
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(571, 429);
			this->Controls->Add(this->txtRB);
			this->Controls->Add(this->label16);
			this->Controls->Add(this->checkBox3);
			this->Controls->Add(this->checkBox2);
			this->Controls->Add(this->checkBox1);
			this->Controls->Add(this->txtFC);
			this->Controls->Add(this->label15);
			this->Controls->Add(this->txtCTRL);
			this->Controls->Add(this->label14);
			this->Controls->Add(this->txtMC);
			this->Controls->Add(this->label13);
			this->Controls->Add(this->txtFF);
			this->Controls->Add(this->label12);
			this->Controls->Add(this->txtIER);
			this->Controls->Add(this->label11);
			this->Controls->Add(this->txtIS);
			this->Controls->Add(this->label10);
			this->Controls->Add(this->txtMS);
			this->Controls->Add(this->label9);
			this->Controls->Add(this->txtLS);
			this->Controls->Add(this->label8);
			this->Controls->Add(this->txtTB);
			this->Controls->Add(this->label7);
			this->Controls->Add(this->txtCM3);
			this->Controls->Add(this->label6);
			this->Controls->Add(this->txtCM2);
			this->Controls->Add(this->label5);
			this->Controls->Add(this->txtCM1);
			this->Controls->Add(this->label4);
			this->Controls->Add(this->txtCM0);
			this->Controls->Add(this->label3);
			this->Controls->Add(this->button2);
			this->Controls->Add(this->txtFromUart);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->txtToUart);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedSingle;
			this->Name = L"frmUart";
			this->Text = L"rtfSimpleUart Emulator";
			this->FormClosing += gcnew System::Windows::Forms::FormClosingEventHandler(this, &frmUart::frmUart_FormClosing);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void button2_Click(System::Object^  sender, System::EventArgs^  e) {
				 do_send = true;
			 }
private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 int dat;
			 char buf[20];
		
			 if (do_send && txtToUart->Text->Length > 0) {
 	 			 char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(txtToUart->Text->Substring(0,1));
				 txtToUart->Text = txtToUart->Text->Substring(1);
				 mut->WaitOne();
				 system1.uart1.RxPort(str[0]);
				 mut->ReleaseMutex();
			 }
			 if (txtToUart->Text->Length <= 0)
				 do_send = false;
			 mut->WaitOne();
			 dat = system1.uart1.TxPort() & 0xFF;
			 mut->ReleaseMutex();
			 buf[0] = dat;
			 buf[1] = '\0';
			 if (dat != 0xFF)
				 txtFromUart->Text = txtFromUart->Text + gcnew String(buf);
		
			 mut->WaitOne();
			 sprintf(buf, "%02X", system1.uart1.cm1);
			 txtCM1->Text = gcnew String(buf);
			 sprintf(buf, "%02X", system1.uart1.cm2);
			 txtCM2->Text = gcnew String(buf);
			 sprintf(buf, "%02X", system1.uart1.cm3);
			 txtCM3->Text = gcnew String(buf);
			 sprintf(buf, "%02X", system1.uart1.ls);
			 txtLS->Text = gcnew String(buf);
			 sprintf(buf, "%02X", system1.uart1.rb);
			 txtRB->Text = gcnew String(buf);
			 sprintf(buf, "%02X", system1.uart1.tb);
			 txtTB->Text = gcnew String(buf);
			 sprintf(buf, "%02X", system1.uart1.ier);
			 txtIER->Text = gcnew String(buf);
			 sprintf(buf, "%02X", system1.uart1.is);
			 mut->ReleaseMutex();
			 txtIS->Text = gcnew String(buf);
		 }
private: System::Void frmUart_FormClosing(System::Object^  sender, System::Windows::Forms::FormClosingEventArgs^  e) {
			 if (e->CloseReason==CloseReason::UserClosing)
				 e->Cancel = true;
		 }
};
}
