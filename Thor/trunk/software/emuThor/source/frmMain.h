#pragma once
#include <Windows.h>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <vcclr.h>
#include <string.h>
#include <math.h>
#include "stdafx.h"
#include "frmRun.h"
#include "frmRegisters.h"
#include "frmBreakpoints.h"
#include "frmScreen.h"
#include "frmKeyboard.h"
#include "frmUart.h"
#include "fmrFreeRun.h"
#include "frmPCHistory.h"
#include "About.h"
//#include "fmrPCS.h"
#include "frmInterrupts.h"
#include "frmStack.h"
#include "frmMemory.h"

clsDisassem da;
extern clsSystem system1;
extern unsigned int breakpoints[30];
extern unsigned __int64 ibreakpoints[10];
extern bool ib_active[10];
bool isRunning;
bool quit;
bool stepout, stepover;
unsigned int step_depth, stepover_depth;
unsigned int stepoverBkpt;
unsigned int stepover_pc;
bool animate;
bool fullspeed;
bool runstop;

bool screenClosed;
bool dbgScreenClosed;
bool keyboardClosed;

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
			fullspeed = false;
			runstop = false;
			stepout = false;
			stepover = false;
			animate = false;
			isRunning = false;
			mut = gcnew Mutex(false, "emuThor");
			registersFrm = nullptr;
			memoryFrm = nullptr;
			stackFrm = nullptr;
			interruptsFrm = nullptr;
			PCHistoryFrm = nullptr;
			breakpointsFrm = nullptr;
			keyboardFrm = gcnew frmKeyboard(mut);
			     keyboardFrm->Show();
			screenClosed = false;
			dbgScreenClosed = false;
			screenFrm = gcnew frmScreen(mut, "Main Screen");
				mut->WaitOne();
			    screenFrm->pVidMem = &system1.VideoMem[0];
				screenFrm->pVidDirty = &system1.VideoMemDirty[0];
				screenFrm->which = 0;
  			    mut->ReleaseMutex();
				screenFrm->Show();
			DBGScreenFrm = gcnew frmScreen(mut, "Debug Screen");
				mut->WaitOne();
			    DBGScreenFrm->pVidMem = &system1.DBGVideoMem[0];
				DBGScreenFrm->pVidDirty = &system1.DBGVideoMemDirty[0];
				DBGScreenFrm->which = 1;
				mut->ReleaseMutex();
				DBGScreenFrm->Show();
			uartFrm = gcnew frmUart(mut);
				uartFrm->MdiParent = this;
				uartFrm->Show();
				uartFrm->WindowState = FormWindowState::Minimized;
			runFrm = gcnew frmRun(mut);
			    runFrm->MdiParent = this;
				runFrm->WindowState = FormWindowState::Maximized;
				runFrm->Show();
//			myThreadDelegate = gcnew ThreadStart(this, &frmMain::Run);
//			myThread = gcnew Thread(myThreadDelegate);			
//			myThread->Start();

//			this->SetStyle(ControlStyles::AllPaintingInWmPaint |
//			ControlStyles::Opaque, true);
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmMain()
		{
//			this->backgroundWorker1->CancelAsync();
			if (components)
			{
				delete components;
			}
			system1.quit = true;
		}
	private: System::Windows::Forms::MenuStrip^  menuStrip1;
	protected: 
	private: System::Windows::Forms::ToolStripMenuItem^  viewToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  registersToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  fileToolStripMenuItem;

	private: System::Windows::Forms::ToolStripMenuItem^  aboutToolStripMenuItem;
	private: System::Windows::Forms::ToolStrip^  toolStrip1;





	private: System::Windows::Forms::ToolStripButton^  toolStripButton6;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton7;
	private: System::Windows::Forms::ToolStripMenuItem^  loadINTELHexFIleToolStripMenuItem;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::Label^  lblChecksumError;
	private: System::Windows::Forms::ToolStripMenuItem^  memoryToolStripMenuItem;
	private: System::Windows::Forms::PictureBox^  pictureBox1;





	private: System::Windows::Forms::Label^  lblLEDS;
	private: System::Windows::Forms::ToolStripMenuItem^  breakpointsToolStripMenuItem;
	private: ThreadStart^ myThreadDelegate;
	private: Thread^ myThread;

	private: System::Windows::Forms::Timer^  timer1;



	private: System::Windows::Forms::ToolStripMenuItem^  stackToolStripMenuItem;

	private: System::Windows::Forms::ToolStripMenuItem^  pCHistoryToolStripMenuItem;
	private: System::ComponentModel::BackgroundWorker^  backgroundWorker1;
	private: Mutex^ mut;
	private: frmKeyboard^ keyboardFrm;
	private: frmScreen^ screenFrm;
	private: frmScreen^ DBGScreenFrm;
	private: frmRun^ runFrm;
	private: frmRegisters^ registersFrm;
	private: frmMemory^ memoryFrm;
	private: frmStack^ stackFrm;
	private: frmInterrupts^ interruptsFrm;
	private: frmPCHistory^ PCHistoryFrm;
	private: frmBreakpoints^ breakpointsFrm;
	private: frmUart^ uartFrm;

	private: System::Windows::Forms::ToolStripMenuItem^  keyboardToolStripMenuItem;
	private: System::Windows::Forms::Timer^  timer30;
	private: System::Windows::Forms::Timer^  timer1024;


	private: System::Windows::Forms::ToolStripMenuItem^  screenToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  debugScreenToolStripMenuItem;
