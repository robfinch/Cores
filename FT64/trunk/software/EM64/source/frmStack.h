#pragma once
#include "clsSystem.h"
#include "clsCPU.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define max(a,b)	((a) < (b) ? (b) : (a))

extern clsCPU cpu1;
extern clsSystem system1;

namespace E64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for frmStack
	/// </summary>
	public ref class frmStack : public System::Windows::Forms::Form
	{
	public:
		frmStack(void)
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
		~frmStack()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::ListBox^  listBoxSP;
	protected: 
	private: System::Windows::Forms::ListBox^  listBoxBP;
	private: System::Windows::Forms::Button^  buttonOK;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::TextBox^  textBoxSP;
	private: System::Windows::Forms::TextBox^  textBoxBP;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::ComponentModel::IContainer^  components;

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
			this->listBoxSP = (gcnew System::Windows::Forms::ListBox());
			this->listBoxBP = (gcnew System::Windows::Forms::ListBox());
			this->buttonOK = (gcnew System::Windows::Forms::Button());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->textBoxSP = (gcnew System::Windows::Forms::TextBox());
			this->textBoxBP = (gcnew System::Windows::Forms::TextBox());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->SuspendLayout();
			// 
			// listBoxSP
			// 
			this->listBoxSP->Font = (gcnew System::Drawing::Font(L"Courier New", 8.25F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->listBoxSP->FormattingEnabled = true;
			this->listBoxSP->ItemHeight = 14;
			this->listBoxSP->Location = System::Drawing::Point(13, 58);
			this->listBoxSP->Name = L"listBoxSP";
			this->listBoxSP->Size = System::Drawing::Size(288, 466);
			this->listBoxSP->TabIndex = 0;
			// 
			// listBoxBP
			// 
			this->listBoxBP->Font = (gcnew System::Drawing::Font(L"Courier New", 8.25F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->listBoxBP->FormattingEnabled = true;
			this->listBoxBP->ItemHeight = 14;
			this->listBoxBP->Location = System::Drawing::Point(321, 58);
			this->listBoxBP->Name = L"listBoxBP";
			this->listBoxBP->Size = System::Drawing::Size(288, 466);
			this->listBoxBP->TabIndex = 1;
			// 
			// buttonOK
			// 
			this->buttonOK->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->buttonOK->Location = System::Drawing::Point(533, 23);
			this->buttonOK->Name = L"buttonOK";
			this->buttonOK->Size = System::Drawing::Size(76, 23);
			this->buttonOK->TabIndex = 2;
			this->buttonOK->Text = L"OK";
			this->buttonOK->UseVisualStyleBackColor = true;
			this->buttonOK->Click += gcnew System::EventHandler(this, &frmStack::buttonOK_Click);
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(10, 9);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(103, 13);
			this->label1->TabIndex = 3;
			this->label1->Text = L"Stack Pointer Focus";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(318, 9);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(104, 13);
			this->label2->TabIndex = 4;
			this->label2->Text = L"Frame Pointer Focus";
			// 
			// textBoxSP
			// 
			this->textBoxSP->Location = System::Drawing::Point(13, 26);
			this->textBoxSP->Name = L"textBoxSP";
			this->textBoxSP->Size = System::Drawing::Size(100, 20);
			this->textBoxSP->TabIndex = 5;
			// 
			// textBoxBP
			// 
			this->textBoxBP->Location = System::Drawing::Point(321, 25);
			this->textBoxBP->Name = L"textBoxBP";
			this->textBoxBP->Size = System::Drawing::Size(100, 20);
			this->textBoxBP->TabIndex = 6;
			// 
			// timer1
			// 
			this->timer1->Enabled = true;
			this->timer1->Tick += gcnew System::EventHandler(this, &frmStack::timer1_Tick);
			// 
			// frmStack
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(627, 535);
			this->Controls->Add(this->textBoxBP);
			this->Controls->Add(this->textBoxSP);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->buttonOK);
			this->Controls->Add(this->listBoxBP);
			this->Controls->Add(this->listBoxSP);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
			this->MaximizeBox = false;
			this->Name = L"frmStack";
			this->Text = L"E64 Stack View";
			this->Load += gcnew System::EventHandler(this, &frmStack::frmStack_Load);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void frmStack_Load(System::Object^  sender, System::EventArgs^  e) {
				 UpdateForm();
			 }
private: System::Void buttonOK_Click(System::Object^  sender, System::EventArgs^  e) {
			 this->Hide();
		 }
private: void UpdateForm() {
				 __int64 nn, kk, jj;
				 char buf[40];
				 static __int64 lastSP = -1;
				 static __int64 lastBP = -1;

				 jj = 0;
				 if (lastSP != cpu1.regs[31]) {
					 sprintf(buf, "%06X", cpu1.regs[31]);
					 this->textBoxSP->Text = gcnew String(buf);
					 this->listBoxSP->Items->Clear();
				     for (nn = -128; nn < 128; nn+=8) {
						 kk = max(0,cpu1.regs[31]+nn);
						 sprintf(buf, "%s %06X: %016I64X", kk == cpu1.regs[31] ? "SP->" : "    ", (unsigned int)kk,
							 ((unsigned __int64)system1.Read(kk+4) << 32)|(unsigned __int64)system1.Read(kk));
						 this->listBoxSP->Items->Add(gcnew String(buf));
						 if (kk == cpu1.regs[31])
							 this->listBoxSP->SetSelected(jj,true);
						 lastSP = cpu1.regs[31];
						 jj++;
					 }
				 }
				 jj = 0;
				 if (lastBP != cpu1.regs[30]) {
					 sprintf(buf, "%06X", cpu1.regs[30]);
					 this->textBoxBP->Text = gcnew String(buf);
					 this->listBoxBP->Items->Clear();
					 for (nn = -128; nn < 128; nn+=8) {
						 kk = max(0,cpu1.regs[30]+nn);
						 sprintf(buf, "%s %06X: %016I64X", kk == cpu1.regs[30] ? "FP->" : "    ", (unsigned int)kk,
							 ((unsigned __int64)system1.Read(kk+4) << 32)|(unsigned __int64)system1.Read(kk));
						 this->listBoxBP->Items->Add(gcnew String(buf));
						 if (kk == cpu1.regs[30])
							 this->listBoxBP->SetSelected(jj,true);
						 lastBP = cpu1.regs[30];
						 jj++;
					 }
				 }
		 }
//private: __int64 max(__int64 a, __int64 b) {
//			 return a > b ? a : b;
//			}
private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 UpdateForm();
		 }
};
}
