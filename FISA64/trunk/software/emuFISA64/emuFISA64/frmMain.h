#pragma once
#include <Windows.h>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <vcclr.h>
#include <string.h>
#include "frmRegisters.h"
#include "frmBreakpoint.h"
#include "frmScreen.h"
#include "Disassem.h"
#include "clsCPU.h"

extern clsCPU cpu1;
extern clsSystem system1;
extern unsigned int breakpoints[30];

namespace emuFISA64 {
	using namespace std;
	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Runtime::InteropServices;

	/// <summary>
	/// Summary for frmMain
	/// </summary>
	public ref class frmMain : public System::Windows::Forms::Form
	{
		int fullspeed;
	public:
		frmMain(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			fullspeed = false;
			frmScreen^ Screenform = gcnew frmScreen();
				 Screenform->Show();
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

	protected: 
	private: System::Windows::Forms::MenuStrip^  menuStrip1;
	private: System::Windows::Forms::ToolStripMenuItem^  fileToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  loadToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  runToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  viewToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  registersToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  aboutToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  stepIntoToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  stepOverToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  stepOutToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  freeRunToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  stopToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  interruptToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  breakpointToolStripMenuItem;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::ToolStrip^  toolStrip1;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton1;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton2;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton3;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton4;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton5;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton6;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton7;
	private: System::Windows::Forms::ToolStripMenuItem^  resetToolStripMenuItem;

	private: System::Windows::Forms::ListBox^  listBoxAdr;
	private: System::Windows::Forms::ListBox^  listBoxCode;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::Windows::Forms::ListBox^  listBoxBytes;
	private: System::Windows::Forms::Label^  label7;
	private: System::Windows::Forms::Label^  label6;
	private: System::Windows::Forms::Label^  label5;
	private: System::Windows::Forms::Label^  label4;
	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Label^  label8;
	private: System::Windows::Forms::Label^  lblR0;
	private: System::Windows::Forms::TextBox^  textR7;
	private: System::Windows::Forms::TextBox^  textR6;
	private: System::Windows::Forms::TextBox^  textR5;
	private: System::Windows::Forms::TextBox^  textR4;
	private: System::Windows::Forms::TextBox^  textR3;
	private: System::Windows::Forms::TextBox^  textR2;
	private: System::Windows::Forms::TextBox^  textR1;
	private: System::Windows::Forms::TextBox^  textR0;
	private: System::Windows::Forms::Label^  label15;
	private: System::Windows::Forms::Label^  label14;
	private: System::Windows::Forms::Label^  label13;
	private: System::Windows::Forms::Label^  label12;
	private: System::Windows::Forms::Label^  label11;
	private: System::Windows::Forms::Label^  label10;
	private: System::Windows::Forms::Label^  label9;
	private: System::Windows::Forms::Label^  label16;
	private: System::Windows::Forms::TextBox^  textR15;
	private: System::Windows::Forms::TextBox^  textR14;
	private: System::Windows::Forms::TextBox^  textR13;
	private: System::Windows::Forms::TextBox^  textR12;
	private: System::Windows::Forms::TextBox^  textR11;
	private: System::Windows::Forms::TextBox^  textR10;
	private: System::Windows::Forms::TextBox^  textR9;
	private: System::Windows::Forms::TextBox^  textR8;
	private: System::Windows::Forms::Label^  label23;
	private: System::Windows::Forms::Label^  label22;
	private: System::Windows::Forms::Label^  label21;
	private: System::Windows::Forms::Label^  label20;
	private: System::Windows::Forms::Label^  label19;
	private: System::Windows::Forms::Label^  label18;
	private: System::Windows::Forms::Label^  label17;
	private: System::Windows::Forms::Label^  label24;
	private: System::Windows::Forms::TextBox^  textR23;
	private: System::Windows::Forms::TextBox^  textR22;
	private: System::Windows::Forms::TextBox^  textR21;
	private: System::Windows::Forms::TextBox^  textR20;
	private: System::Windows::Forms::TextBox^  textR19;
	private: System::Windows::Forms::TextBox^  textR18;
	private: System::Windows::Forms::TextBox^  textR17;
	private: System::Windows::Forms::TextBox^  textR16;
private: System::Windows::Forms::Label^  label31;
private: System::Windows::Forms::Label^  label30;
private: System::Windows::Forms::Label^  label29;
private: System::Windows::Forms::Label^  label28;
private: System::Windows::Forms::Label^  label27;
private: System::Windows::Forms::Label^  label26;
private: System::Windows::Forms::Label^  label25;
private: System::Windows::Forms::Label^  label32;
private: System::Windows::Forms::TextBox^  textR31;
private: System::Windows::Forms::TextBox^  textR30;
private: System::Windows::Forms::TextBox^  textR29;
private: System::Windows::Forms::TextBox^  textR28;
private: System::Windows::Forms::TextBox^  textR27;
private: System::Windows::Forms::TextBox^  textR26;
private: System::Windows::Forms::TextBox^  textR25;
private: System::Windows::Forms::TextBox^  textR24;
private: System::Windows::Forms::Label^  label35;
private: System::Windows::Forms::Label^  label34;
private: System::Windows::Forms::Label^  label33;
private: System::Windows::Forms::Label^  label36;
private: System::Windows::Forms::TextBox^  textEPC;
private: System::Windows::Forms::TextBox^  textDPC;
private: System::Windows::Forms::TextBox^  textIPC;
private: System::Windows::Forms::TextBox^  textPC;
private: System::Windows::Forms::Label^  label38;
private: System::Windows::Forms::Label^  label37;
private: System::Windows::Forms::Label^  label39;
private: System::Windows::Forms::TextBox^  textESP;
private: System::Windows::Forms::TextBox^  textDSP;
private: System::Windows::Forms::TextBox^  textISP;
private: System::Windows::Forms::ToolStripMenuItem^  freeRunFastToolStripMenuItem;
private: System::Windows::Forms::ToolStripMenuItem^  fullSpeedToolStripMenuItem;
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
			this->loadToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->runToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->resetToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stepIntoToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stepOverToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stepOutToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->freeRunToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stopToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->interruptToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->breakpointToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->freeRunFastToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->viewToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->registersToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->aboutToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->toolStrip1 = (gcnew System::Windows::Forms::ToolStrip());
			this->toolStripButton1 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton2 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton3 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton4 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton5 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton6 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton7 = (gcnew System::Windows::Forms::ToolStripButton());
			this->listBoxAdr = (gcnew System::Windows::Forms::ListBox());
			this->listBoxCode = (gcnew System::Windows::Forms::ListBox());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->listBoxBytes = (gcnew System::Windows::Forms::ListBox());
			this->label7 = (gcnew System::Windows::Forms::Label());
			this->label6 = (gcnew System::Windows::Forms::Label());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->label8 = (gcnew System::Windows::Forms::Label());
			this->lblR0 = (gcnew System::Windows::Forms::Label());
			this->textR7 = (gcnew System::Windows::Forms::TextBox());
			this->textR6 = (gcnew System::Windows::Forms::TextBox());
			this->textR5 = (gcnew System::Windows::Forms::TextBox());
			this->textR4 = (gcnew System::Windows::Forms::TextBox());
			this->textR3 = (gcnew System::Windows::Forms::TextBox());
			this->textR2 = (gcnew System::Windows::Forms::TextBox());
			this->textR1 = (gcnew System::Windows::Forms::TextBox());
			this->textR0 = (gcnew System::Windows::Forms::TextBox());
			this->label15 = (gcnew System::Windows::Forms::Label());
			this->label14 = (gcnew System::Windows::Forms::Label());
			this->label13 = (gcnew System::Windows::Forms::Label());
			this->label12 = (gcnew System::Windows::Forms::Label());
			this->label11 = (gcnew System::Windows::Forms::Label());
			this->label10 = (gcnew System::Windows::Forms::Label());
			this->label9 = (gcnew System::Windows::Forms::Label());
			this->label16 = (gcnew System::Windows::Forms::Label());
			this->textR15 = (gcnew System::Windows::Forms::TextBox());
			this->textR14 = (gcnew System::Windows::Forms::TextBox());
			this->textR13 = (gcnew System::Windows::Forms::TextBox());
			this->textR12 = (gcnew System::Windows::Forms::TextBox());
			this->textR11 = (gcnew System::Windows::Forms::TextBox());
			this->textR10 = (gcnew System::Windows::Forms::TextBox());
			this->textR9 = (gcnew System::Windows::Forms::TextBox());
			this->textR8 = (gcnew System::Windows::Forms::TextBox());
			this->label23 = (gcnew System::Windows::Forms::Label());
			this->label22 = (gcnew System::Windows::Forms::Label());
			this->label21 = (gcnew System::Windows::Forms::Label());
			this->label20 = (gcnew System::Windows::Forms::Label());
			this->label19 = (gcnew System::Windows::Forms::Label());
			this->label18 = (gcnew System::Windows::Forms::Label());
			this->label17 = (gcnew System::Windows::Forms::Label());
			this->label24 = (gcnew System::Windows::Forms::Label());
			this->textR23 = (gcnew System::Windows::Forms::TextBox());
			this->textR22 = (gcnew System::Windows::Forms::TextBox());
			this->textR21 = (gcnew System::Windows::Forms::TextBox());
			this->textR20 = (gcnew System::Windows::Forms::TextBox());
			this->textR19 = (gcnew System::Windows::Forms::TextBox());
			this->textR18 = (gcnew System::Windows::Forms::TextBox());
			this->textR17 = (gcnew System::Windows::Forms::TextBox());
			this->textR16 = (gcnew System::Windows::Forms::TextBox());
			this->label31 = (gcnew System::Windows::Forms::Label());
			this->label30 = (gcnew System::Windows::Forms::Label());
			this->label29 = (gcnew System::Windows::Forms::Label());
			this->label28 = (gcnew System::Windows::Forms::Label());
			this->label27 = (gcnew System::Windows::Forms::Label());
			this->label26 = (gcnew System::Windows::Forms::Label());
			this->label25 = (gcnew System::Windows::Forms::Label());
			this->label32 = (gcnew System::Windows::Forms::Label());
			this->textR31 = (gcnew System::Windows::Forms::TextBox());
			this->textR30 = (gcnew System::Windows::Forms::TextBox());
			this->textR29 = (gcnew System::Windows::Forms::TextBox());
			this->textR28 = (gcnew System::Windows::Forms::TextBox());
			this->textR27 = (gcnew System::Windows::Forms::TextBox());
			this->textR26 = (gcnew System::Windows::Forms::TextBox());
			this->textR25 = (gcnew System::Windows::Forms::TextBox());
			this->textR24 = (gcnew System::Windows::Forms::TextBox());
			this->label35 = (gcnew System::Windows::Forms::Label());
			this->label34 = (gcnew System::Windows::Forms::Label());
			this->label33 = (gcnew System::Windows::Forms::Label());
			this->label36 = (gcnew System::Windows::Forms::Label());
			this->textEPC = (gcnew System::Windows::Forms::TextBox());
			this->textDPC = (gcnew System::Windows::Forms::TextBox());
			this->textIPC = (gcnew System::Windows::Forms::TextBox());
			this->textPC = (gcnew System::Windows::Forms::TextBox());
			this->label38 = (gcnew System::Windows::Forms::Label());
			this->label37 = (gcnew System::Windows::Forms::Label());
			this->label39 = (gcnew System::Windows::Forms::Label());
			this->textESP = (gcnew System::Windows::Forms::TextBox());
			this->textDSP = (gcnew System::Windows::Forms::TextBox());
			this->textISP = (gcnew System::Windows::Forms::TextBox());
			this->fullSpeedToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->menuStrip1->SuspendLayout();
			this->toolStrip1->SuspendLayout();
			this->SuspendLayout();
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(4) {this->fileToolStripMenuItem, 
				this->runToolStripMenuItem, this->viewToolStripMenuItem, this->aboutToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(882, 24);
			this->menuStrip1->TabIndex = 1;
			this->menuStrip1->Text = L"menuStrip1";
			// 
			// fileToolStripMenuItem
			// 
			this->fileToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->loadToolStripMenuItem});
			this->fileToolStripMenuItem->Name = L"fileToolStripMenuItem";
			this->fileToolStripMenuItem->Size = System::Drawing::Size(37, 20);
			this->fileToolStripMenuItem->Text = L"&File";
			// 
			// loadToolStripMenuItem
			// 
			this->loadToolStripMenuItem->Name = L"loadToolStripMenuItem";
			this->loadToolStripMenuItem->Size = System::Drawing::Size(100, 22);
			this->loadToolStripMenuItem->Text = L"&Load";
			this->loadToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::loadToolStripMenuItem_Click);
			// 
			// runToolStripMenuItem
			// 
			this->runToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(10) {this->resetToolStripMenuItem, 
				this->stepIntoToolStripMenuItem, this->stepOverToolStripMenuItem, this->stepOutToolStripMenuItem, this->freeRunToolStripMenuItem, 
				this->stopToolStripMenuItem, this->interruptToolStripMenuItem, this->breakpointToolStripMenuItem, this->freeRunFastToolStripMenuItem, 
				this->fullSpeedToolStripMenuItem});
			this->runToolStripMenuItem->Name = L"runToolStripMenuItem";
			this->runToolStripMenuItem->Size = System::Drawing::Size(40, 20);
			this->runToolStripMenuItem->Text = L"&Run";
			this->runToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::runToolStripMenuItem_Click);
			// 
			// resetToolStripMenuItem
			// 
			this->resetToolStripMenuItem->Name = L"resetToolStripMenuItem";
			this->resetToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->resetToolStripMenuItem->Text = L"Reset";
			this->resetToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::resetToolStripMenuItem_Click);
			// 
			// stepIntoToolStripMenuItem
			// 
			this->stepIntoToolStripMenuItem->Name = L"stepIntoToolStripMenuItem";
			this->stepIntoToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->stepIntoToolStripMenuItem->Text = L"Step Into";
			// 
			// stepOverToolStripMenuItem
			// 
			this->stepOverToolStripMenuItem->Name = L"stepOverToolStripMenuItem";
			this->stepOverToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->stepOverToolStripMenuItem->Text = L"Step Over";
			// 
			// stepOutToolStripMenuItem
			// 
			this->stepOutToolStripMenuItem->Name = L"stepOutToolStripMenuItem";
			this->stepOutToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->stepOutToolStripMenuItem->Text = L"Step Out";
			// 
			// freeRunToolStripMenuItem
			// 
			this->freeRunToolStripMenuItem->Name = L"freeRunToolStripMenuItem";
			this->freeRunToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->freeRunToolStripMenuItem->Text = L"Free &Run";
			// 
			// stopToolStripMenuItem
			// 
			this->stopToolStripMenuItem->Name = L"stopToolStripMenuItem";
			this->stopToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->stopToolStripMenuItem->Text = L"&Stop";
			// 
			// interruptToolStripMenuItem
			// 
			this->interruptToolStripMenuItem->Name = L"interruptToolStripMenuItem";
			this->interruptToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->interruptToolStripMenuItem->Text = L"&Interrupt";
			// 
			// breakpointToolStripMenuItem
			// 
			this->breakpointToolStripMenuItem->Name = L"breakpointToolStripMenuItem";
			this->breakpointToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->breakpointToolStripMenuItem->Text = L"&Breakpoint";
			// 
			// freeRunFastToolStripMenuItem
			// 
			this->freeRunFastToolStripMenuItem->Name = L"freeRunFastToolStripMenuItem";
			this->freeRunFastToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->freeRunFastToolStripMenuItem->Text = L"Free Run Fast";
			this->freeRunFastToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::freeRunFastToolStripMenuItem_Click);
			// 
			// viewToolStripMenuItem
			// 
			this->viewToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->registersToolStripMenuItem});
			this->viewToolStripMenuItem->Name = L"viewToolStripMenuItem";
			this->viewToolStripMenuItem->Size = System::Drawing::Size(44, 20);
			this->viewToolStripMenuItem->Text = L"&View";
			// 
			// registersToolStripMenuItem
			// 
			this->registersToolStripMenuItem->Name = L"registersToolStripMenuItem";
			this->registersToolStripMenuItem->Size = System::Drawing::Size(121, 22);
			this->registersToolStripMenuItem->Text = L"&Registers";
			this->registersToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::registersToolStripMenuItem_Click);
			// 
			// aboutToolStripMenuItem
			// 
			this->aboutToolStripMenuItem->Name = L"aboutToolStripMenuItem";
			this->aboutToolStripMenuItem->Size = System::Drawing::Size(52, 20);
			this->aboutToolStripMenuItem->Text = L"&About";
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->FileName = L"Bootrom";
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(474, 24);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(35, 13);
			this->label1->TabIndex = 2;
			this->label1->Text = L"label1";
			// 
			// toolStrip1
			// 
			this->toolStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(7) {this->toolStripButton1, 
				this->toolStripButton2, this->toolStripButton3, this->toolStripButton4, this->toolStripButton5, this->toolStripButton6, this->toolStripButton7});
			this->toolStrip1->Location = System::Drawing::Point(0, 24);
			this->toolStrip1->Name = L"toolStrip1";
			this->toolStrip1->Size = System::Drawing::Size(882, 25);
			this->toolStrip1->TabIndex = 3;
			this->toolStrip1->Text = L"toolStripExec";
			// 
			// toolStripButton1
			// 
			this->toolStripButton1->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton1->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton1.Image")));
			this->toolStripButton1->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton1->Name = L"toolStripButton1";
			this->toolStripButton1->Size = System::Drawing::Size(23, 22);
			this->toolStripButton1->Text = L"toolStripButton1";
			this->toolStripButton1->ToolTipText = L"Step Into";
			this->toolStripButton1->Click += gcnew System::EventHandler(this, &frmMain::toolStripButton1_Click);
			// 
			// toolStripButton2
			// 
			this->toolStripButton2->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton2->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton2.Image")));
			this->toolStripButton2->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton2->Name = L"toolStripButton2";
			this->toolStripButton2->Size = System::Drawing::Size(23, 22);
			this->toolStripButton2->Text = L"toolStripButton2";
			this->toolStripButton2->ToolTipText = L"Bounce Over";
			// 
			// toolStripButton3
			// 
			this->toolStripButton3->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton3->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton3.Image")));
			this->toolStripButton3->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton3->Name = L"toolStripButton3";
			this->toolStripButton3->Size = System::Drawing::Size(23, 22);
			this->toolStripButton3->Text = L"toolStripButton3";
			this->toolStripButton3->ToolTipText = L"Step Out";
			// 
			// toolStripButton4
			// 
			this->toolStripButton4->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton4->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton4.Image")));
			this->toolStripButton4->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton4->Name = L"toolStripButton4";
			this->toolStripButton4->Size = System::Drawing::Size(23, 22);
			this->toolStripButton4->Text = L"toolStripButton4";
			this->toolStripButton4->ToolTipText = L"Run";
			this->toolStripButton4->Click += gcnew System::EventHandler(this, &frmMain::toolStripButton4_Click);
			// 
			// toolStripButton5
			// 
			this->toolStripButton5->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton5->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton5.Image")));
			this->toolStripButton5->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton5->Name = L"toolStripButton5";
			this->toolStripButton5->Size = System::Drawing::Size(23, 22);
			this->toolStripButton5->Text = L"toolStripButton5";
			this->toolStripButton5->ToolTipText = L"Stop";
			this->toolStripButton5->Click += gcnew System::EventHandler(this, &frmMain::toolStripButton5_Click);
			// 
			// toolStripButton6
			// 
			this->toolStripButton6->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton6->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton6.Image")));
			this->toolStripButton6->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton6->Name = L"toolStripButton6";
			this->toolStripButton6->Size = System::Drawing::Size(23, 22);
			this->toolStripButton6->Text = L"toolStripButton6";
			this->toolStripButton6->ToolTipText = L"Interrupt";
			// 
			// toolStripButton7
			// 
			this->toolStripButton7->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton7->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton7.Image")));
			this->toolStripButton7->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton7->Name = L"toolStripButton7";
			this->toolStripButton7->Size = System::Drawing::Size(23, 22);
			this->toolStripButton7->Text = L"toolStripButton7";
			this->toolStripButton7->ToolTipText = L"Breakpoint";
			this->toolStripButton7->Click += gcnew System::EventHandler(this, &frmMain::toolStripButton7_Click);
			// 
			// listBoxAdr
			// 
			this->listBoxAdr->FormattingEnabled = true;
			this->listBoxAdr->Location = System::Drawing::Point(12, 48);
			this->listBoxAdr->Name = L"listBoxAdr";
			this->listBoxAdr->Size = System::Drawing::Size(64, 446);
			this->listBoxAdr->TabIndex = 5;
			// 
			// listBoxCode
			// 
			this->listBoxCode->FormattingEnabled = true;
			this->listBoxCode->Location = System::Drawing::Point(138, 48);
			this->listBoxCode->Name = L"listBoxCode";
			this->listBoxCode->Size = System::Drawing::Size(238, 446);
			this->listBoxCode->TabIndex = 6;
			// 
			// timer1
			// 
			this->timer1->Enabled = true;
			this->timer1->Tick += gcnew System::EventHandler(this, &frmMain::timer1_Tick);
			// 
			// listBoxBytes
			// 
			this->listBoxBytes->FormattingEnabled = true;
			this->listBoxBytes->Location = System::Drawing::Point(72, 48);
			this->listBoxBytes->Name = L"listBoxBytes";
			this->listBoxBytes->Size = System::Drawing::Size(69, 446);
			this->listBoxBytes->TabIndex = 7;
			// 
			// label7
			// 
			this->label7->AutoSize = true;
			this->label7->Location = System::Drawing::Point(402, 235);
			this->label7->Name = L"label7";
			this->label7->Size = System::Drawing::Size(21, 13);
			this->label7->TabIndex = 55;
			this->label7->Text = L"R7";
			// 
			// label6
			// 
			this->label6->AutoSize = true;
			this->label6->Location = System::Drawing::Point(402, 209);
			this->label6->Name = L"label6";
			this->label6->Size = System::Drawing::Size(21, 13);
			this->label6->TabIndex = 54;
			this->label6->Text = L"R6";
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Location = System::Drawing::Point(402, 183);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(21, 13);
			this->label5->TabIndex = 53;
			this->label5->Text = L"R5";
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(402, 157);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(21, 13);
			this->label4->TabIndex = 52;
			this->label4->Text = L"R4";
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(402, 131);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(21, 13);
			this->label3->TabIndex = 51;
			this->label3->Text = L"R3";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(402, 105);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(21, 13);
			this->label2->TabIndex = 50;
			this->label2->Text = L"R2";
			// 
			// label8
			// 
			this->label8->AutoSize = true;
			this->label8->Location = System::Drawing::Point(402, 79);
			this->label8->Name = L"label8";
			this->label8->Size = System::Drawing::Size(21, 13);
			this->label8->TabIndex = 49;
			this->label8->Text = L"R1";
			// 
			// lblR0
			// 
			this->lblR0->AutoSize = true;
			this->lblR0->Location = System::Drawing::Point(402, 53);
			this->lblR0->Name = L"lblR0";
			this->lblR0->Size = System::Drawing::Size(21, 13);
			this->lblR0->TabIndex = 48;
			this->lblR0->Text = L"R0";
			// 
			// textR7
			// 
			this->textR7->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR7->Location = System::Drawing::Point(429, 232);
			this->textR7->Name = L"textR7";
			this->textR7->Size = System::Drawing::Size(82, 17);
			this->textR7->TabIndex = 47;
			this->textR7->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR6
			// 
			this->textR6->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR6->Location = System::Drawing::Point(429, 206);
			this->textR6->Name = L"textR6";
			this->textR6->Size = System::Drawing::Size(82, 17);
			this->textR6->TabIndex = 46;
			this->textR6->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR5
			// 
			this->textR5->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR5->Location = System::Drawing::Point(429, 180);
			this->textR5->Name = L"textR5";
			this->textR5->Size = System::Drawing::Size(82, 17);
			this->textR5->TabIndex = 45;
			this->textR5->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR4
			// 
			this->textR4->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR4->Location = System::Drawing::Point(429, 154);
			this->textR4->Name = L"textR4";
			this->textR4->Size = System::Drawing::Size(82, 17);
			this->textR4->TabIndex = 44;
			this->textR4->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR3
			// 
			this->textR3->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR3->Location = System::Drawing::Point(429, 128);
			this->textR3->Name = L"textR3";
			this->textR3->Size = System::Drawing::Size(82, 17);
			this->textR3->TabIndex = 43;
			this->textR3->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR2
			// 
			this->textR2->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR2->Location = System::Drawing::Point(429, 102);
			this->textR2->Name = L"textR2";
			this->textR2->Size = System::Drawing::Size(82, 17);
			this->textR2->TabIndex = 42;
			this->textR2->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR1
			// 
			this->textR1->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR1->Location = System::Drawing::Point(429, 76);
			this->textR1->Name = L"textR1";
			this->textR1->Size = System::Drawing::Size(82, 17);
			this->textR1->TabIndex = 41;
			this->textR1->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR0
			// 
			this->textR0->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR0->Location = System::Drawing::Point(429, 50);
			this->textR0->Name = L"textR0";
			this->textR0->ReadOnly = true;
			this->textR0->Size = System::Drawing::Size(82, 17);
			this->textR0->TabIndex = 40;
			this->textR0->TabStop = false;
			this->textR0->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label15
			// 
			this->label15->AutoSize = true;
			this->label15->Location = System::Drawing::Point(402, 445);
			this->label15->Name = L"label15";
			this->label15->Size = System::Drawing::Size(27, 13);
			this->label15->TabIndex = 71;
			this->label15->Text = L"R15";
			// 
			// label14
			// 
			this->label14->AutoSize = true;
			this->label14->Location = System::Drawing::Point(402, 419);
			this->label14->Name = L"label14";
			this->label14->Size = System::Drawing::Size(27, 13);
			this->label14->TabIndex = 70;
			this->label14->Text = L"R14";
			// 
			// label13
			// 
			this->label13->AutoSize = true;
			this->label13->Location = System::Drawing::Point(402, 393);
			this->label13->Name = L"label13";
			this->label13->Size = System::Drawing::Size(27, 13);
			this->label13->TabIndex = 69;
			this->label13->Text = L"R13";
			// 
			// label12
			// 
			this->label12->AutoSize = true;
			this->label12->Location = System::Drawing::Point(402, 367);
			this->label12->Name = L"label12";
			this->label12->Size = System::Drawing::Size(27, 13);
			this->label12->TabIndex = 68;
			this->label12->Text = L"R12";
			// 
			// label11
			// 
			this->label11->AutoSize = true;
			this->label11->Location = System::Drawing::Point(402, 341);
			this->label11->Name = L"label11";
			this->label11->Size = System::Drawing::Size(27, 13);
			this->label11->TabIndex = 67;
			this->label11->Text = L"R11";
			// 
			// label10
			// 
			this->label10->AutoSize = true;
			this->label10->Location = System::Drawing::Point(402, 315);
			this->label10->Name = L"label10";
			this->label10->Size = System::Drawing::Size(27, 13);
			this->label10->TabIndex = 66;
			this->label10->Text = L"R10";
			// 
			// label9
			// 
			this->label9->AutoSize = true;
			this->label9->Location = System::Drawing::Point(402, 289);
			this->label9->Name = L"label9";
			this->label9->Size = System::Drawing::Size(21, 13);
			this->label9->TabIndex = 65;
			this->label9->Text = L"R9";
			// 
			// label16
			// 
			this->label16->AutoSize = true;
			this->label16->Location = System::Drawing::Point(402, 263);
			this->label16->Name = L"label16";
			this->label16->Size = System::Drawing::Size(21, 13);
			this->label16->TabIndex = 64;
			this->label16->Text = L"R8";
			// 
			// textR15
			// 
			this->textR15->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR15->Location = System::Drawing::Point(429, 442);
			this->textR15->Name = L"textR15";
			this->textR15->Size = System::Drawing::Size(82, 17);
			this->textR15->TabIndex = 63;
			this->textR15->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR14
			// 
			this->textR14->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR14->Location = System::Drawing::Point(429, 416);
			this->textR14->Name = L"textR14";
			this->textR14->Size = System::Drawing::Size(82, 17);
			this->textR14->TabIndex = 62;
			this->textR14->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR13
			// 
			this->textR13->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR13->Location = System::Drawing::Point(429, 390);
			this->textR13->Name = L"textR13";
			this->textR13->Size = System::Drawing::Size(82, 17);
			this->textR13->TabIndex = 61;
			this->textR13->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR12
			// 
			this->textR12->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR12->Location = System::Drawing::Point(429, 364);
			this->textR12->Name = L"textR12";
			this->textR12->Size = System::Drawing::Size(82, 17);
			this->textR12->TabIndex = 60;
			this->textR12->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR11
			// 
			this->textR11->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR11->Location = System::Drawing::Point(429, 338);
			this->textR11->Name = L"textR11";
			this->textR11->Size = System::Drawing::Size(82, 17);
			this->textR11->TabIndex = 59;
			this->textR11->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR10
			// 
			this->textR10->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR10->Location = System::Drawing::Point(429, 312);
			this->textR10->Name = L"textR10";
			this->textR10->Size = System::Drawing::Size(82, 17);
			this->textR10->TabIndex = 58;
			this->textR10->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR9
			// 
			this->textR9->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR9->Location = System::Drawing::Point(429, 286);
			this->textR9->Name = L"textR9";
			this->textR9->Size = System::Drawing::Size(82, 17);
			this->textR9->TabIndex = 57;
			this->textR9->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR8
			// 
			this->textR8->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR8->Location = System::Drawing::Point(429, 260);
			this->textR8->Name = L"textR8";
			this->textR8->Size = System::Drawing::Size(82, 17);
			this->textR8->TabIndex = 56;
			this->textR8->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label23
			// 
			this->label23->AutoSize = true;
			this->label23->Location = System::Drawing::Point(551, 209);
			this->label23->Name = L"label23";
			this->label23->Size = System::Drawing::Size(27, 13);
			this->label23->TabIndex = 87;
			this->label23->Text = L"R22";
			// 
			// label22
			// 
			this->label22->AutoSize = true;
			this->label22->Location = System::Drawing::Point(551, 183);
			this->label22->Name = L"label22";
			this->label22->Size = System::Drawing::Size(27, 13);
			this->label22->TabIndex = 85;
			this->label22->Text = L"R21";
			// 
			// label21
			// 
			this->label21->AutoSize = true;
			this->label21->Location = System::Drawing::Point(551, 235);
			this->label21->Name = L"label21";
			this->label21->Size = System::Drawing::Size(27, 13);
			this->label21->TabIndex = 86;
			this->label21->Text = L"R23";
			// 
			// label20
			// 
			this->label20->AutoSize = true;
			this->label20->Location = System::Drawing::Point(551, 157);
			this->label20->Name = L"label20";
			this->label20->Size = System::Drawing::Size(27, 13);
			this->label20->TabIndex = 84;
			this->label20->Text = L"R20";
			// 
			// label19
			// 
			this->label19->AutoSize = true;
			this->label19->Location = System::Drawing::Point(551, 131);
			this->label19->Name = L"label19";
			this->label19->Size = System::Drawing::Size(27, 13);
			this->label19->TabIndex = 83;
			this->label19->Text = L"R19";
			// 
			// label18
			// 
			this->label18->AutoSize = true;
			this->label18->Location = System::Drawing::Point(551, 105);
			this->label18->Name = L"label18";
			this->label18->Size = System::Drawing::Size(27, 13);
			this->label18->TabIndex = 82;
			this->label18->Text = L"R18";
			// 
			// label17
			// 
			this->label17->AutoSize = true;
			this->label17->Location = System::Drawing::Point(551, 79);
			this->label17->Name = L"label17";
			this->label17->Size = System::Drawing::Size(27, 13);
			this->label17->TabIndex = 81;
			this->label17->Text = L"R17";
			// 
			// label24
			// 
			this->label24->AutoSize = true;
			this->label24->Location = System::Drawing::Point(551, 53);
			this->label24->Name = L"label24";
			this->label24->Size = System::Drawing::Size(27, 13);
			this->label24->TabIndex = 80;
			this->label24->Text = L"R16";
			// 
			// textR23
			// 
			this->textR23->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR23->Location = System::Drawing::Point(584, 232);
			this->textR23->Name = L"textR23";
			this->textR23->Size = System::Drawing::Size(82, 17);
			this->textR23->TabIndex = 79;
			this->textR23->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR22
			// 
			this->textR22->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR22->Location = System::Drawing::Point(584, 206);
			this->textR22->Name = L"textR22";
			this->textR22->Size = System::Drawing::Size(82, 17);
			this->textR22->TabIndex = 78;
			this->textR22->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR21
			// 
			this->textR21->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR21->Location = System::Drawing::Point(584, 180);
			this->textR21->Name = L"textR21";
			this->textR21->Size = System::Drawing::Size(82, 17);
			this->textR21->TabIndex = 77;
			this->textR21->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR20
			// 
			this->textR20->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR20->Location = System::Drawing::Point(584, 154);
			this->textR20->Name = L"textR20";
			this->textR20->Size = System::Drawing::Size(82, 17);
			this->textR20->TabIndex = 76;
			this->textR20->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR19
			// 
			this->textR19->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR19->Location = System::Drawing::Point(584, 128);
			this->textR19->Name = L"textR19";
			this->textR19->Size = System::Drawing::Size(82, 17);
			this->textR19->TabIndex = 75;
			this->textR19->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR18
			// 
			this->textR18->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR18->Location = System::Drawing::Point(584, 102);
			this->textR18->Name = L"textR18";
			this->textR18->Size = System::Drawing::Size(82, 17);
			this->textR18->TabIndex = 74;
			this->textR18->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR17
			// 
			this->textR17->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR17->Location = System::Drawing::Point(584, 76);
			this->textR17->Name = L"textR17";
			this->textR17->Size = System::Drawing::Size(82, 17);
			this->textR17->TabIndex = 73;
			this->textR17->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR16
			// 
			this->textR16->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR16->Location = System::Drawing::Point(584, 50);
			this->textR16->Name = L"textR16";
			this->textR16->Size = System::Drawing::Size(82, 17);
			this->textR16->TabIndex = 72;
			this->textR16->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label31
			// 
			this->label31->AutoSize = true;
			this->label31->Location = System::Drawing::Point(528, 443);
			this->label31->Name = L"label31";
			this->label31->Size = System::Drawing::Size(46, 13);
			this->label31->TabIndex = 103;
			this->label31->Text = L"R31/LR";
			// 
			// label30
			// 
			this->label30->AutoSize = true;
			this->label30->Location = System::Drawing::Point(528, 417);
			this->label30->Name = L"label30";
			this->label30->Size = System::Drawing::Size(46, 13);
			this->label30->TabIndex = 102;
			this->label30->Text = L"R30/SP";
			// 
			// label29
			// 
			this->label29->AutoSize = true;
			this->label29->Location = System::Drawing::Point(528, 391);
			this->label29->Name = L"label29";
			this->label29->Size = System::Drawing::Size(27, 13);
			this->label29->TabIndex = 101;
			this->label29->Text = L"R29";
			// 
			// label28
			// 
			this->label28->AutoSize = true;
			this->label28->Location = System::Drawing::Point(528, 365);
			this->label28->Name = L"label28";
			this->label28->Size = System::Drawing::Size(53, 13);
			this->label28->TabIndex = 100;
			this->label28->Text = L"R28/XLR";
			// 
			// label27
			// 
			this->label27->AutoSize = true;
			this->label27->Location = System::Drawing::Point(528, 339);
			this->label27->Name = L"label27";
			this->label27->Size = System::Drawing::Size(46, 13);
			this->label27->TabIndex = 99;
			this->label27->Text = L"R27/BP";
			// 
			// label26
			// 
			this->label26->AutoSize = true;
			this->label26->Location = System::Drawing::Point(528, 313);
			this->label26->Name = L"label26";
			this->label26->Size = System::Drawing::Size(27, 13);
			this->label26->TabIndex = 98;
			this->label26->Text = L"R26";
			// 
			// label25
			// 
			this->label25->AutoSize = true;
			this->label25->Location = System::Drawing::Point(528, 287);
			this->label25->Name = L"label25";
			this->label25->Size = System::Drawing::Size(27, 13);
			this->label25->TabIndex = 97;
			this->label25->Text = L"R25";
			// 
			// label32
			// 
			this->label32->AutoSize = true;
			this->label32->Location = System::Drawing::Point(528, 261);
			this->label32->Name = L"label32";
			this->label32->Size = System::Drawing::Size(47, 13);
			this->label32->TabIndex = 96;
			this->label32->Text = L"R24/TR";
			// 
			// textR31
			// 
			this->textR31->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR31->Location = System::Drawing::Point(584, 440);
			this->textR31->Name = L"textR31";
			this->textR31->Size = System::Drawing::Size(82, 17);
			this->textR31->TabIndex = 95;
			this->textR31->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR30
			// 
			this->textR30->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR30->Location = System::Drawing::Point(584, 414);
			this->textR30->Name = L"textR30";
			this->textR30->Size = System::Drawing::Size(82, 17);
			this->textR30->TabIndex = 94;
			this->textR30->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR29
			// 
			this->textR29->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR29->Location = System::Drawing::Point(584, 388);
			this->textR29->Name = L"textR29";
			this->textR29->Size = System::Drawing::Size(82, 17);
			this->textR29->TabIndex = 93;
			this->textR29->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR28
			// 
			this->textR28->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR28->Location = System::Drawing::Point(584, 362);
			this->textR28->Name = L"textR28";
			this->textR28->Size = System::Drawing::Size(82, 17);
			this->textR28->TabIndex = 92;
			this->textR28->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR27
			// 
			this->textR27->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR27->Location = System::Drawing::Point(584, 336);
			this->textR27->Name = L"textR27";
			this->textR27->Size = System::Drawing::Size(82, 17);
			this->textR27->TabIndex = 91;
			this->textR27->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR26
			// 
			this->textR26->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR26->Location = System::Drawing::Point(584, 310);
			this->textR26->Name = L"textR26";
			this->textR26->Size = System::Drawing::Size(82, 17);
			this->textR26->TabIndex = 90;
			this->textR26->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR25
			// 
			this->textR25->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR25->Location = System::Drawing::Point(584, 284);
			this->textR25->Name = L"textR25";
			this->textR25->Size = System::Drawing::Size(82, 17);
			this->textR25->TabIndex = 89;
			this->textR25->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// textR24
			// 
			this->textR24->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textR24->Location = System::Drawing::Point(584, 258);
			this->textR24->Name = L"textR24";
			this->textR24->Size = System::Drawing::Size(82, 17);
			this->textR24->TabIndex = 88;
			this->textR24->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// label35
			// 
			this->label35->AutoSize = true;
			this->label35->Location = System::Drawing::Point(700, 131);
			this->label35->Name = L"label35";
			this->label35->Size = System::Drawing::Size(28, 13);
			this->label35->TabIndex = 111;
			this->label35->Text = L"EPC";
			// 
			// label34
			// 
			this->label34->AutoSize = true;
			this->label34->Location = System::Drawing::Point(700, 105);
			this->label34->Name = L"label34";
			this->label34->Size = System::Drawing::Size(29, 13);
			this->label34->TabIndex = 110;
			this->label34->Text = L"DPC";
			// 
			// label33
			// 
			this->label33->AutoSize = true;
			this->label33->Location = System::Drawing::Point(700, 79);
			this->label33->Name = L"label33";
			this->label33->Size = System::Drawing::Size(24, 13);
			this->label33->TabIndex = 109;
			this->label33->Text = L"IPC";
			// 
			// label36
			// 
			this->label36->AutoSize = true;
			this->label36->Location = System::Drawing::Point(700, 53);
			this->label36->Name = L"label36";
			this->label36->Size = System::Drawing::Size(21, 13);
			this->label36->TabIndex = 108;
			this->label36->Text = L"PC";
			// 
			// textEPC
			// 
			this->textEPC->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textEPC->Location = System::Drawing::Point(727, 128);
			this->textEPC->Name = L"textEPC";
			this->textEPC->Size = System::Drawing::Size(82, 17);
			this->textEPC->TabIndex = 107;
			// 
			// textDPC
			// 
			this->textDPC->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textDPC->Location = System::Drawing::Point(727, 102);
			this->textDPC->Name = L"textDPC";
			this->textDPC->Size = System::Drawing::Size(82, 17);
			this->textDPC->TabIndex = 106;
			// 
			// textIPC
			// 
			this->textIPC->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textIPC->Location = System::Drawing::Point(727, 76);
			this->textIPC->Name = L"textIPC";
			this->textIPC->Size = System::Drawing::Size(82, 17);
			this->textIPC->TabIndex = 105;
			// 
			// textPC
			// 
			this->textPC->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textPC->Location = System::Drawing::Point(727, 50);
			this->textPC->Name = L"textPC";
			this->textPC->Size = System::Drawing::Size(82, 17);
			this->textPC->TabIndex = 104;
			// 
			// label38
			// 
			this->label38->AutoSize = true;
			this->label38->Location = System::Drawing::Point(700, 235);
			this->label38->Name = L"label38";
			this->label38->Size = System::Drawing::Size(28, 13);
			this->label38->TabIndex = 117;
			this->label38->Text = L"ESP";
			// 
			// label37
			// 
			this->label37->AutoSize = true;
			this->label37->Location = System::Drawing::Point(700, 209);
			this->label37->Name = L"label37";
			this->label37->Size = System::Drawing::Size(29, 13);
			this->label37->TabIndex = 116;
			this->label37->Text = L"DSP";
			// 
			// label39
			// 
			this->label39->AutoSize = true;
			this->label39->Location = System::Drawing::Point(700, 183);
			this->label39->Name = L"label39";
			this->label39->Size = System::Drawing::Size(24, 13);
			this->label39->TabIndex = 115;
			this->label39->Text = L"ISP";
			// 
			// textESP
			// 
			this->textESP->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textESP->Location = System::Drawing::Point(727, 232);
			this->textESP->Name = L"textESP";
			this->textESP->Size = System::Drawing::Size(82, 17);
			this->textESP->TabIndex = 114;
			// 
			// textDSP
			// 
			this->textDSP->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textDSP->Location = System::Drawing::Point(727, 206);
			this->textDSP->Name = L"textDSP";
			this->textDSP->Size = System::Drawing::Size(82, 17);
			this->textDSP->TabIndex = 113;
			// 
			// textISP
			// 
			this->textISP->Font = (gcnew System::Drawing::Font(L"Microsoft Sans Serif", 6, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->textISP->Location = System::Drawing::Point(727, 180);
			this->textISP->Name = L"textISP";
			this->textISP->Size = System::Drawing::Size(82, 17);
			this->textISP->TabIndex = 112;
			// 
			// fullSpeedToolStripMenuItem
			// 
			this->fullSpeedToolStripMenuItem->Name = L"fullSpeedToolStripMenuItem";
			this->fullSpeedToolStripMenuItem->Size = System::Drawing::Size(152, 22);
			this->fullSpeedToolStripMenuItem->Text = L"Full Speed";
			this->fullSpeedToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmMain::fullSpeedToolStripMenuItem_Click);
			// 
			// frmMain
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(882, 549);
			this->Controls->Add(this->label38);
			this->Controls->Add(this->label37);
			this->Controls->Add(this->label39);
			this->Controls->Add(this->textESP);
			this->Controls->Add(this->textDSP);
			this->Controls->Add(this->textISP);
			this->Controls->Add(this->label35);
			this->Controls->Add(this->label34);
			this->Controls->Add(this->label33);
			this->Controls->Add(this->label36);
			this->Controls->Add(this->textEPC);
			this->Controls->Add(this->textDPC);
			this->Controls->Add(this->textIPC);
			this->Controls->Add(this->textPC);
			this->Controls->Add(this->label31);
			this->Controls->Add(this->label30);
			this->Controls->Add(this->label29);
			this->Controls->Add(this->label28);
			this->Controls->Add(this->label27);
			this->Controls->Add(this->label26);
			this->Controls->Add(this->label25);
			this->Controls->Add(this->label32);
			this->Controls->Add(this->textR31);
			this->Controls->Add(this->textR30);
			this->Controls->Add(this->textR29);
			this->Controls->Add(this->textR28);
			this->Controls->Add(this->textR27);
			this->Controls->Add(this->textR26);
			this->Controls->Add(this->textR25);
			this->Controls->Add(this->textR24);
			this->Controls->Add(this->label23);
			this->Controls->Add(this->label22);
			this->Controls->Add(this->label21);
			this->Controls->Add(this->label20);
			this->Controls->Add(this->label19);
			this->Controls->Add(this->label18);
			this->Controls->Add(this->label17);
			this->Controls->Add(this->label24);
			this->Controls->Add(this->textR23);
			this->Controls->Add(this->textR22);
			this->Controls->Add(this->textR21);
			this->Controls->Add(this->textR20);
			this->Controls->Add(this->textR19);
			this->Controls->Add(this->textR18);
			this->Controls->Add(this->textR17);
			this->Controls->Add(this->textR16);
			this->Controls->Add(this->label15);
			this->Controls->Add(this->label14);
			this->Controls->Add(this->label13);
			this->Controls->Add(this->label12);
			this->Controls->Add(this->label11);
			this->Controls->Add(this->label10);
			this->Controls->Add(this->label9);
			this->Controls->Add(this->label16);
			this->Controls->Add(this->textR15);
			this->Controls->Add(this->textR14);
			this->Controls->Add(this->textR13);
			this->Controls->Add(this->textR12);
			this->Controls->Add(this->textR11);
			this->Controls->Add(this->textR10);
			this->Controls->Add(this->textR9);
			this->Controls->Add(this->textR8);
			this->Controls->Add(this->label7);
			this->Controls->Add(this->label6);
			this->Controls->Add(this->label5);
			this->Controls->Add(this->label4);
			this->Controls->Add(this->label3);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label8);
			this->Controls->Add(this->lblR0);
			this->Controls->Add(this->textR7);
			this->Controls->Add(this->textR6);
			this->Controls->Add(this->textR5);
			this->Controls->Add(this->textR4);
			this->Controls->Add(this->textR3);
			this->Controls->Add(this->textR2);
			this->Controls->Add(this->textR1);
			this->Controls->Add(this->textR0);
			this->Controls->Add(this->listBoxBytes);
			this->Controls->Add(this->listBoxCode);
			this->Controls->Add(this->listBoxAdr);
			this->Controls->Add(this->toolStrip1);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->menuStrip1);
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"frmMain";
			this->Text = L"emuFISA64";
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->toolStrip1->ResumeLayout(false);
			this->toolStrip1->PerformLayout();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void registersToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
				 frmRegisters ^form = gcnew frmRegisters();
				 form->Show();
				  }
