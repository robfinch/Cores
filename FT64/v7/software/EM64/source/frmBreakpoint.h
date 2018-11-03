#pragma once
#include <string>
#include <string.h>
#include <stdio.h>

extern unsigned int breakpoints[30];
extern int numBreakpoints;
extern unsigned int dataBreakpoints[30];
extern int numDataBreakpoints;
extern int runstop;

namespace E64 {

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
	private: System::Windows::Forms::TextBox^  textBoxDataBrkpt;
	private: System::Windows::Forms::ListBox^  listBoxDataBrkpts;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;

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
			this->textBoxDataBrkpt = (gcnew System::Windows::Forms::TextBox());
			this->listBoxDataBrkpts = (gcnew System::Windows::Forms::ListBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->SuspendLayout();
			// 
			// textBoxBrkpt
			// 
			this->textBoxBrkpt->Location = System::Drawing::Point(12, 37);
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
			this->btnAdd->Location = System::Drawing::Point(253, 20);
			this->btnAdd->Name = L"btnAdd";
			this->btnAdd->Size = System::Drawing::Size(75, 23);
			this->btnAdd->TabIndex = 2;
			this->btnAdd->Text = L"Add";
			this->btnAdd->UseVisualStyleBackColor = true;
			this->btnAdd->Click += gcnew System::EventHandler(this, &frmBreakpoint::btnAdd_Click);
			// 
			// btnRemove
			// 
			this->btnRemove->Location = System::Drawing::Point(253, 49);
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
			this->button3->Location = System::Drawing::Point(253, 254);
			this->button3->Name = L"button3";
			this->button3->Size = System::Drawing::Size(75, 23);
			this->button3->TabIndex = 4;
			this->button3->Text = L"OK";
			this->button3->UseVisualStyleBackColor = true;
			this->button3->Click += gcnew System::EventHandler(this, &frmBreakpoint::button3_Click);
			// 
			// textBoxDataBrkpt
			// 
			this->textBoxDataBrkpt->Location = System::Drawing::Point(133, 37);
			this->textBoxDataBrkpt->Name = L"textBoxDataBrkpt";
			this->textBoxDataBrkpt->Size = System::Drawing::Size(100, 20);
			this->textBoxDataBrkpt->TabIndex = 5;
			// 
			// listBoxDataBrkpts
			// 
			this->listBoxDataBrkpts->FormattingEnabled = true;
			this->listBoxDataBrkpts->Location = System::Drawing::Point(133, 63);
			this->listBoxDataBrkpts->Name = L"listBoxDataBrkpts";
			this->listBoxDataBrkpts->Size = System::Drawing::Size(100, 212);
			this->listBoxDataBrkpts->TabIndex = 6;
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(12, 20);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(61, 13);
			this->label1->TabIndex = 7;
			this->label1->Text = L"Instructions";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(130, 20);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(30, 13);
			this->label2->TabIndex = 8;
			this->label2->Text = L"Data";
			this->label2->Click += gcnew System::EventHandler(this, &frmBreakpoint::label2_Click);
			// 
			// frmBreakpoint
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(340, 296);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->listBoxDataBrkpts);
			this->Controls->Add(this->textBoxDataBrkpt);
			this->Controls->Add(this->button3);
			this->Controls->Add(this->btnRemove);
			this->Controls->Add(this->btnAdd);
			this->Controls->Add(this->listBoxBrkpts);
			this->Controls->Add(this->textBoxBrkpt);
			this->Name = L"frmBreakpoint";
			this->Text = L"E64 Breakpoints";
			this->Load += gcnew System::EventHandler(this, &frmBreakpoint::frmBreakpoint_Load);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void btnAdd_Click(System::Object^  sender, System::EventArgs^  e) {
				 char* str2 = (char*)(void*)Marshal::StringToHGlobalAnsi(this->textBoxBrkpt->Text);
				 char buf[20];
				 int kk;
				 long bp;

				 std::string str;
				 bp = strtoul(str2,0,16);
				 if (bp > 0) {
					 if (numBreakpoints < 30) {
						 breakpoints[numBreakpoints] = bp;
						 numBreakpoints++;
					 }
					 this->listBoxBrkpts->Items->Clear();
					 for (kk = 0; kk < numBreakpoints; kk++) {
						 sprintf(buf, "%06X", breakpoints[kk]);
						 str = std::string(buf);
						 this->listBoxBrkpts->Items->Add(gcnew String(str.c_str()));
					 }
				 }
				 str2 = (char*)(void*)Marshal::StringToHGlobalAnsi(this->textBoxDataBrkpt->Text);
				 bp = strtoul(str2,0,16);
				 if (bp > 0) {
					 if (numDataBreakpoints < 30) {
						 dataBreakpoints[numDataBreakpoints] = bp;
						 numDataBreakpoints++;
					 }
					 this->listBoxBrkpts->Items->Clear();
					 for (kk = 0; kk < numDataBreakpoints; kk++) {
						 sprintf(buf, "%06X", dataBreakpoints[kk]);
						 str = std::string(buf);
						 this->listBoxDataBrkpts->Items->Add(gcnew String(str.c_str()));
					 }
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
			 this->listBoxDataBrkpts->Items->Clear();
			 for (kk = 0; kk < numDataBreakpoints; kk++) {
				 sprintf(buf, "%06X", dataBreakpoints[kk]);
				 str = std::string(buf);
				 this->listBoxDataBrkpts->Items->Add(gcnew String(str.c_str()));
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

			 str2 = (char*)(void*)Marshal::StringToHGlobalAnsi(this->textBoxDataBrkpt->Text);
			 bkp = strtoul(str2,0,16);
			 for (kk = 0; kk < numDataBreakpoints; kk++) {
				 if (bkp==dataBreakpoints[kk]) {
					 for (jj = kk +1; jj < 30; jj++)
						 dataBreakpoints[jj-1] = dataBreakpoints[jj];
					 break;
				 }
			 }
			 dataBreakpoints[29] = 0;
			 numDataBreakpoints--;
			 this->listBoxDataBrkpts->Items->Clear();
			 for (kk = 0; kk < numDataBreakpoints; kk++) {
				 sprintf(buf, "%06X", dataBreakpoints[kk]);
				 str = std::string(buf);
				 this->listBoxDataBrkpts->Items->Add(gcnew String(str.c_str()));
			 }

		 }
private: System::Void button3_Click(System::Object^  sender, System::EventArgs^  e) {
			 this->Hide();
		 }
private: System::Void label2_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
};
}