private: System::Windows::Forms::ToolStripMenuItem^  runToolStripMenuItem1;
private: System::Windows::Forms::ToolStripMenuItem^  interruptsToolStripMenuItem;
private: System::Windows::Forms::ToolStripMenuItem^  uartToolStripMenuItem;
private: System::Windows::Forms::PictureBox^  pictureBox2;


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
			System::ComponentModel::ComponentResourceManager^  resources = (gcnew System::ComponentModel::ComponentResourceManager(frmMain::typeid));
			this->menuStrip1 = (gcnew System::Windows::Forms::MenuStrip());
			this->fileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->loadINTELHexFIleToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->viewToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->registersToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->memoryToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->breakpointsToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->interruptsToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stackToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->pCHistoryToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->keyboardToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->screenToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->debugScreenToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->uartToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->runToolStripMenuItem1 = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->aboutToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->toolStrip1 = (gcnew System::Windows::Forms::ToolStrip());
			this->toolStripButton6 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton7 = (gcnew System::Windows::Forms::ToolStripButton());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->lblChecksumError = (gcnew System::Windows::Forms::Label());
			this->pictureBox1 = (gcnew System::Windows::Forms::PictureBox());
			this->lblLEDS = (gcnew System::Windows::Forms::Label());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->backgroundWorker1 = (gcnew System::ComponentModel::BackgroundWorker());
			this->timer30 = (gcnew System::Windows::Forms::Timer(this->components));
			this->timer1024 = (gcnew System::Windows::Forms::Timer(this->components));
			this->pictureBox2 = (gcnew System::Windows::Forms::PictureBox());
			this->menuStrip1->SuspendLayout();
			this->toolStrip1->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox2))->BeginInit();
			this->SuspendLayout();
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(3) {this->fileToolStripMenuItem, 
				this->viewToolStripMenuItem, this->aboutToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(911, 24);
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
			// viewToolStripMenuItem
			// 
			this->viewToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(11) {this->registersToolStripMenuItem, 
				this->memoryToolStripMenuItem, this->breakpointsToolStripMenuItem, this->interruptsToolStripMenuItem, this->stackToolStripMenuItem, 
				this->pCHistoryToolStripMenuItem, this->keyboardToolStripMenuItem, this->screenToolStripMenuItem, this->debugScreenToolStripMenuItem, 
				this->uartToolStripMenuItem, this->runToolStripMenuItem1});
			this->viewToolStripMenuItem->Name = L"viewToolStripMenuItem";
			this->viewToolStripMenuItem->Size = System::Drawing::Size(44, 20);
			this->viewToolStripMenuItem->Text = L"&View";
			// 
			// registersToolStripMenuItem
			// 
			this->registersToolStripMenuItem->Name = L"registersToolStripMenuItem";
			this->registersToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->registersToolStripMenuItem->Text = L"&Registers";
			this->registersToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::registersToolStripMenuItem_Click);
			// 
			// memoryToolStripMenuItem
			// 
			this->memoryToolStripMenuItem->Name = L"memoryToolStripMenuItem";
			this->memoryToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->memoryToolStripMenuItem->Text = L"&Memory";
			this->memoryToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::memoryToolStripMenuItem_Click);
			// 
			// breakpointsToolStripMenuItem
			// 
			this->breakpointsToolStripMenuItem->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"breakpointsToolStripMenuItem.Image")));
			this->breakpointsToolStripMenuItem->Name = L"breakpointsToolStripMenuItem";
			this->breakpointsToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->breakpointsToolStripMenuItem->Text = L"&Breakpoints";
			this->breakpointsToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::breakpointsToolStripMenuItem_Click);
			// 
			// interruptsToolStripMenuItem
			// 
			this->interruptsToolStripMenuItem->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"interruptsToolStripMenuItem.Image")));
			this->interruptsToolStripMenuItem->Name = L"interruptsToolStripMenuItem";
			this->interruptsToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->interruptsToolStripMenuItem->Text = L"&Interrupts - PIC";
			this->interruptsToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::interruptsToolStripMenuItem_Click);
			// 
			// stackToolStripMenuItem
			// 
			this->stackToolStripMenuItem->Name = L"stackToolStripMenuItem";
			this->stackToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->stackToolStripMenuItem->Text = L"&Stack";
			this->stackToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::stackToolStripMenuItem_Click);
			// 
			// pCHistoryToolStripMenuItem
			// 
			this->pCHistoryToolStripMenuItem->Name = L"pCHistoryToolStripMenuItem";
			this->pCHistoryToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->pCHistoryToolStripMenuItem->Text = L"&PC History";
			this->pCHistoryToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::pCHistoryToolStripMenuItem_Click);
			// 
			// keyboardToolStripMenuItem
			// 
			this->keyboardToolStripMenuItem->Name = L"keyboardToolStripMenuItem";
			this->keyboardToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->keyboardToolStripMenuItem->Text = L"&Keyboard";
			this->keyboardToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::keyboardToolStripMenuItem_Click);
			// 
			// screenToolStripMenuItem
			// 
			this->screenToolStripMenuItem->Name = L"screenToolStripMenuItem";
			this->screenToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->screenToolStripMenuItem->Text = L"Screen";
			this->screenToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::screenToolStripMenuItem_Click);
			// 
			// debugScreenToolStripMenuItem
			// 
			this->debugScreenToolStripMenuItem->Name = L"debugScreenToolStripMenuItem";
			this->debugScreenToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->debugScreenToolStripMenuItem->Text = L"Debug Screen";
			this->debugScreenToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::debugScreenToolStripMenuItem_Click);
			// 
			// uartToolStripMenuItem
			// 
			this->uartToolStripMenuItem->Name = L"uartToolStripMenuItem";
			this->uartToolStripMenuItem->Size = System::Drawing::Size(154, 22);
			this->uartToolStripMenuItem->Text = L"&Uart";
			this->uartToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::uartToolStripMenuItem_Click);
			// 
			// runToolStripMenuItem1
			// 
			this->runToolStripMenuItem1->Name = L"runToolStripMenuItem1";
			this->runToolStripMenuItem1->Size = System::Drawing::Size(154, 22);
			this->runToolStripMenuItem1->Text = L"Run";
			this->runToolStripMenuItem1->Click += gcnew System::EventHandler(this, &frmMain::runToolStripMenuItem1_Click);
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
			this->toolStrip1->Dock = System::Windows::Forms::DockStyle::None;
			this->toolStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->toolStripButton6, 
				this->toolStripButton7});
			this->toolStrip1->Location = System::Drawing::Point(12, 32);
			this->toolStrip1->Name = L"toolStrip1";
			this->toolStrip1->Size = System::Drawing::Size(58, 25);
			this->toolStrip1->TabIndex = 1;
			this->toolStrip1->Text = L"toolStrip1";
			// 
			// toolStripButton6
			// 
			this->toolStripButton6->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton6->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton6.Image")));
			this->toolStripButton6->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton6->Name = L"toolStripButton6";
			this->toolStripButton6->Size = System::Drawing::Size(23, 22);
			this->toolStripButton6->Text = L"Interrupt";
			this->toolStripButton6->Click += gcnew System::EventHandler(this, &frmMain::toolStripButton6_Click);
			// 
			// toolStripButton7
			// 
			this->toolStripButton7->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton7->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton7.Image")));
			this->toolStripButton7->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton7->Name = L"toolStripButton7";
			this->toolStripButton7->Size = System::Drawing::Size(23, 22);
			this->toolStripButton7->Text = L"Breakpoints";
			this->toolStripButton7->Click += gcnew System::EventHandler(this, &frmMain::toolStripButton7_Click);
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
			this->lblChecksumError->Location = System::Drawing::Point(195, 655);
			this->lblChecksumError->Name = L"lblChecksumError";
			this->lblChecksumError->Size = System::Drawing::Size(35, 13);
			this->lblChecksumError->TabIndex = 2;
			this->lblChecksumError->Text = L"label1";
			// 
			// pictureBox1
			// 
			this->pictureBox1->Anchor = static_cast<System::Windows::Forms::AnchorStyles>((System::Windows::Forms::AnchorStyles::Bottom | System::Windows::Forms::AnchorStyles::Left));
			this->pictureBox1->Location = System::Drawing::Point(12, 640);
			this->pictureBox1->Name = L"pictureBox1";
			this->pictureBox1->Size = System::Drawing::Size(218, 12);
			this->pictureBox1->TabIndex = 3;
			this->pictureBox1->TabStop = false;
			this->pictureBox1->Click += gcnew System::EventHandler(this, &frmMain::pictureBox1_Click);
			this->pictureBox1->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &frmMain::pictureBox1_Paint);
			// 
			// lblLEDS
			// 
			this->lblLEDS->AutoSize = true;
			this->lblLEDS->Location = System::Drawing::Point(255, 639);
			this->lblLEDS->Name = L"lblLEDS";
			this->lblLEDS->Size = System::Drawing::Size(31, 13);
			this->lblLEDS->TabIndex = 7;
			this->lblLEDS->Text = L"0000";
			this->lblLEDS->Visible = false;
			// 
			// timer1
			// 
			this->timer1->Enabled = true;
			this->timer1->Tick += gcnew System::EventHandler(this, &frmMain::timer1_Tick);
			// 
			// timer30
			// 
			this->timer30->Tick += gcnew System::EventHandler(this, &frmMain::timer30_Tick);
			// 
			// timer1024
			// 
			this->timer1024->Tick += gcnew System::EventHandler(this, &frmMain::timer1024_Tick);
			// 
			// pictureBox2
			// 
			this->pictureBox2->Anchor = static_cast<System::Windows::Forms::AnchorStyles>((System::Windows::Forms::AnchorStyles::Bottom | System::Windows::Forms::AnchorStyles::Left));
			this->pictureBox2->Location = System::Drawing::Point(305, 631);
			this->pictureBox2->Name = L"pictureBox2";
			this->pictureBox2->Size = System::Drawing::Size(172, 38);
			this->pictureBox2->TabIndex = 9;
			this->pictureBox2->TabStop = false;
			this->pictureBox2->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &frmMain::pictureBox2_Paint);
			// 
			// frmMain
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(911, 681);
			this->Controls->Add(this->pictureBox2);
			this->Controls->Add(this->toolStrip1);
			this->Controls->Add(this->lblLEDS);
			this->Controls->Add(this->pictureBox1);
			this->Controls->Add(this->lblChecksumError);
			this->Controls->Add(this->menuStrip1);
			this->IsMdiContainer = true;
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"frmMain";
			this->Text = L"Thor ISA Emulator";
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->toolStrip1->ResumeLayout(false);
			this->toolStrip1->PerformLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox2))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion

	private: System::Void registersToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
				 if (registersFrm)
					 registersFrm->Activate();
				 else {
					 registersFrm = gcnew frmRegisters(mut);
					 registersFrm->MdiParent = this;
					 registersFrm->Show();
				 }
			 }
	private: System::Void loadINTELHexFIleToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (this->openFileDialog1->ShowDialog()  == System::Windows::Forms::DialogResult::OK ) {
				 LoadIntelHexFile();
				 if (runFrm)
					 runFrm->UpdateListBoxes();
				 }
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
				mut->WaitOne();
				system1.Write(ad, dat, 0xFF, 0);
				mut->ReleaseMutex();
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
			if (runFrm)
				runFrm->UpdateListBoxes();
			if (chksum != 0) {
				sprintf(buf2, "Checksum Error: %d", chksum);
				this->lblChecksumError->Text = gcnew String(buf2);
			}
			else
				this->lblChecksumError->Text = "Checksum OK";
			System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
		 }
