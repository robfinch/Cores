#pragma once
#include <Windows.h>
#include <iostream>
#include <fstream>
#include <iomanip>
#include "stdafx.h"
#include "global.h"
#include "frmMemory.h"

namespace emu816 {

	using namespace std;
	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Runtime::InteropServices;
	using namespace System::Threading;

	/// <summary>
	/// Summary for Form1
	/// </summary>
	public ref class Form1 : public System::Windows::Forms::Form
	{
	public:
		Form1(void)
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
		~Form1()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::MenuStrip^  menuStrip1;
	protected: 
	private: System::Windows::Forms::ToolStripMenuItem^  ileToolStripMenuItem;
	private: System::Windows::Forms::TextBox^  txtAReg;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::TextBox^  txtCode;

	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::TextBox^  txtXReg;
	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::TextBox^  txtYReg;
	private: System::Windows::Forms::Label^  label4;
	private: System::Windows::Forms::TextBox^  txtSPReg;
	private: System::Windows::Forms::Label^  label5;
	private: System::Windows::Forms::TextBox^  textBox2;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::Windows::Forms::ToolStripMenuItem^  loadToolStripMenuItem;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::ToolStripMenuItem^  viewToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  memoryToolStripMenuItem;
	private: System::Windows::Forms::TextBox^  txtAddr;
	private: System::Windows::Forms::CheckBox^  chk16Acc;
	private: System::Windows::Forms::CheckBox^  chk16Ndx;
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
			this->menuStrip1 = (gcnew System::Windows::Forms::MenuStrip());
			this->ileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->loadToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->viewToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->memoryToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->txtAReg = (gcnew System::Windows::Forms::TextBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->txtCode = (gcnew System::Windows::Forms::TextBox());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->txtXReg = (gcnew System::Windows::Forms::TextBox());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->txtYReg = (gcnew System::Windows::Forms::TextBox());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->txtSPReg = (gcnew System::Windows::Forms::TextBox());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->textBox2 = (gcnew System::Windows::Forms::TextBox());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->txtAddr = (gcnew System::Windows::Forms::TextBox());
			this->chk16Acc = (gcnew System::Windows::Forms::CheckBox());
			this->chk16Ndx = (gcnew System::Windows::Forms::CheckBox());
			this->menuStrip1->SuspendLayout();
			this->SuspendLayout();
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->ileToolStripMenuItem, 
				this->viewToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(591, 24);
			this->menuStrip1->TabIndex = 0;
			this->menuStrip1->Text = L"menuStrip1";
			// 
			// ileToolStripMenuItem
			// 
			this->ileToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->loadToolStripMenuItem});
			this->ileToolStripMenuItem->Name = L"ileToolStripMenuItem";
			this->ileToolStripMenuItem->Size = System::Drawing::Size(37, 20);
			this->ileToolStripMenuItem->Text = L"&File";
			this->ileToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::ileToolStripMenuItem_Click);
			// 
			// loadToolStripMenuItem
			// 
			this->loadToolStripMenuItem->Name = L"loadToolStripMenuItem";
			this->loadToolStripMenuItem->Size = System::Drawing::Size(100, 22);
			this->loadToolStripMenuItem->Text = L"&Load";
			this->loadToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::loadToolStripMenuItem_Click);
			// 
			// viewToolStripMenuItem
			// 
			this->viewToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->memoryToolStripMenuItem});
			this->viewToolStripMenuItem->Name = L"viewToolStripMenuItem";
			this->viewToolStripMenuItem->Size = System::Drawing::Size(44, 20);
			this->viewToolStripMenuItem->Text = L"&View";
			// 
			// memoryToolStripMenuItem
			// 
			this->memoryToolStripMenuItem->Name = L"memoryToolStripMenuItem";
			this->memoryToolStripMenuItem->Size = System::Drawing::Size(119, 22);
			this->memoryToolStripMenuItem->Text = L"&Memory";
			this->memoryToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::memoryToolStripMenuItem_Click);
			// 
			// txtAReg
			// 
			this->txtAReg->Location = System::Drawing::Point(501, 75);
			this->txtAReg->Name = L"txtAReg";
			this->txtAReg->Size = System::Drawing::Size(58, 20);
			this->txtAReg->TabIndex = 1;
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(448, 82);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(17, 13);
			this->label1->TabIndex = 2;
			this->label1->Text = L".A";
			// 
			// txtCode
			// 
			this->txtCode->Location = System::Drawing::Point(36, 75);
			this->txtCode->Multiline = true;
			this->txtCode->Name = L"txtCode";
			this->txtCode->Size = System::Drawing::Size(383, 304);
			this->txtCode->TabIndex = 3;
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(448, 108);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(17, 13);
			this->label2->TabIndex = 5;
			this->label2->Text = L".X";
			// 
			// txtXReg
			// 
			this->txtXReg->Location = System::Drawing::Point(501, 101);
			this->txtXReg->Name = L"txtXReg";
			this->txtXReg->Size = System::Drawing::Size(58, 20);
			this->txtXReg->TabIndex = 4;
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(448, 134);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(17, 13);
			this->label3->TabIndex = 7;
			this->label3->Text = L".Y";
			// 
			// txtYReg
			// 
			this->txtYReg->Location = System::Drawing::Point(501, 127);
			this->txtYReg->Name = L"txtYReg";
			this->txtYReg->Size = System::Drawing::Size(58, 20);
			this->txtYReg->TabIndex = 6;
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(448, 160);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(24, 13);
			this->label4->TabIndex = 9;
			this->label4->Text = L".SP";
			// 
			// txtSPReg
			// 
			this->txtSPReg->Location = System::Drawing::Point(501, 153);
			this->txtSPReg->Name = L"txtSPReg";
			this->txtSPReg->Size = System::Drawing::Size(58, 20);
			this->txtSPReg->TabIndex = 8;
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Location = System::Drawing::Point(448, 186);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(24, 13);
			this->label5->TabIndex = 11;
			this->label5->Text = L".PC";
			// 
			// textBox2
			// 
			this->textBox2->Location = System::Drawing::Point(484, 179);
			this->textBox2->Name = L"textBox2";
			this->textBox2->Size = System::Drawing::Size(75, 20);
			this->textBox2->TabIndex = 10;
			// 
			// timer1
			// 
			this->timer1->Enabled = true;
			this->timer1->Tick += gcnew System::EventHandler(this, &Form1::timer1_Tick);
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->FileName = L"bootrom";
			this->openFileDialog1->Filter = L"Binary Files(*.bin)|*.bin|S19 Hex Files(*.s19)|*.hex|All Files (*.*)|*.*";
			// 
			// txtAddr
			// 
			this->txtAddr->Location = System::Drawing::Point(36, 49);
			this->txtAddr->Name = L"txtAddr";
			this->txtAddr->Size = System::Drawing::Size(100, 20);
			this->txtAddr->TabIndex = 12;
			this->txtAddr->TextChanged += gcnew System::EventHandler(this, &Form1::txtAddr_TextChanged);
			// 
			// chk16Acc
			// 
			this->chk16Acc->AutoSize = true;
			this->chk16Acc->Location = System::Drawing::Point(142, 51);
			this->chk16Acc->Name = L"chk16Acc";
			this->chk16Acc->Size = System::Drawing::Size(74, 17);
			this->chk16Acc->TabIndex = 13;
			this->chk16Acc->Text = L"16 bit Acc";
			this->chk16Acc->UseVisualStyleBackColor = true;
			this->chk16Acc->CheckedChanged += gcnew System::EventHandler(this, &Form1::chk16Acc_CheckedChanged);
			// 
			// chk16Ndx
			// 
			this->chk16Ndx->AutoSize = true;
			this->chk16Ndx->Location = System::Drawing::Point(222, 52);
			this->chk16Ndx->Name = L"chk16Ndx";
			this->chk16Ndx->Size = System::Drawing::Size(74, 17);
			this->chk16Ndx->TabIndex = 14;
			this->chk16Ndx->Text = L"16 bit Ndx";
			this->chk16Ndx->UseVisualStyleBackColor = true;
			// 
			// Form1
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(591, 398);
			this->Controls->Add(this->chk16Ndx);
			this->Controls->Add(this->chk16Acc);
			this->Controls->Add(this->txtAddr);
			this->Controls->Add(this->label5);
			this->Controls->Add(this->textBox2);
			this->Controls->Add(this->label4);
			this->Controls->Add(this->txtSPReg);
			this->Controls->Add(this->label3);
			this->Controls->Add(this->txtYReg);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->txtXReg);
			this->Controls->Add(this->txtCode);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->txtAReg);
			this->Controls->Add(this->menuStrip1);
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"Form1";
			this->Text = L"Form1";
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
				 disassem();
			 }
	void disassem()
	{
				 int nn;
        		char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->txtAddr->Text);

				 nn = strtoul(str,NULL,16);
		txtCode->Text = gcnew String(dasm.disassem20(nn).c_str());
	}
private: System::Void loadToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			this->openFileDialog1->ShowDialog();
			char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->openFileDialog1->FileName);
			char *strdot;
			bool openBin;

			openBin = true;
			strdot = strrchr(str, '.');
			if (strdot) {
				if (strcmp(strdot,".bin"))
					openBin = false;
			}
			if (openBin) {
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
				std::ifstream fp_in;
				fp_in.open(str,std::ios::in|std::ifstream::binary);
			  // get pointer to associated buffer object
			  std::filebuf* pbuf = fp_in.rdbuf();

			  // get file size using buffer's members
			  std::size_t size = pbuf->pubseekoff (0,fp_in.end,fp_in.in);
			  pbuf->pubseekpos (0,fp_in.in);

			  // get file data
			  pbuf->sgetn (&sys65c816.ROM[16384],16384);

			  fp_in.close();
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
			  disassem();
			}
		 }
private: System::Void ileToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void memoryToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 frmMemory^ form = gcnew frmMemory();
			 form->Show();
		 }
private: System::Void txtAddr_TextChanged(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void chk16Acc_CheckedChanged(System::Object^  sender, System::EventArgs^  e) {
			 dasm.m_bit = !this->chk16Acc->Checked;
		 }
};
}

