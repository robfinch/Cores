#pragma once
#include <stdio.h>
#include "clsCPU.h"

extern clsCPU cpu1;

namespace E64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for fmrPCS
	/// </summary>
	public ref class fmrPCS : public System::Windows::Forms::Form
	{
	public:
		fmrPCS(void)
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
		~fmrPCS()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::ListBox^  listBox1;
	protected: 
	private: System::Windows::Forms::Button^  button1;

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
			this->listBox1 = (gcnew System::Windows::Forms::ListBox());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->SuspendLayout();
			// 
			// listBox1
			// 
			this->listBox1->FormattingEnabled = true;
			this->listBox1->Location = System::Drawing::Point(12, 47);
			this->listBox1->Name = L"listBox1";
			this->listBox1->Size = System::Drawing::Size(82, 225);
			this->listBox1->TabIndex = 0;
			// 
			// button1
			// 
			this->button1->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->button1->Location = System::Drawing::Point(122, 249);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(75, 23);
			this->button1->TabIndex = 1;
			this->button1->Text = L"OK";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &fmrPCS::button1_Click);
			// 
			// fmrPCS
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(209, 287);
			this->Controls->Add(this->button1);
			this->Controls->Add(this->listBox1);
			this->Name = L"fmrPCS";
			this->Text = L"E64 PC History";
			this->Load += gcnew System::EventHandler(this, &fmrPCS::fmrPCS_Load);
			this->ResumeLayout(false);

		}
#pragma endregion
	private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {
				 this->Hide();
			 }
	private: System::Void fmrPCS_Load(System::Object^  sender, System::EventArgs^  e) {
				 int nn;
				 char buf[40];
			
				this->listBox1->Items->Clear();
				 for (nn = 0; nn < 40; nn++) {
					 sprintf(buf, "%06X", cpu1.pcs[nn]);
					 this->listBox1->Items->Add(gcnew String(buf));
				 }
			 }
	};
}