private: System::Void memoryToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (memoryFrm)
				 memoryFrm->Activate();
			 else {
				 memoryFrm = gcnew frmMemory(mut);
				 memoryFrm->MdiParent = this;
				 memoryFrm->Show();
			 }
		 }
private: System::Void pictureBox1_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void pictureBox1_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
			 Graphics^ gr = e->Graphics;
			 int h = pictureBox1->ClientSize.Height;
			 int w = h;
			 int nn,kk;
			 int lds;

			 mut->WaitOne();
			 lds = system1.leds;
			 mut->ReleaseMutex();
			 for (kk= 15, nn = 0; nn < 16; nn++, kk--) {
				if (lds & (1 << kk))
					gr->FillEllipse(gcnew SolidBrush(Color::Green),System::Drawing::Rectangle(w*nn,0,w-1,h-1));
				else
					gr->FillEllipse(gcnew SolidBrush(Color::FromArgb(0xFF003000)),System::Drawing::Rectangle(w*nn,0,w-1,h-1));
			 }
		 }
private: System::Void openFileDialog1_FileOk(System::Object^  sender, System::ComponentModel::CancelEventArgs^  e) {
		 }
private: System::Void aboutToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 About^ form = gcnew About;
			 form->MdiParent = this;
			 form->Show();
		 }
