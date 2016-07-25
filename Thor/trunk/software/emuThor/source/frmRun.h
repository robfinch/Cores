#pragma once
#include <math.h>
#include "fmrFreeRun.h"
#include "clsDisassem.h"

extern clsDisassem da;
extern bool isRunning;
extern bool quit;
extern bool stepout, stepover;
extern unsigned int step_depth, stepover_depth;
extern unsigned int stepoverBkpt;
extern unsigned int stepover_pc;
extern bool animate;
extern bool fullspeed;
extern bool runstop;
extern bool runClosed;

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Threading;
	using namespace System::Diagnostics;

	/// <summary>
	/// Summary for frmRun
	/// </summary>
	public ref class frmRun : public System::Windows::Forms::Form
	{
	public:
		frmRun(Mutex^ m)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			mut = m;
			stopwatch = gcnew Stopwatch;
			InitializeBackgroundWorker();
			toolTipMHz->SetToolTip(lblMHz,"Shows an estimate of the frequency of operation\n of the emulator compared to the FPGA version.");
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmRun()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TrackBar^  trackBar1;
	protected: 
	private: System::Windows::Forms::ListBox^  listBoxCode;
	private: System::Windows::Forms::ListBox^  listBoxBytes;
	private: System::Windows::Forms::ListBox^  listBoxAdr;
	private: System::Windows::Forms::ToolStrip^  toolStrip1;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton1;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton2;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton3;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton4;
	private: System::Windows::Forms::ToolStripButton^  toolStripButton5;


	private: System::Windows::Forms::ToolStripButton^  toolStripButton8;
	private: Mutex^ mut;
	private: Stopwatch^ stopwatch;
	private: __int64 startTick, stopTick;
	private: System::Windows::Forms::MenuStrip^  menuStrip1;

	private: System::Windows::Forms::ToolStripMenuItem^  stepOverToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  stepOutToolStripMenuItem;

	private: System::Windows::Forms::ToolStripMenuItem^  stopToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  resetToolStripMenuItem;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::Windows::Forms::ToolStripMenuItem^  animateToolStripMenuItem;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::ProgressBar^  progressBar1;
	private: System::Windows::Forms::NumericUpDown^  numSteps;

	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Button^  button1;
	private: System::ComponentModel::BackgroundWorker^  backgroundWorker1;
	private: System::Windows::Forms::Button^  button2;
	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::ToolStripMenuItem^  stepIntoToolStripMenuItem;
	private: System::Windows::Forms::Label^  lblMHz;
	private: System::Windows::Forms::ToolTip^  toolTipMHz;
	private: System::Windows::Forms::CheckBox^  checkBox1;
	private: System::Windows::Forms::NumericUpDown^  nudSegmentModel;
	private: System::Windows::Forms::Label^  label4;

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
			System::ComponentModel::ComponentResourceManager^  resources = (gcnew System::ComponentModel::ComponentResourceManager(frmRun::typeid));
			this->trackBar1 = (gcnew System::Windows::Forms::TrackBar());
			this->listBoxCode = (gcnew System::Windows::Forms::ListBox());
			this->listBoxBytes = (gcnew System::Windows::Forms::ListBox());
			this->listBoxAdr = (gcnew System::Windows::Forms::ListBox());
			this->toolStrip1 = (gcnew System::Windows::Forms::ToolStrip());
			this->toolStripButton1 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton2 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton3 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton4 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton5 = (gcnew System::Windows::Forms::ToolStripButton());
			this->toolStripButton8 = (gcnew System::Windows::Forms::ToolStripButton());
			this->menuStrip1 = (gcnew System::Windows::Forms::MenuStrip());
			this->stepIntoToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stepOverToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stepOutToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->animateToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->stopToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->resetToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->progressBar1 = (gcnew System::Windows::Forms::ProgressBar());
			this->numSteps = (gcnew System::Windows::Forms::NumericUpDown());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->backgroundWorker1 = (gcnew System::ComponentModel::BackgroundWorker());
			this->button2 = (gcnew System::Windows::Forms::Button());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->lblMHz = (gcnew System::Windows::Forms::Label());
			this->toolTipMHz = (gcnew System::Windows::Forms::ToolTip(this->components));
			this->checkBox1 = (gcnew System::Windows::Forms::CheckBox());
			this->nudSegmentModel = (gcnew System::Windows::Forms::NumericUpDown());
			this->label4 = (gcnew System::Windows::Forms::Label());
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->trackBar1))->BeginInit();
			this->toolStrip1->SuspendLayout();
			this->menuStrip1->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numSteps))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->nudSegmentModel))->BeginInit();
			this->SuspendLayout();
			// 
			// trackBar1
			// 
			this->trackBar1->Location = System::Drawing::Point(565, 63);
			this->trackBar1->Maximum = 12;
			this->trackBar1->Name = L"trackBar1";
			this->trackBar1->Size = System::Drawing::Size(137, 45);
			this->trackBar1->TabIndex = 12;
			this->trackBar1->TickStyle = System::Windows::Forms::TickStyle::TopLeft;
			this->trackBar1->Value = 7;
			this->trackBar1->Scroll += gcnew System::EventHandler(this, &frmRun::trackBar1_Scroll);
			// 
			// listBoxCode
			// 
			this->listBoxCode->FormattingEnabled = true;
			this->listBoxCode->Location = System::Drawing::Point(232, 63);
			this->listBoxCode->Name = L"listBoxCode";
			this->listBoxCode->Size = System::Drawing::Size(327, 433);
			this->listBoxCode->TabIndex = 11;
			// 
			// listBoxBytes
			// 
			this->listBoxBytes->FormattingEnabled = true;
			this->listBoxBytes->Location = System::Drawing::Point(85, 63);
			this->listBoxBytes->Name = L"listBoxBytes";
			this->listBoxBytes->Size = System::Drawing::Size(141, 433);
			this->listBoxBytes->TabIndex = 10;
			// 
			// listBoxAdr
			// 
			this->listBoxAdr->FormattingEnabled = true;
			this->listBoxAdr->Location = System::Drawing::Point(8, 63);
			this->listBoxAdr->Name = L"listBoxAdr";
			this->listBoxAdr->Size = System::Drawing::Size(71, 433);
			this->listBoxAdr->TabIndex = 9;
			// 
			// toolStrip1
			// 
			this->toolStrip1->Dock = System::Windows::Forms::DockStyle::None;
			this->toolStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(6) {this->toolStripButton1, 
				this->toolStripButton2, this->toolStripButton3, this->toolStripButton4, this->toolStripButton5, this->toolStripButton8});
			this->toolStrip1->Location = System::Drawing::Point(9, 35);
			this->toolStrip1->Name = L"toolStrip1";
			this->toolStrip1->Size = System::Drawing::Size(150, 25);
			this->toolStrip1->TabIndex = 13;
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
			this->toolStripButton1->Click += gcnew System::EventHandler(this, &frmRun::toolStripButton1_Click);
			// 
			// toolStripButton2
			// 
			this->toolStripButton2->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton2->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton2.Image")));
			this->toolStripButton2->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton2->Name = L"toolStripButton2";
			this->toolStripButton2->Size = System::Drawing::Size(23, 22);
			this->toolStripButton2->Text = L"Step Over (Bounce)";
			this->toolStripButton2->Click += gcnew System::EventHandler(this, &frmRun::toolStripButton2_Click);
			// 
			// toolStripButton3
			// 
			this->toolStripButton3->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton3->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton3.Image")));
			this->toolStripButton3->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton3->Name = L"toolStripButton3";
			this->toolStripButton3->Size = System::Drawing::Size(23, 22);
			this->toolStripButton3->Text = L"Step Out Of";
			this->toolStripButton3->Click += gcnew System::EventHandler(this, &frmRun::toolStripButton3_Click);
			// 
			// toolStripButton4
			// 
			this->toolStripButton4->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton4->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton4.Image")));
			this->toolStripButton4->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton4->Name = L"toolStripButton4";
			this->toolStripButton4->Size = System::Drawing::Size(23, 22);
			this->toolStripButton4->Text = L"Run";
			this->toolStripButton4->Click += gcnew System::EventHandler(this, &frmRun::toolStripButton4_Click);
			// 
			// toolStripButton5
			// 
			this->toolStripButton5->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton5->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton5.Image")));
			this->toolStripButton5->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton5->Name = L"toolStripButton5";
			this->toolStripButton5->Size = System::Drawing::Size(23, 22);
			this->toolStripButton5->Text = L"Stop";
			this->toolStripButton5->Click += gcnew System::EventHandler(this, &frmRun::toolStripButton5_Click);
			// 
			// toolStripButton8
			// 
			this->toolStripButton8->DisplayStyle = System::Windows::Forms::ToolStripItemDisplayStyle::Image;
			this->toolStripButton8->Image = (cli::safe_cast<System::Drawing::Image^  >(resources->GetObject(L"toolStripButton8.Image")));
			this->toolStripButton8->ImageTransparentColor = System::Drawing::Color::Magenta;
			this->toolStripButton8->Name = L"toolStripButton8";
			this->toolStripButton8->Size = System::Drawing::Size(23, 22);
			this->toolStripButton8->Text = L"Reset Button";
			this->toolStripButton8->Click += gcnew System::EventHandler(this, &frmRun::toolStripButton8_Click);
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(6) {this->stepIntoToolStripMenuItem, 
				this->stepOverToolStripMenuItem, this->stepOutToolStripMenuItem, this->animateToolStripMenuItem, this->stopToolStripMenuItem, 
				this->resetToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(741, 24);
			this->menuStrip1->TabIndex = 14;
			this->menuStrip1->Text = L"menuStrip1";
			this->menuStrip1->ItemClicked += gcnew System::Windows::Forms::ToolStripItemClickedEventHandler(this, &frmRun::menuStrip1_ItemClicked);
			// 
			// stepIntoToolStripMenuItem
			// 
			this->stepIntoToolStripMenuItem->Name = L"stepIntoToolStripMenuItem";
			this->stepIntoToolStripMenuItem->Size = System::Drawing::Size(66, 20);
			this->stepIntoToolStripMenuItem->Text = L"Step I&nto";
			this->stepIntoToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmRun::stepIntoToolStripMenuItem_Click);
			// 
			// stepOverToolStripMenuItem
			// 
			this->stepOverToolStripMenuItem->Name = L"stepOverToolStripMenuItem";
			this->stepOverToolStripMenuItem->Size = System::Drawing::Size(70, 20);
			this->stepOverToolStripMenuItem->Text = L"Step &Over";
			this->stepOverToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmRun::stepOverToolStripMenuItem_Click);
			// 
			// stepOutToolStripMenuItem
			// 
			this->stepOutToolStripMenuItem->Name = L"stepOutToolStripMenuItem";
			this->stepOutToolStripMenuItem->Size = System::Drawing::Size(65, 20);
			this->stepOutToolStripMenuItem->Text = L"Step Ou&t";
			this->stepOutToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmRun::stepOutToolStripMenuItem_Click);
			// 
			// animateToolStripMenuItem
			// 
			this->animateToolStripMenuItem->Name = L"animateToolStripMenuItem";
			this->animateToolStripMenuItem->Size = System::Drawing::Size(64, 20);
			this->animateToolStripMenuItem->Text = L"&Animate";
			this->animateToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmRun::animateToolStripMenuItem_Click);
			// 
			// stopToolStripMenuItem
			// 
			this->stopToolStripMenuItem->Name = L"stopToolStripMenuItem";
			this->stopToolStripMenuItem->Size = System::Drawing::Size(43, 20);
			this->stopToolStripMenuItem->Text = L"&Stop";
			this->stopToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmRun::stopToolStripMenuItem_Click);
			// 
			// resetToolStripMenuItem
			// 
			this->resetToolStripMenuItem->Name = L"resetToolStripMenuItem";
			this->resetToolStripMenuItem->Size = System::Drawing::Size(47, 20);
			this->resetToolStripMenuItem->Text = L"&Reset";
			this->resetToolStripMenuItem->Click += gcnew System::EventHandler(this, &frmRun::resetToolStripMenuItem_Click);
			// 
			// timer1
			// 
			this->timer1->Tick += gcnew System::EventHandler(this, &frmRun::timer1_Tick);
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(568, 38);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(79, 13);
			this->label1->TabIndex = 15;
			this->label1->Text = L"Animation Rate";
			// 
			// progressBar1
			// 
			this->progressBar1->Location = System::Drawing::Point(571, 231);
			this->progressBar1->Name = L"progressBar1";
			this->progressBar1->Size = System::Drawing::Size(158, 23);
			this->progressBar1->TabIndex = 16;
			// 
			// numSteps
			// 
			this->numSteps->DecimalPlaces = 3;
			this->numSteps->Increment = System::Decimal(gcnew cli::array< System::Int32 >(4) {10, 0, 0, 0});
			this->numSteps->Location = System::Drawing::Point(571, 177);
			this->numSteps->Maximum = System::Decimal(gcnew cli::array< System::Int32 >(4) {100000, 0, 0, 0});
			this->numSteps->Name = L"numSteps";
			this->numSteps->Size = System::Drawing::Size(120, 20);
			this->numSteps->TabIndex = 17;
			this->numSteps->ValueChanged += gcnew System::EventHandler(this, &frmRun::numSteps_ValueChanged);
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(568, 161);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(129, 13);
			this->label2->TabIndex = 18;
			this->label2->Text = L"Number of Steps (1,000\'s)";
			// 
			// button1
			// 
			this->button1->Location = System::Drawing::Point(571, 202);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(75, 23);
			this->button1->TabIndex = 19;
			this->button1->Text = L"Run";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &frmRun::button1_Click);
			// 
			// backgroundWorker1
			// 
			this->backgroundWorker1->WorkerReportsProgress = true;
			this->backgroundWorker1->WorkerSupportsCancellation = true;
			// 
			// button2
			// 
			this->button2->Location = System::Drawing::Point(652, 202);
			this->button2->Name = L"button2";
			this->button2->Size = System::Drawing::Size(75, 23);
			this->button2->TabIndex = 20;
			this->button2->Text = L"Stop";
			this->button2->UseVisualStyleBackColor = true;
			this->button2->Click += gcnew System::EventHandler(this, &frmRun::button2_Click);
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(571, 137);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(120, 13);
			this->label3->TabIndex = 21;
			this->label3->Text = L"Run at Maximum Speed";
			// 
			// lblMHz
			// 
			this->lblMHz->AutoSize = true;
			this->lblMHz->Location = System::Drawing::Point(571, 266);
			this->lblMHz->Name = L"lblMHz";
			this->lblMHz->Size = System::Drawing::Size(47, 13);
			this->lblMHz->TabIndex = 22;
			this->lblMHz->Text = L"0.0 MHz";
			this->lblMHz->MouseHover += gcnew System::EventHandler(this, &frmRun::lblMHz_MouseHover);
			// 
			// toolTipMHz
			// 
			this->toolTipMHz->IsBalloon = true;
			// 
			// checkBox1
			// 
			this->checkBox1->AutoSize = true;
			this->checkBox1->Checked = true;
			this->checkBox1->CheckState = System::Windows::Forms::CheckState::Checked;
			this->checkBox1->Location = System::Drawing::Point(574, 301);
			this->checkBox1->Name = L"checkBox1";
			this->checkBox1->Size = System::Drawing::Size(57, 17);
			this->checkBox1->TabIndex = 23;
			this->checkBox1->Text = L"32 bits";
			this->checkBox1->UseVisualStyleBackColor = true;
			this->checkBox1->CheckedChanged += gcnew System::EventHandler(this, &frmRun::checkBox1_CheckedChanged);
			// 
			// nudSegmentModel
			// 
			this->nudSegmentModel->Location = System::Drawing::Point(679, 331);
			this->nudSegmentModel->Maximum = System::Decimal(gcnew cli::array< System::Int32 >(4) {2, 0, 0, 0});
			this->nudSegmentModel->Name = L"nudSegmentModel";
			this->nudSegmentModel->Size = System::Drawing::Size(48, 20);
			this->nudSegmentModel->TabIndex = 24;
			this->nudSegmentModel->Value = System::Decimal(gcnew cli::array< System::Int32 >(4) {2, 0, 0, 0});
			this->nudSegmentModel->ValueChanged += gcnew System::EventHandler(this, &frmRun::nudSegmentModel_ValueChanged);
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(570, 334);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(104, 13);
			this->label4->TabIndex = 25;
			this->label4->Text = L"Segmentation Model";
			// 
			// frmRun
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(741, 501);
			this->Controls->Add(this->label4);
			this->Controls->Add(this->nudSegmentModel);
			this->Controls->Add(this->checkBox1);
			this->Controls->Add(this->lblMHz);
			this->Controls->Add(this->label3);
			this->Controls->Add(this->button2);
			this->Controls->Add(this->button1);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->numSteps);
			this->Controls->Add(this->progressBar1);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->toolStrip1);
			this->Controls->Add(this->menuStrip1);
			this->Controls->Add(this->trackBar1);
			this->Controls->Add(this->listBoxCode);
			this->Controls->Add(this->listBoxBytes);
			this->Controls->Add(this->listBoxAdr);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedSingle;
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"frmRun";
			this->Text = L"emuThor - Run";
			this->WindowState = System::Windows::Forms::FormWindowState::Maximized;
			this->FormClosing += gcnew System::Windows::Forms::FormClosingEventHandler(this, &frmRun::frmRun_FormClosing);
			this->Load += gcnew System::EventHandler(this, &frmRun::frmRun_Load);
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->trackBar1))->EndInit();
			this->toolStrip1->ResumeLayout(false);
			this->toolStrip1->PerformLayout();
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numSteps))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->nudSegmentModel))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
private: void InitializeBackgroundWorker() {
	backgroundWorker1->DoWork += gcnew DoWorkEventHandler(this, &frmRun::backgroundWorker1_DoWork);
	backgroundWorker1->RunWorkerCompleted += gcnew RunWorkerCompletedEventHandler(this, &frmRun::backgroundWorker1_RunWorkerCompleted);
	backgroundWorker1->ProgressChanged += gcnew ProgressChangedEventHandler(this, &frmRun::backgroundWorker1_ProgressChanged);
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
            mut->WaitOne();
			if (ae==system1.cpu2.pc) {
				mut->ReleaseMutex();
				return ad;
			}
			mut->ReleaseMutex();
		dstr = da.Disassem(ae,&nb);
		ae += nb;
		}
	}
	return as;
}

