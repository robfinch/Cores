#pragma once
#include "stdafx.h"
extern char master_filebuf[10000000];
extern Finray::RayTracer rayTracer;

static char *msgs[100] = {
	"%d syntax error",
	"%d no errors",
	"%d Expecting a '%c'",
	"%d Bad floating point constant",
	"%d Error processing texture",
	"%d Too many symbols",
	"%d Symbol not defined",
	"%d Mismatched types",
	"%d Too many nested include files",
	"%d No viewpoint has been set",
	"%d Too many nested objects",
	"%d Non-planer rectangle (given points don't make up a rectangle)",
	"%d An assignment was expected",
	"%d Operation is illegal with given types",
	"%d The expected type was not found.",
	"%d Singular matrix found.",
	"%d Degenerate object detected."
};

namespace Finray {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for frmError
	/// </summary>
	public ref class frmError : public System::Windows::Forms::Form
	{
	public:
		frmError(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			ex = nullptr;
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmError()
		{
			if (components)
			{
				delete components;
			}
		}
	public:
		char *msg;
		Finray::FinrayException^ ex;
	private: System::Windows::Forms::Label^  label1;
	public: 
	private: System::Windows::Forms::TextBox^  textBox1;
	private: System::Windows::Forms::Button^  button1;
	private: System::Windows::Forms::TextBox^  textBox2;

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
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->textBox1 = (gcnew System::Windows::Forms::TextBox());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->textBox2 = (gcnew System::Windows::Forms::TextBox());
			this->SuspendLayout();
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(16, 16);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(29, 13);
			this->label1->TabIndex = 0;
			this->label1->Text = L"Error";
			// 
			// textBox1
			// 
			this->textBox1->AcceptsReturn = true;
			this->textBox1->Location = System::Drawing::Point(51, 16);
			this->textBox1->Multiline = true;
			this->textBox1->Name = L"textBox1";
			this->textBox1->ReadOnly = true;
			this->textBox1->Size = System::Drawing::Size(319, 118);
			this->textBox1->TabIndex = 1;
			// 
			// button1
			// 
			this->button1->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->button1->Location = System::Drawing::Point(295, 291);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(75, 23);
			this->button1->TabIndex = 2;
			this->button1->Text = L"OK";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &frmError::button1_Click);
			// 
			// textBox2
			// 
			this->textBox2->Location = System::Drawing::Point(51, 140);
			this->textBox2->Multiline = true;
			this->textBox2->Name = L"textBox2";
			this->textBox2->ReadOnly = true;
			this->textBox2->Size = System::Drawing::Size(319, 145);
			this->textBox2->TabIndex = 3;
			// 
			// frmError
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(396, 326);
			this->Controls->Add(this->textBox2);
			this->Controls->Add(this->button1);
			this->Controls->Add(this->textBox1);
			this->Controls->Add(this->label1);
			this->Name = L"frmError";
			this->Text = L"Finray - Error";
			this->Shown += gcnew System::EventHandler(this, &frmError::frmError_Shown);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void frmError_Shown(System::Object^  sender, System::EventArgs^  e) {
				 char buf[2000];
				 if (ex != nullptr) {
					sprintf_s(buf, sizeof(buf), msgs[ex->errnum], ex->errnum, ex->data);
					textBox1->Text = gcnew String(buf);
				 }
				 else if (msg) {
					textBox1->Text = gcnew String(msg);
				 }
				 sprintf_s(buf, sizeof(buf), "%.200s", rayTracer.parser.p > &master_filebuf[8] ? rayTracer.parser.p-8 : rayTracer.parser.p);
				 textBox2->Text = gcnew String(buf);
		 }
};
}