private: System::Void breakpointsToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (breakpointsFrm)
				 breakpointsFrm->Activate();
			 else {
				 breakpointsFrm = gcnew frmBreakpoints(mut);
				 breakpointsFrm->MdiParent = this;
				 breakpointsFrm->Show();
			 }
		 }
private: System::Void fullSpeedToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 if (trigger30) {
				 trigger30 = false;
				 if (interval30==-1) {
					 mut->WaitOne();
					 system1.pic1.irq30Hz = true;
		  			 mut->ReleaseMutex();
				 }
				 else {
					 this->timer30->Interval = interval30;
					 this->timer30->Enabled = true;
				 }
			 }
			 if (trigger1024) {
				 trigger1024 = false;
				 if (interval1024==-1) {
					 mut->WaitOne();
					 system1.pic1.irq1024Hz = true;
		  			 mut->ReleaseMutex();
				 }
				 else {
					 this->timer1024->Interval = interval1024;
					 this->timer1024->Enabled = true;
				 }
			 }
			if (interruptsFrm)
				interruptsFrm->UpdateForm();
			 if (isRunning) {
				 if (registersFrm)
					 registersFrm->UpdateForm();
				 if (PCHistoryFrm)
					 PCHistoryFrm->UpdateForm();
				 if (stackFrm)
					 stackFrm->UpdateForm();
			 }
			 pictureBox1->Invalidate();
			 pictureBox2->Invalidate();
		 }
