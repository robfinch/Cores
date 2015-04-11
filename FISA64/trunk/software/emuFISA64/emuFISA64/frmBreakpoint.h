#pragma once
#include <string>
#include <string.h>
#include <stdio.h>

extern unsigned int breakpoints[30];
extern int numBreakpoints;

namespace emuFISA64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Runtime::InteropServices;

	/// <summary>
	/// Summary for frmBreakpoint
	/// </summary>
	public ref class frmBreakpoint : public System::Windows::Forms::Form
	{
	public:
		frmBreakpoint(void)
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
		~frmBreakpoint()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TextBox^  textBoxBrkpt;
	protected: 
	private: System::Windows::Forms::ListBox^  listBoxBrkpts;
	private: System::Windows::Forms::Button^  btnAdd;
	private: System::Windows::Forms::Button^  btnRemove;


	private: System::Windows::Forms::Button^  button3;

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
			this->textBoxBrkpt = (gcnew System::Windows::Forms::TextBox());
			this->listBoxBrkpts = (gcnew System::Windows::Forms::ListBox());
			this->btnAdd = (gcnew System::Windows::Forms::Button());
			this->btnRemove = (gcnew System::Windows::Forms::Button());
			this->button3 = (gcnew System::Windows::Forms::Button());
			this->SuspendLayout();
			// 
			// textBoxBrkpt
			// 
			this->textBoxBrkpt->Location = System::Drawing::Point(12, 22);
			this->textBoxBrkpt->Name = L"textBoxBrkpt";
			this->textBoxBrkpt->Size = System::Drawing::Size(100, 20);
			this->textBoxBrkpt->TabIndex = 0;
			// 
			// listBoxBrkpts
			// 
			this->listBoxBrkpts->FormattingEnabled = true;
			this->listBoxBrkpts->Location = System::Drawing::Point(12, 63);
			this->listBoxBrkpts->Name = L"listBoxBrkpts";
			this->listBoxBrkpts->Size = System::Drawing::Size(100, 212);
			this->listBoxBrkpts->TabIndex = 1;
			// 
			// btnAdd
			// 
			this->btnAdd->Location = System::Drawing::Point(140, 18);
			this->btnAdd->Name = L"btnAdd";
			this->btnAdd->Size = System::Drawing::Size(75, 23);
			this->btnAdd->TabIndex = 2;
			this->btnAdd->Text = L"Add";
			this->btnAdd->UseVisualStyleBackColor = true;
			this->btnAdd->Click += gcnew System::EventHandler(this, &frmBreakpoint::btnAdd_Click);
			// 
			// btnRemove
			// 
			this->btnRemove->Location = System::Drawing::Point(140, 47);
			this->btnRemove->Name = L"btnRemove";
			this->btnRemove->Size = System::Drawing::Size(75, 23);
			this->btnRemove->TabIndex = 3;
			this->btnRemove->Text = L"Remove";
			this->btnRemove->UseVisualStyleBackColor = true;
			this->btnRemove->Click += gcnew System::EventHandler(this, &frmBreakpoint::btnRemove_Click);
			// 
			// button3
			// 
			this->button3->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->button3->Location = System::Drawing::Point(140, 252);
			this->button3->Name = L"button3";
			this->button3->Size = System::Drawing::Size(75, 23);
			this->button3->TabIndex = 4;
			this->button3->Text = L"OK";
			this->button3->UseVisualStyleBackColor = true;
			this->button3->Click += gcnew System::EventHandler(this, &frmBreakpoint::button3_Click);
			// 
			// frmBreakpoint
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(229, 296);
			this->Controls->Add(this->button3);
			this->Controls->Add(this->btnRemove);
			this->Controls->Add(this->btnAdd);
			this->Controls->Add(this->listBoxBrkpts);
			this->Controls->Add(this->textBoxBrkpt);
			this->Name = L"frmBreakpoint";
			this->Text = L"Breakpoints";
			this->Load += gcnew System::EventHandler(this, &frmBreakpoint::frmBreakpoint_Load);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void btnAdd_Click(System::Object^  sender, System::EventArgs^  e) {
				 char* str2 = (char*)(void*)Marshal::StringToHGlobalAnsi(this->textBoxBrkpt->Text);
				 char buf[20];
				 int kk;
				 std::string str;
				 if (numBreakpoints < 30) {
					 breakpoints[numBreakpoints] = strtoul(str2,0,16);
					 numBreakpoints++;
				 }
				 this->listBoxBrkpts->Items->Clear();
				 for (kk = 0; kk < numBreakpoints; kk++) {
					 sprintf(buf, "%06X", breakpoints[kk]);
					 str = std::string(buf);
					 this->listBoxBrkpts->Items->Add(gcnew String(str.c_str()));
				 }
			 }
private: System::Void frmBreakpoint_Load(System::Object^  sender, System::EventArgs^  e) {
			 char buf[20];
			 int kk;
			 std::string str;

			 this->listBoxBrkpts->Items->Clear();
			 for (kk = 0; kk < numBreakpoints; kk++) {
				 sprintf(buf, "%06X", breakpoints[kk]);
				 str = std::string(buf);
				 this->listBoxBrkpts->Items->Add(gcnew String(str.c_str()));
			 }
			 
		 }
private: System::Void btnRemove_Click(System::Object^  sender, System::EventArgs^  e) {
				 char* str2 = (char*)(void*)Marshal::StringToHGlobalAnsi(this->textBoxBrkpt->Text);
			 char buf[20];
			 int kk,jj;
			 std::string str;
			 int bkp = strtoul(str2,0,16);

			 for (kk = 0; kk < numBreakpoints; kk++) {
				 if (bkp==breakpoints[kk]) {
					 for (jj = kk +1; jj < 30; jj++)
						 breakpoints[jj-1] = breakpoints[jj];
					 break;
				 }
			 }
			 breakpoints[29] = 0;
			 numBreakpoints--;
			 this->listBoxBrkpts->Items->Clear();
			 for (kk = 0; kk < numBreakpoints; kk++) {
				 sprintf(buf, "%06X", breakpoints[kk]);
				 str = std::string(buf);
				 this->listBoxBrkpts->Items->Add(gcnew String(str.c_str()));
			 }
		 }
private: System::Void button3_Click(System::Object^  sender, System::EventArgs^  e) {
			 this->Hide();
		 }
};
}
