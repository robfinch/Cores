#pragma once
#include <Windows.h>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <vcclr.h>
#include <string.h>
#include "frmRegisters.h"
//#include "frmBreakpoint.h"
#include "frmScreen.h"
#include "frmKeyboard.h"
#include "About.h"
//#include "fmrPCS.h"
//#include "frmInterrupts.h"
//#include "frmStack.h"
#include "frmMemory.h"
//#include "Disassem.h"
#include "clsCPU.h"
#include "clsPIC.h"
#include "clsDisassem.h"

clsDisassem da;
extern clsThor cpu1;
extern clsPIC pic1;
extern clsSystem system1;
extern unsigned int breakpoints[30];

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
	/// Summary for frmMain
	/// </summary>
	public ref class frmMain : public System::Windows::Forms::Form
	{
	public:
		frmMain(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			frmKeyboard^ keyboardFrm = gcnew frmKeyboard();
			     keyboardFrm->Show();
			frmScreen^ screenFrm = gcnew frmScreen();
				screenFrm->Show();
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmMain()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::MenuStrip^  menuStrip1;
	protected: 
	private: System::Windows::Forms::ToolStripMenuItem^  viewToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  registersToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  fileToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  runToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  aboutToolStripMenuItem;
	private: System::Windows::Forms::ToolStrip^  toolStrip1;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton1;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton2;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton3;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton4;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton5;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton6;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton7;
	private: System::Windows::Forms::ToolStripMenuItem^  loadINTELHexFIleToolStripMenuItem;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::Label^  lblChecksumError;
	private: System::Windows::Forms::ToolStripMenuItem^  memoryToolStripMenuItem;
	private: System::Windows::Forms::PictureBox^  pictureBox1;
	private: System::Windows::Forms::ListBox^  listBoxAdr;
	private: System::Windows::Forms::ListBox^  listBoxBytes;
	private: System::Windows::Forms::ListBox^  listBoxCode;
	private: System::Windows::Forms::ToolStripMenuItem^  stepToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  resetToolStripMenuItem;
	private: System::Windows::Forms::Label^  lblLEDS;

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
			System::ComponentModel::ComponentResourceManager^  resources = (gcnew System::ComponentModel::ComponentResourceManager(frmMain::typeid));
			this->menuStrip1 = (gcnew System::Windows::Forms::MenuStrip());
			this->fileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->loadINTELHexFIleToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->runToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->resetToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stepToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->viewToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->registersToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->memoryToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->aboutToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->toolStrip1 = (gcnew System::Windows::Forms::ToolStrip());
			this->toolStripButton1 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton2 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton3 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton4 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton5 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton6 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton7 = (gcnew System::Windows::Forms::ToolStripButton());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->lblChecksumError = (gcnew System::Windows::Forms::Label());
			this->pictureBox1 = (gcnew System::Windows::Forms::PictureBox());
			this->listBoxAdr = (gcnew System::Windows::Forms::ListBox());
			this->listBoxBytes = (gcnew System::Windows::Forms::ListBox());
			this->listBoxCode = (gcnew System::Windows::Forms::ListBox());
			this->lblLEDS = (gcnew System::Windows::Forms::Label());
			this->menuStrip1->SuspendLayout();
			this->toolStrip1->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->BeginInit();
			this->SuspendLayout();
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(4) {this->fileToolStripMenuItem, 
				this->runToolStripMenuItem, this->viewToolStripMenuItem, this->aboutToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(684, 24);
			this->menuStrip1->TabIndex = 0;
			this->menuStrip1->Text = L"menuStrip1";
			// 
			// fileToolStripMenuItem
			// 
			this->fileToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->loadINTELHexFIleToolStripMenuItem});
			this->fileToolStripMenuItem->Name = L"fileToolStripMenuItem";
			this->fileToolStripMenuItem->Size = System::Drawing::Size(37, 20);
			this->fileToolStripMenuItem->Text = L"&File";
			// 
			// loadINTELHexFIleToolStripMenuItem
			// 
			this->loadINTELHexFIleToolStripMenuItem->Name = L"loadINTELHexFIleToolStripMenuItem";
			this->loadINTELHexFIleToolStripMenuItem->Size = System::Drawing::Size(178, 22);
			this->loadINTELHexFIleToolStripMenuItem->Text = L"&Load INTEL Hex FIle";
			this->loadINTELHexFIleToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::loadINTELHexFIleToolStripMenuItem_Click);
			// 
			// runToolStripMenuItem
			// 
			this->runToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->resetToolStripMenuItem, 
				this->stepToolStripMenuItem});
			this->runToolStripMenuItem->Name = L"runToolStripMenuItem";
			this->runToolStripMenuItem->Size = System::Drawing::Size(40, 20);
			this->runToolStripMenuItem->Text = L"&Run";
			// 
			// resetToolStripMenuItem
			// 
			this->resetToolStripMenuItem->Name = L"resetToolStripMenuItem";
			this->resetToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->resetToolStripMenuItem->Text = L"&Reset";
			this->resetToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::resetToolStripMenuItem_Click);
			// 
			// stepToolStripMenuItem
			// 
			this->stepToolStripMenuItem->Name = L"stepToolStripMenuItem";
			this->stepToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->stepToolStripMenuItem->Text = L"&Step";
			this->stepToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::stepToolStripMenuItem_Click);
			// 
			// viewToolStripMenuItem
			// 
			this->viewToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->registersToolStripMenuItem, 
				this->memoryToolStripMenuItem});
			this->viewToolStripMenuItem->Name = L"viewToolStripMenuItem";
			this->viewToolStripMenuItem->Size = System::Drawing::Size(44, 20);
			this->viewToolStripMenuItem->Text = L"&View";
			// 
			// registersToolStripMenuItem
			// 
			this->registersToolStripMenuItem->Name = L"registersToolStripMenuItem";
			this->registersToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->registersToolStripMenuItem->Text = L"&Registers";
			this->registersToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::registersToolStripMenuItem_Click);
			// 
			// memoryToolStripMenuItem
			// 
			this->memoryToolStripMenuItem->Name = L"memoryToolStripMenuItem";
			this->memoryToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->memoryToolStripMenuItem->Text = L"&Memory";
			this->memoryToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::memoryToolStripMenuItem_Click);
			// 
			// aboutToolStripMenuItem
			// 
			this->aboutToolStripMenuItem->Name = L"aboutToolStripMenuItem";
			this->aboutToolStripMenuItem->Size = System::Drawing::Size(52, 20);
			this->aboutToolStripMenuItem->Text = L"&About";
			this->aboutToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::aboutToolStripMenuItem_Click);
			// 
			// toolStrip1
			// 
			this->toolStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(7) {this->toolStripButton1, 
				this->toolStripButton2, this->toolStripButton3, this->toolStripButton4, this->toolStripButton5, this->toolStripButton6, this->toolStripButton7});
			this->toolStrip1->Location = System::Drawing::Point(0, 24);
			this->toolStrip1->Name = L"toolStrip1";
			this->toolStrip1->Size = System::Drawing::Size(684, 25);
			this->toolStrip1->TabIndex = 1;
			this->toolStrip1->Text = L"toolStrip1";
			// 
			// toolStripButton1
			// 
			this->toolStripButton1->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton1->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton1.Image")));
			this->toolStripButton1->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton1->Name = L"toolStripButton1";
			this->toolStripButton1->Size = System::Drawing::Size(23, 22);
			this->toolStripButton1->Text = L"Step Into";
			this->toolStripButton1->Click += gcnew System::EventHandler(this, &frmMain::toolStripButton1_Click);
			// 
			// toolStripButton2
			// 
			this->toolStripButton2->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton2->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton2.Image")));
			this->toolStripButton2->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton2->Name = L"toolStripButton2";
			this->toolStripButton2->Size = System::Drawing::Size(23, 22);
			this->toolStripButton2->Text = L"Step Over (Bounce)";
			// 
			// toolStripButton3
			// 
			this->toolStripButton3->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton3->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton3.Image")));
			this->toolStripButton3->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton3->Name = L"toolStripButton3";
			this->toolStripButton3->Size = System::Drawing::Size(23, 22);
			this->toolStripButton3->Text = L"Step Out Of";
			// 
			// toolStripButton4
			// 
			this->toolStripButton4->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton4->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton4.Image")));
			this->toolStripButton4->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton4->Name = L"toolStripButton4";
			this->toolStripButton4->Size = System::Drawing::Size(23, 22);
			this->toolStripButton4->Text = L"Run";
			// 
			// toolStripButton5
			// 
			this->toolStripButton5->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton5->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton5.Image")));
			this->toolStripButton5->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton5->Name = L"toolStripButton5";
			this->toolStripButton5->Size = System::Drawing::Size(23, 22);
			this->toolStripButton5->Text = L"Stop";
			// 
			// toolStripButton6
			// 
			this->toolStripButton6->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton6->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton6.Image")));
			this->toolStripButton6->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton6->Name = L"toolStripButton6";
			this->toolStripButton6->Size = System::Drawing::Size(23, 22);
			this->toolStripButton6->Text = L"Interrupt";
			// 
			// toolStripButton7
			// 
			this->toolStripButton7->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton7->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton7.Image")));
			this->toolStripButton7->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton7->Name = L"toolStripButton7";
			this->toolStripButton7->Size = System::Drawing::Size(23, 22);
			this->toolStripButton7->Text = L"Breakpoints";
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->DefaultExt = L"hex";
			this->openFileDialog1->FileName = L"boot";
			this->openFileDialog1->Filter = L"\"INTEL Hex Files|*.hex|All Files|*.*\"";
			this->openFileDialog1->FileOk += gcnew System::ComponentModel::CancelEventHandler(this, &frmMain::openFileDialog1_FileOk);
			// 
			// lblChecksumError
			// 
			this->lblChecksumError->Anchor = static_cast<System::Windows::Forms::AnchorStyles>((System::Windows::Forms::AnchorStyles::Bottom | System::Windows::Forms::AnchorStyles::Left));
			this->lblChecksumError->AutoSize = true;
			this->lblChecksumError->Location = System::Drawing::Point(75, 522);
			this->lblChecksumError->Name = L"lblChecksumError";
			this->lblChecksumError->Size = System::Drawing::Size(35, 13);
			this->lblChecksumError->TabIndex = 2;
			this->lblChecksumError->Text = L"label1";
			// 
			// pictureBox1
			// 
			this->pictureBox1->Anchor = static_cast<System::Windows::Forms::AnchorStyles>((System::Windows::Forms::AnchorStyles::Bottom | System::Windows::Forms::AnchorStyles::Left));
			this->pictureBox1->Location = System::Drawing::Point(12, 507);
			this->pictureBox1->Name = L"pictureBox1";
			this->pictureBox1->Size = System::Drawing::Size(218, 12);
			this->pictureBox1->TabIndex = 3;
			this->pictureBox1->TabStop = false;
			this->pictureBox1->Click += gcnew System::EventHandler(this, &frmMain::pictureBox1_Click);
			this->pictureBox1->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &frmMain::pictureBox1_Paint);
			// 
			// listBoxAdr
			// 
			this->listBoxAdr->FormattingEnabled = true;
			this->listBoxAdr->Location = System::Drawing::Point(12, 52);
			this->listBoxAdr->Name = L"listBoxAdr";
			this->listBoxAdr->Size = System::Drawing::Size(71, 433);
			this->listBoxAdr->TabIndex = 4;
			// 
			// listBoxBytes
			// 
			this->listBoxBytes->FormattingEnabled = true;
			this->listBoxBytes->Location = System::Drawing::Point(89, 52);
			this->listBoxBytes->Name = L"listBoxBytes";
			this->listBoxBytes->Size = System::Drawing::Size(141, 433);
			this->listBoxBytes->TabIndex = 5;
			// 
			// listBoxCode
			// 
			this->listBoxCode->FormattingEnabled = true;
			this->listBoxCode->Location = System::Drawing::Point(236, 52);
			this->listBoxCode->Name = L"listBoxCode";
			this->listBoxCode->Size = System::Drawing::Size(327, 433);
			this->listBoxCode->TabIndex = 6;
			// 
			// lblLEDS
			// 
			this->lblLEDS->AutoSize = true;
			this->lblLEDS->Location = System::Drawing::Point(275, 507);
			this->lblLEDS->Name = L"lblLEDS";
			this->lblLEDS->Size = System::Drawing::Size(40, 13);
			this->lblLEDS->TabIndex = 7;
			this->lblLEDS->Text = L"lblLeds";
			// 
			// frmMain
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(684, 548);
			this->Controls->Add(this->lblLEDS);
			this->Controls->Add(this->listBoxCode);
			this->Controls->Add(this->listBoxBytes);
			this->Controls->Add(this->listBoxAdr);
			this->Controls->Add(this->pictureBox1);
			this->Controls->Add(this->lblChecksumError);
			this->Controls->Add(this->toolStrip1);
			this->Controls->Add(this->menuStrip1);
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"frmMain";
			this->Text = L"Thor ISA Emulator";
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->toolStrip1->ResumeLayout(false);
			this->toolStrip1->PerformLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void registersToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
				 frmRegisters^ form = gcnew frmRegisters();
				 form->Show();
			 }
	private: System::Void loadINTELHexFIleToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
	  		 this->openFileDialog1->ShowDialog();
			 LoadIntelHexFile();
			 return;
			 }