private: System::Void toolStripButton7_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (breakpointsFrm)
				 breakpointsFrm->Activate();
			 else {
				 breakpointsFrm = gcnew frmBreakpoints(mut);
				 breakpointsFrm->MdiParent = this;
				 breakpointsFrm->Show();
			 }
		 }
private: System::Void stackToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (stackFrm)
				 stackFrm->Activate();
			 else {
				 stackFrm = gcnew frmStack(mut);
				 stackFrm->MdiParent = this;
				 stackFrm->Show();
			 }
		 }
private: System::Void interruptToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (interruptsFrm)
				 interruptsFrm->Activate();
			 else {
				 interruptsFrm = gcnew frmInterrupts(mut);
				 interruptsFrm->MdiParent = this;
				 interruptsFrm->Show();
			 }
		 }
private: System::Void toolStripButton6_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (interruptsFrm)
				 interruptsFrm->Activate();
			 else {
				 interruptsFrm = gcnew frmInterrupts(mut);
				 interruptsFrm->MdiParent = this;
				 interruptsFrm->Show();
			 }
		 }
private: System::Void pCHistoryToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (PCHistoryFrm)
				 PCHistoryFrm->Activate();
			 else {
				 PCHistoryFrm = gcnew frmPCHistory(mut);
				 PCHistoryFrm->MdiParent = this;
				 PCHistoryFrm->Show();
			 }
		 }