public: void UpdateListBoxes()
		 {
			 int nn,nb,kk;
			 char buf2[100];
			 std::string dstr;
			 std::string buf;
			 int adr[32];
			 int adf;
			 int ad;

			 mut->WaitOne();
			 ad = PCIsInList(system1.cpu2.pc-32);
			 mut->ReleaseMutex();
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
					mut->WaitOne();
					sprintf(&buf2[strlen(buf2)], "%02X ", system1.ReadByte(ad));
					mut->ReleaseMutex();
					ad++;
				}
				buf = std::string(buf2);
				this->listBoxBytes->Items->Add(gcnew String(buf.c_str()));
				this->listBoxCode->Items->Add(gcnew String(dstr.c_str()));
			 }
			 for (nn = 0; nn < 32; nn++) {
				 mut->WaitOne();
				 adf = system1.cpu2.pc;
				 mut->ReleaseMutex();
				if (adr[nn]==adf) {
					this->listBoxAdr->SetSelected(nn,true);
					this->listBoxBytes->SetSelected(nn,true);
					this->listBoxCode->SetSelected(nn,true);
				}
			 }
		 }
public: void DoStepInto() {
//		 	 animate = false;
//			 isRunning = false;
			 char buf[100];
			 mut->WaitOne();
			 system1.Step();
			 mut->ReleaseMutex();
			 UpdateListBoxes();
//			 sprintf(buf, "%04X", system1.leds);
//			 lblLEDS->Text = gcnew String(buf);
//			 pictureBox1->Refresh();
		 }
