#pragma once
#include "stdafx.h"
extern clsDisassem da;

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Threading;

	/// <summary>
	/// Summary for frmPCHistory
	/// </summary>
	public ref class frmPCHistory : public System::Windows::Forms::Form
	{
	public:
		frmPCHistory(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			UpdateForm();
		}
		frmPCHistory(void)
		{
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
		~frmPCHistory()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TextBox^  textBox1;
	public:	Mutex^ mut;
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
			this->SuspendLayout();
			// 
			// textBox1
			// 
			this->textBox1->Location = System::Drawing::Point(12, 47);
			this->textBox1->Multiline = true;
			this->textBox1->Name = L"textBox1";
			this->textBox1->ReadOnly = true;
			this->textBox1->ScrollBars = System::Windows::Forms::ScrollBars::Vertical;
			this->textBox1->Size = System::Drawing::Size(332, 379);
			this->textBox1->TabIndex = 0;
			// 
			// frmPCHistory
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(362, 438);
			this->Controls->Add(this->textBox1);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedSingle;
			this->Name = L"frmPCHistory";
			this->Text = L"PCHistory";
			this->FormClosing += gcnew System::Windows::Forms::FormClosingEventHandler(this, &frmPCHistory::frmPCHistory_FormClosing);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void frmPCHistory_FormClosing(System::Object^  sender, System::Windows::Forms::FormClosingEventArgs^  e) {
			 if (e->CloseReason==CloseReason::UserClosing)
				 e->Cancel = true;
			 }
	public: void UpdateForm() {
				char buf[20];
				int nb;
				String^ str = gcnew String("");
				int xx,kk;
				kk = system1.cpu2.pcsndx + 1;
				for (xx = 0; xx < 1024; xx++,  kk++) {
					kk &= 1023;
					mut->WaitOne();
					sprintf(buf, "%08I64X  ", system1.cpu2.pcs[kk]);
					mut->ReleaseMutex();
					str += gcnew String(buf);
					str += gcnew String(da.Disassem(system1.cpu2.pcs[kk],&nb).c_str());
					str += gcnew String("\r\n");
				}
				textBox1->Text = str;
			}
	};
}