private: System::Void loadToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 //static char buf[135000];
			 int nc,nn;
			 std::string buf;
			 std::string str_ad;
			 std::string str_insn;
			 std::string str_ad_insn;
			 std::string str_disassem;
			 unsigned int ad;
			 unsigned int dat;
			 unsigned int firstAdr;
			 char buf2[20];

			this->openFileDialog1->ShowDialog();
			char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->openFileDialog1->FileName);
			std::ifstream fp_in;
			fp_in.open(str,std::ios::in);
			firstAdr = 0;
			while (!fp_in.eof()) {
				std::getline(fp_in, buf);
				nc = buf.find(',');
				nn = buf.find('\n');
				if (nc > 0)
					str_ad = buf.substr(0,nc);
				if (nc > 0)
					str_insn = buf.substr(nc+1);
				ad = strtoul(str_ad.c_str(),0,16);
				dat = strtoul(str_insn.c_str(),0,16);
				if (!firstAdr)
					firstAdr = ad;
				system1.memory[ad>>2] = dat;
				str_disassem = Disassem(str_ad,str_insn);
				str_ad_insn = str_ad + "   " + str_insn + "    " + str_disassem;
				label1->Text = gcnew String(str_ad_insn.c_str());
				//this->checkedListBox1->Items->Add(gcnew String(str_ad_insn.c_str()));
			}
     		fp_in.close();
			ad = firstAdr;
			UpdateListBox(ad);
	};