public: void DoStepOut() {
			 int xx;
			 mut->WaitOne();
			 step_depth = system1.cpu2.sub_depth;
			 stepout = true;
			 animate = false;
			 fullspeed = true;
			 isRunning = true;
			 mut->ReleaseMutex();
			 int ticks = (int)(1000 * 1000);

			 this->button1->Enabled = false;
			 backgroundWorker1->RunWorkerAsync(ticks);
			 this->button2->Enabled = true;
			 progressBar1->Value = 0;
			 //UpdateListBoxes();
			 //this->fullSpeedToolStripMenuItem->Checked = true;
		}
public: void DoStepOver() {
			 mut->WaitOne();
			 stepover_pc = system1.cpu2.pc;
			 stepover_depth = system1.cpu2.sub_depth;
			 stepover = true;
			 animate = false;
			 fullspeed = true;
			 isRunning = true;
			 mut->ReleaseMutex();
			 UpdateListBoxes();
//			 this->fullSpeedToolStripMenuItem->Checked = true;
		}
public: void DoStopButton() {
			 timer1->Enabled = false;
			 mut->WaitOne();
			 animate = false;
			 isRunning = false;
//			 cpu2.brk = true;
			 fullspeed = false;
			 mut->ReleaseMutex();
			 UpdateListBoxes();
//			 this->fullSpeedToolStripMenuItem->Checked = false;
//			 this->animateFastToolStripMenuItem->Checked = false;
//			 this->timer1->Interval = 100;
		 }