private: int IHChecksumCheck(const char *buf) {
	int nn;
	int sum;
	std::string str;
	std::string str1;
	str = std::string(buf);
	sum = 0;
	for (nn = 1; nn < str.length(); nn+=2) {
		str1 = str.substr(nn,2);
		sum += strtoul(str1.c_str(),NULL,16);
	}
	sum &= 0xff;
	return sum;
}

private: void LoadIntelHexFile() {
			 int nc,nn;
			 std::string buf;
			 std::string str_ad;
			 std::string str_insn;
			 std::string str_ad_insn;
			 std::string str_disassem;
			 unsigned int ad;
			 unsigned __int64 dat;
			 unsigned __int64 b0,b1,b2,b3,b4,b5,b6,b7;
			 unsigned int firstAdr;
			 char buf2[40];
			 unsigned int ad_msbs;
			 int chksum;
			 int lineno;	// 16531

			char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->openFileDialog1->FileName);
			System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
			std::ifstream fp_in;
			fp_in.open(str,std::ios::in);
			firstAdr = 0;
			ad_msbs = 0;
			chksum = 0;
			lineno=0;
			system1.WriteROM = true;
			while (!fp_in.eof()) {
				lineno++;
				std::getline(fp_in, buf);
				chksum += IHChecksumCheck(buf.c_str());
				if (buf.c_str()[0]!=':') continue;
				if (buf.c_str()[8]=='4') {
					strncpy(buf2,&((buf.c_str())[9]),4);
					buf2[4] = '\0';
					ad_msbs = strtoul(buf2,NULL,16);
					continue;
				}
				// Process record type #'00'
				if (buf.c_str()[8]=='0') {
					ad = strtoul(buf.substr(3,4).c_str(),NULL,16) | (ad_msbs << 16);
					b0 = strtoul(buf.substr(9,2).c_str(),NULL,16);
					b1 = strtoul(buf.substr(11,2).c_str(),NULL,16);
					b2 = strtoul(buf.substr(13,2).c_str(),NULL,16);
					b3 = strtoul(buf.substr(15,2).c_str(),NULL,16);
					b4 = strtoul(buf.substr(17,2).c_str(),NULL,16);
					b5 = strtoul(buf.substr(19,2).c_str(),NULL,16);
					b6 = strtoul(buf.substr(21,2).c_str(),NULL,16);
					b7 = strtoul(buf.substr(23,2).c_str(),NULL,16);
					dat = b0 |
						(b1 << 8) |
						(b2 << 16) |
						(b3 << 24) |
						(b4 << 32) |
						(b5 << 40) |
						(b6 << 48) |
						(b7 << 56)
						;
				}
				if (!firstAdr)
					firstAdr = ad;
				system1.Write(ad, dat, 0xFF, 0);
				//system1.memory[ad>>2] = dat;
				//sprintf(buf2,"%06X", ad);
				//str_ad = std::string(buf2);
				//sprintf(buf2,"%08X", dat);
				//str_insn = std::string(buf2);
				//str_disassem = Disassem(str_ad,str_insn);
				//str_ad_insn = str_ad + "   " + str_insn + "    " + str_disassem;
				//label1->Text = gcnew String(str_ad_insn.c_str());
				//this->checkedListBox1->Items->Add(gcnew String(str_ad_insn.c_str()));
			}
     		fp_in.close();
			system1.WriteROM = false;
			ad = firstAdr;
			UpdateListBoxes(ad);
			if (chksum != 0) {
				sprintf(buf2, "Checksum Error: %d", chksum);
				this->lblChecksumError->Text = gcnew String(buf2);
			}
			else
				this->lblChecksumError->Text = "Checksum OK";
			System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
		 }
