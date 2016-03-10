#pragma once
#include "stdafx.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <string>

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
	/// Summary for frmMemory
	/// </summary>
	public ref class frmMemory : public System::Windows::Forms::Form
	{
	public:
		Mutex^ mut;
		frmMemory(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmMemory()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TextBox^  textBoxAddr;
	protected: 

	protected: 
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::TextBox^  textBoxMem;

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
			this->textBoxAddr = (gcnew System::Windows::Forms::TextBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->textBoxMem = (gcnew System::Windows::Forms::TextBox());
			this->SuspendLayout();
			// 
			// textBoxAddr
			// 
			this->textBoxAddr->Location = System::Drawing::Point(75, 18);
			this->textBoxAddr->Name = L"textBoxAddr";
			this->textBoxAddr->Size = System::Drawing::Size(100, 20);
			this->textBoxAddr->TabIndex = 0;
			this->textBoxAddr->TextChanged += gcnew System::EventHandler(this, &frmMemory::textBox1_TextChanged);
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(24, 21);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(45, 13);
			this->label1->TabIndex = 1;
			this->label1->Text = L"Address";
			// 
			// textBoxMem
			// 
			this->textBoxMem->Enabled = false;
			this->textBoxMem->Font = (gcnew System::Drawing::Font(L"Lucida Console", 8.25F, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textBoxMem->Location = System::Drawing::Point(27, 44);
			this->textBoxMem->Multiline = true;
			this->textBoxMem->Name = L"textBoxMem";
			this->textBoxMem->Size = System::Drawing::Size(561, 353);
			this->textBoxMem->TabIndex = 2;
			// 
			// frmMemory
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(614, 409);
			this->Controls->Add(this->textBoxMem);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->textBoxAddr);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
			this->Name = L"frmMemory";
			this->Text = L"Memory";
			this->FormClosing += gcnew System::Windows::Forms::FormClosingEventHandler(this, &frmMemory::frmMemory_FormClosing);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void textBox1_TextChanged(System::Object^  sender, System::EventArgs^  e) {
				 int nn;
        		char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->textBoxAddr->Text);
				std::string str2;
				char buf[50];

				str2 = "";
				 for (nn = strtoul(str,NULL,16); nn < strtoul(str,NULL,16) + 512; nn++) {
					 if ((nn % 16)==0) {
						 sprintf(buf, "\r\n%06X ", nn);
						 str2 += buf;
					 }
					 mut->WaitOne();
					 sprintf(buf, "%02X ", (system1.Read(nn,0) >> ((nn & 7)<<3)) & 0xFF);
					 mut->ReleaseMutex();
					 str2 += buf;
				 }
				 this->textBoxMem->Text = gcnew String(str2.c_str());
			 }
private: System::Void frmMemory_FormClosing(System::Object^  sender, System::Windows::Forms::FormClosingEventArgs^  e) {
			 if (e->CloseReason==CloseReason::UserClosing)
				 e->Cancel = true;
		 }
	};
}
