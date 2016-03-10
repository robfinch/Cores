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
	using namespace System::Threading;

	/// <summary>
	/// Summary for frmStack
	/// </summary>
	public ref class frmStack : public System::Windows::Forms::Form
	{
	public:
		Mutex^ mut;
		frmStack(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			UpdateForm();
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
	private: System::Windows::Forms::TextBox^  textBox1;
	private: System::Windows::Forms::TextBox^  textBox2;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;
	protected: 

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
			this->textBox1 = (gcnew System::Windows::Forms::TextBox());
			this->textBox2 = (gcnew System::Windows::Forms::TextBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->SuspendLayout();
			// 
			// textBox1
			// 
			this->textBox1->Location = System::Drawing::Point(12, 72);
			this->textBox1->Multiline = true;
			this->textBox1->Name = L"textBox1";
			this->textBox1->ScrollBars = System::Windows::Forms::ScrollBars::Vertical;
			this->textBox1->Size = System::Drawing::Size(228, 432);
			this->textBox1->TabIndex = 0;
			// 
			// textBox2
			// 
			this->textBox2->Location = System::Drawing::Point(254, 72);
			this->textBox2->Multiline = true;
			this->textBox2->Name = L"textBox2";
			this->textBox2->ScrollBars = System::Windows::Forms::ScrollBars::Vertical;
			this->textBox2->Size = System::Drawing::Size(228, 432);
			this->textBox2->TabIndex = 1;
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(9, 56);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(61, 13);
			this->label1->TabIndex = 2;
			this->label1->Text = L"Stack View";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(251, 56);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(93, 13);
			this->label2->TabIndex = 3;
			this->label2->Text = L"Base Pointer View";
			// 
			// frmStack
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(506, 516);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->textBox2);
			this->Controls->Add(this->textBox1);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedSingle;
			this->Name = L"frmStack";
			this->Text = L"emuThor - Stack View";
			this->FormClosing += gcnew System::Windows::Forms::FormClosingEventHandler(this, &frmStack::frmStack_FormClosing);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void frmStack_FormClosing(System::Object^  sender, System::Windows::Forms::FormClosingEventArgs^  e) {
			 if (e->CloseReason==CloseReason::UserClosing)
				 e->Cancel = true;
			 }
	public: void UpdateForm() {
				int xx;
				char buf[4000];
				buf[0] = '\0';
				mut->WaitOne();
				for (xx = -128; xx < 128; xx+=8) {
					sprintf(&buf[strlen(buf)], "%c %08I64X: %016I64X\r\n", xx==0 ? '>' : ' ',
						system1.cpu2.GetGP(27)+xx, system1.Read(system1.cpu2.GetGP(27)+xx));
				}
				textBox1->Text = gcnew String(buf);
				buf[0] = '\0';
				for (xx = -128; xx < 128; xx+=8) {
					sprintf(&buf[strlen(buf)], "%c %08I64X: %016I64X\r\n", xx==0 ? '>' : ' ',
						system1.cpu2.GetGP(26)+xx, system1.Read(system1.cpu2.GetGP(26)+xx));
				}
				mut->ReleaseMutex();
				textBox2->Text = gcnew String(buf);
			}
};
}