private: System::Void memoryToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 frmMemory^ form = gcnew frmMemory;
			 form->Show();
		 }
private: System::Void pictureBox1_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void pictureBox1_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
			 Graphics^ gr = e->Graphics;
			 int h = pictureBox1->ClientSize.Height;
			 int w = h;
			 int nn,kk;
			 for (kk= 15, nn = 0; nn < 16; nn++, kk--) {
				if (system1.leds & (1 << kk))
					gr->FillEllipse(gcnew SolidBrush(Color::Green),System::Drawing::Rectangle(w*nn,0,w-1,h-1));
				else
					gr->FillEllipse(gcnew SolidBrush(Color::FromArgb(0xFF003000)),System::Drawing::Rectangle(w*nn,0,w-1,h-1));
			 }
		 }
private: void UpdateListBoxes(int ad)
		 {
			 int nn,nb,kk;
			 char buf2[100];
			 std::string dstr;
			 std::string buf;
			 int adr[32];

			 listBoxAdr->Items->Clear();
			 listBoxBytes->Items->Clear();
			 listBoxCode->Items->Clear();
			 for (nn = 0; nn < 32; nn++) {
				 adr[nn] = ad;
				sprintf(buf2,"%06X", ad);
				buf = std::string(buf2);
				this->listBoxAdr->Items->Add(gcnew String(buf.c_str()));
				dstr = da.Disassem(ad,&nb);
				buf2[0] = '\0';
				for (kk = 0; kk < nb; kk++) {
					sprintf(&buf2[strlen(buf2)], "%02X ", system1.ReadByte(ad));
					ad++;
				}
				buf = std::string(buf2);
				this->listBoxBytes->Items->Add(gcnew String(buf.c_str()));
				this->listBoxCode->Items->Add(gcnew String(dstr.c_str()));
			 }
			 for (nn = 0; nn < 32; nn++) {
				if (adr[nn]==cpu1.pc) {
					this->listBoxAdr->SetSelected(nn,true);
					this->listBoxBytes->SetSelected(nn,true);
					this->listBoxCode->SetSelected(nn,true);
				}
			 }
		 }