private: System::Void toolStripButton1_Click(System::Object^  sender, System::EventArgs^  e) {
			 cpu1.Step();
			 UpdateListBox(cpu1.pc-32);
		 }
private: System::Void resetToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 cpu1.Reset();
			 UpdateListBox(cpu1.pc-32);
			 //checkedListBox1->SetSelection("010000");
			 //checkedListBox1->Items(0)->Select(0);
		 }
public: void UpdateListBox(unsigned int ad) {
	int nn;
	char buf2[20];
	std::string buf;

	this->listBoxCode->Items->Clear();
	this->listBoxAdr->Items->Clear();
	this->listBoxBytes->Items->Clear();
	for (nn = 0; nn < 30; nn++) {
		sprintf(buf2,"%06X", ad);
		buf = std::string(buf2);
		this->listBoxAdr->Items->Add(gcnew String(buf.c_str()));
		sprintf(buf2,"%08X", system1.memory[ad>>2]);
		buf = std::string(buf2);
		this->listBoxBytes->Items->Add(gcnew String(buf.c_str()));
		buf = Disassem(ad,system1.memory[ad>>2]) + "\r\n";
		//richTextCode->AppendText(gcnew String(buf.c_str()));
//				this->checkedListBox1->Items->Add(gcnew String(buf.c_str()));
		this->listBoxCode->Items->Add(gcnew String(buf.c_str()));
		if (ad==cpu1.pc) {
			this->listBoxAdr->SetSelected(nn,true);
			this->listBoxBytes->SetSelected(nn,true);
			this->listBoxCode->SetSelected(nn,true);
		}
		ad = ad + 4;
	}
	sprintf(buf2, "%016I64X", cpu1.regs[0]);
	buf = std::string(buf2);
	this->textR0->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[1]);
	buf = std::string(buf2);
	this->textR1->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[2]);
	buf = std::string(buf2);
	this->textR2->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[3]);
	buf = std::string(buf2);
	this->textR3->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[4]);
	buf = std::string(buf2);
	this->textR4->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[5]);
	buf = std::string(buf2);
	this->textR5->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[6]);
	buf = std::string(buf2);
	this->textR6->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[7]);
	buf = std::string(buf2);
	this->textR7->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[8]);
	buf = std::string(buf2);
	this->textR8->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[9]);
	buf = std::string(buf2);
	this->textR9->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[10]);
	buf = std::string(buf2);
	this->textR10->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[11]);
	buf = std::string(buf2);
	this->textR11->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[12]);
	buf = std::string(buf2);
	this->textR12->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[13]);
	buf = std::string(buf2);
	this->textR13->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[14]);
	buf = std::string(buf2);
	this->textR14->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[15]);
	buf = std::string(buf2);
	this->textR15->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[16]);
	buf = std::string(buf2);
	this->textR16->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[17]);
	buf = std::string(buf2);
	this->textR17->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[18]);
	buf = std::string(buf2);
	this->textR18->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[19]);
	buf = std::string(buf2);
	this->textR19->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[20]);
	buf = std::string(buf2);
	this->textR20->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[21]);
	buf = std::string(buf2);
	this->textR21->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[22]);
	buf = std::string(buf2);
	this->textR22->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[23]);
	buf = std::string(buf2);
	this->textR23->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[24]);
	buf = std::string(buf2);
	this->textR24->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[25]);
	buf = std::string(buf2);
	this->textR25->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[26]);
	buf = std::string(buf2);
	this->textR26->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[27]);
	buf = std::string(buf2);
	this->textR27->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[28]);
	buf = std::string(buf2);
	this->textR28->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[29]);
	buf = std::string(buf2);
	this->textR29->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[30]);
	buf = std::string(buf2);
	this->textR30->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%016I64X", cpu1.regs[31]);
	buf = std::string(buf2);
	this->textR31->Text = gcnew String(buf.c_str());
	sprintf(buf2, "%06X", cpu1.pc);
	buf = std::string(buf2);
	this->textPC->Text = gcnew String(buf.c_str());
};
private: System::Void toolStripButton5_Click(System::Object^  sender, System::EventArgs^  e) {
			 cpu1.brk = true;
			 cpu1.isRunning = false;
			 fullspeed = false;
			 this->timer1->Interval = 100;
		 }