private: void Reset() {
			 int ad;
			 mut->WaitOne();
			 system1.Reset();
			 ad = system1.cpu2.pc-32;
			 mut->ReleaseMutex();
			 UpdateListBoxes();
		 }

private: System::Void toolStripButton8_Click(System::Object^  sender, System::EventArgs^  e) {
			 Reset();
			 }
private: System::Void toolStripButton7_Click(System::Object^  sender, System::EventArgs^  e) {
//			 frmBreakpoints^ form = gcnew frmBreakpoints(mut);
//			 form->MdiParent = this->MdiParent;
//			 form->ShowDialog();
		 }
private: System::Void toolStripButton4_Click(System::Object^  sender, System::EventArgs^  e) {
				 int xx;
				 int ticks = (int)(this->numSteps->Value * 1000);

				 this->button1->Enabled = false;
				 backgroundWorker1->RunWorkerAsync(ticks);
				 this->button2->Enabled = true;
				 progressBar1->Value = 0;
		 }
private: System::Void toolStripButton1_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepInto();
		 }
private: System::Void toolStripButton5_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStopButton();
		 }
private: System::Void toolStripButton2_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepOver();
		 }
private: System::Void stepToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepInto();
		 }
private: System::Void toolStripButton3_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepOut();
		 }
private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 static int tt = 0;

			 mut->WaitOne();
			 system1.Step();
  			 mut->ReleaseMutex();
	
			 if (this->timer1->Interval < 10)
				 tt += 1;
				 if (tt == 10 * this->timer1->Interval) {
					 tt = 0;
					 UpdateListBoxes();
				 }
			 else
				UpdateListBoxes();
		 }