private: System::Void keyboardToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			if (keyboardFrm)
				keyboardFrm->Show();
			else {
				keyboardFrm = gcnew frmKeyboard(mut);
			    keyboardFrm->Show();
			}
		 }
private: System::Void timer30_Tick(System::Object^  sender, System::EventArgs^  e) {
  			 mut->WaitOne();
			 system1.pic1.irq30Hz = true;
  			 mut->ReleaseMutex();
		 }
private: System::Void timer1024_Tick(System::Object^  sender, System::EventArgs^  e) {
  			 mut->WaitOne();
			 system1.pic1.irq1024Hz = true;
  			 mut->ReleaseMutex();
		 }
private: System::Void screenToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (screenClosed) {
				screenFrm = gcnew frmScreen(mut, "Main Screen");
  				mut->WaitOne();
			    screenFrm->pVidMem = &system1.VideoMem[0];
				screenFrm->pVidDirty = &system1.VideoMemDirty[0];
				screenFrm->which = 0;
				mut->ReleaseMutex();
				screenFrm->Show();
			 }
			 else
				 screenFrm->Activate();
		 }
private: System::Void debugScreenToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (dbgScreenClosed) {
				DBGScreenFrm = gcnew frmScreen(mut, "Debug Screen");
	  			mut->WaitOne();
				DBGScreenFrm->pVidMem = &system1.DBGVideoMem[0];
				DBGScreenFrm->pVidDirty = &system1.DBGVideoMemDirty[0];
				DBGScreenFrm->which = 1;
				mut->ReleaseMutex();
				DBGScreenFrm->Show();
			 }
			 else
				DBGScreenFrm->Activate();
		 }
private: System::Void runToolStripMenuItem1_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (runFrm == nullptr) {
				 runFrm = gcnew frmRun(mut);
				 runFrm->MdiParent = this;
				 runFrm->WindowState = FormWindowState::Maximized;
				 runFrm->Show();
			 }
			 else
				 runFrm->Activate();
		 }
private: System::Void interruptsToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (interruptsFrm)
				 interruptsFrm->Activate();
			 else {
				 interruptsFrm = gcnew frmInterrupts(mut);
				 interruptsFrm->MdiParent = this;
				 interruptsFrm->Show();
			 }
		 }
private: System::Void uartToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (uartFrm==nullptr) {
				uartFrm = gcnew frmUart(mut);
				uartFrm->MdiParent = this;
				uartFrm->Show();
			 }
			 else
				 uartFrm->Activate();
		 }
private: System::Void pictureBox2_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
			Graphics^ gr = e->Graphics;
			System::Drawing::Font^ myfont;
			std::string str;
			SolidBrush^ bkbr;
			SolidBrush^ fgbr;
			int xx,kk;
			char buf[9];
			for (xx = 0; xx < 8; xx++)
			{
				kk = (system1.sevenseg.dat >> (xx * 4)) & 0xF;
				if (kk < 10)
					buf[7-xx] = '0' + kk;
				else
					switch(kk) {
					case 10:	buf[7-xx] = 'A'; break;
					case 11:	buf[7-xx] = 'b'; break;
					case 12:	buf[7-xx] = 'C'; break;
					case 13:	buf[7-xx] = 'd'; break;
					case 14:	buf[7-xx] = 'E'; break;
					case 15:	buf[7-xx] = 'F'; break;
					}
			}
			buf[8] = '\0';
			myfont = gcnew System::Drawing::Font("Lucida Console", 24);
			bkbr = gcnew System::Drawing::SolidBrush(System::Drawing::Color::Black);
			gr->FillRectangle(bkbr,this->pictureBox2->ClientRectangle);
			fgbr = gcnew System::Drawing::SolidBrush(Color::FromArgb(0xFF3F0000));
			gr->DrawString(gcnew String("88888888"),myfont,fgbr,0,0);
			fgbr = gcnew System::Drawing::SolidBrush(Color::FromArgb(0x7FFF0000));
			gr->DrawString(gcnew String(buf),myfont,fgbr,2,2);
		 }
};
}