private: System::Void toolStripButton4_Click(System::Object^  sender, System::EventArgs^  e) {
			 cpu1.isRunning = true;
		 }
private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 int nn,kk;
			 if (cpu1.isRunning) {
				 if (fullspeed) {
					 for (nn = 0; nn < 10000; nn++) {
						 for (kk = 0; kk < 30; kk++) {
							 if (cpu1.pc == breakpoints[kk]) {
								 cpu1.isRunning = false;
								 UpdateListBox(cpu1.pc-32);
								 return;
						     }
						 }
						 cpu1.Step();
					 }
				 }
				for (kk = 0; kk < 30; kk++) {
					if (cpu1.pc == breakpoints[kk]) {
						cpu1.isRunning = false;
						 UpdateListBox(cpu1.pc-32);
						return;
					}
				}
				 cpu1.Step();
				 UpdateListBox(cpu1.pc-32);
			 }
		 }
private: System::Void toolStripButton7_Click(System::Object^  sender, System::EventArgs^  e) {
		frmBreakpoint ^form = gcnew frmBreakpoint();
				 form->Show();		 }
private: System::Void freeRunFastToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 this->timer1->Interval = 1;
		 }
private: System::Void runToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void fullSpeedToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 fullspeed = true;
		 }
};
};