private: System::Void animateToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 timer1->Enabled = true;
			 timer1->Interval = (1<<(12-trackBar1->Value));
		 }
private: System::Void trackBar1_Scroll(System::Object^  sender, System::EventArgs^  e) {
			 timer1->Interval = (1<<(12-trackBar1->Value));
		 }
private: System::Void menuStrip1_ItemClicked(System::Object^  sender, System::Windows::Forms::ToolStripItemClickedEventArgs^  e) {
		 }
private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {
				 int xx;
				 int ticks = (int)(this->numSteps->Value * 1000);

				 this->button1->Enabled = false;
				 backgroundWorker1->RunWorkerAsync(ticks);
				 this->button2->Enabled = true;
				 progressBar1->Value = 0;
		 }
private: System::Void button2_Click(System::Object^  sender, System::EventArgs^  e) {
				 backgroundWorker1->CancelAsync();
				 this->button2->Enabled = false;
		 }
	private: void backgroundWorker1_DoWork(Object^ sender, DoWorkEventArgs^ e) {
		int xx;
		BackgroundWorker^ worker = dynamic_cast<BackgroundWorker^>(sender);
		int div = safe_cast<Int32>(e->Argument) / 100;
		int percentComplete = 0;

		mut->WaitOne();
		isRunning = true;
	    stopwatch->Reset();
		stopwatch->Start();
		startTick = system1.cpu2.tick;
		mut->ReleaseMutex();
		for (xx = 0; xx < safe_cast<Int32>(e->Argument) && isRunning; xx++) {
			if (worker->CancellationPending) {
				e->Cancel = true;
				xx = safe_cast<Int32>(e->Argument);
			}
			if (xx % div == 0) {
				worker->ReportProgress(percentComplete);
				percentComplete++;
			}
			mut->WaitOne();
			system1.Run();
			mut->ReleaseMutex();
		}
		mut->WaitOne();
    	stopwatch->Stop();
		stopTick = system1.cpu2.tick;
		isRunning = false;
		mut->ReleaseMutex();
		e->Result = 0;
	}
	private: void backgroundWorker1_ProgressChanged(Object^ sender, ProgressChangedEventArgs^ e) {
		this->progressBar1->Value = e->ProgressPercentage;
	}
	private: void backgroundWorker1_RunWorkerCompleted( Object^ , RunWorkerCompletedEventArgs^ e) {
		char buf[100];
		if (e->Error != nullptr) {
			MessageBox::Show(e->Error->Message);
		}
		else if (e->Cancelled) {
			/* possibly display cancelled message in a label */
		}
		else {
			/* possibly display result status */
		}
		__int64 elapsed = stopwatch->ElapsedMilliseconds;
		double MHz = ((double)(stopTick-startTick)/(double)elapsed)/(double)1000;
		sprintf(buf,"%3.3g MHz", MHz);
		this->lblMHz->Text = gcnew String(buf);
		this->button2->Enabled = false;
		this->button1->Enabled = true;
		this->progressBar1->Value = 0;
		this->UpdateListBoxes();
	}
private: System::Void frmRun_FormClosing(System::Object^  sender, System::Windows::Forms::FormClosingEventArgs^  e) {
			 if (e->CloseReason==CloseReason::UserClosing)
				 e->Cancel = true;
		 }
private: System::Void resetToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 Reset();
		 }
private: System::Void stopToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStopButton();
		 }
private: System::Void stepOverToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepOver();
		 }
private: System::Void stepOutToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepOut();
		 }
private: System::Void stepIntoToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 DoStepInto();
		 }
private: System::Void frmRun_Load(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void lblMHz_MouseHover(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void checkBox1_CheckedChanged(System::Object^  sender, System::EventArgs^  e) {
			 system1.cpu2._32bit = this->checkBox1->Checked;
		 }
private: System::Void nudSegmentModel_ValueChanged(System::Object^  sender, System::EventArgs^  e) {
			 system1.cpu2.segmodel = (int)this->nudSegmentModel->Value;
		 }
private: System::Void numSteps_ValueChanged(System::Object^  sender, System::EventArgs^  e) {
		 }
};
}