private: System::Void stepToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void resetToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 Reset();
		 }
private: void Reset() {
			 system1.Reset();
			 pic1.Reset();
			 cpu1.Reset();
			 UpdateListBoxes(PCIsInList(cpu1.pc-32));
		 }

// Try and align the disassembled code with the current PC.
private: int PCIsInList(int as)
{
	int nn, nb;
	std::string dstr;
	int ae;
	int ad = as;

	for (ad = as; ad > as-32; ad--) {
		ae = ad;
		for (nn = 0; nn < 64; nn++) {
			if (ae==cpu1.pc)
				return ad;
		dstr = da.Disassem(ae,&nb);
		ae += nb;
		}
	}
	return as;
}

private: void DoStepInto() {
//		 	 animate = false;
//			 isRunning = false;
			 char buf[100];
			 cpu1.Step();
			 pic1.Step();
			 UpdateListBoxes(PCIsInList(cpu1.pc-32));
			 sprintf(buf, "%04X", system1.leds);
			 lblLEDS->Text = gcnew String(buf);
			 pictureBox1->Refresh();
		 }
private: System::Void toolStripButton1_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepInto();
		 }
private: System::Void openFileDialog1_FileOk(System::Object^  sender, System::ComponentModel::CancelEventArgs^  e) {
		 }
private: System::Void aboutToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 About^ form = gcnew About;
			 form->Show();
		 }
};
}

