#pragma once
#include "stdafx.h"

extern clsSystem system1;
extern bool isRunning;

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Threading;

	/// <summary>
	/// Summary for fmrFreeRun
	/// </summary>
	public ref class fmrFreeRun : public System::Windows::Forms::Form
	{
	public:
		Mutex^ mut;
		fmrFreeRun(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			InitializeBackgroundWorker();
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~fmrFreeRun()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::Label^  label1;
	protected: 
	private: System::Windows::Forms::NumericUpDown^  numSeconds;
	private: System::Windows::Forms::Button^  button1;
	private: System::Windows::Forms::Button^  button2;
	private: System::Windows::Forms::ProgressBar^  progressBar1;
	private: System::ComponentModel::BackgroundWorker^  backgroundWorker1;

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
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->numSeconds = (gcnew System::Windows::Forms::NumericUpDown());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->button2 = (gcnew System::Windows::Forms::Button());
			this->progressBar1 = (gcnew System::Windows::Forms::ProgressBar());
			this->backgroundWorker1 = (gcnew System::ComponentModel::BackgroundWorker());
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numSeconds))->BeginInit();
			this->SuspendLayout();
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(20, 20);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(86, 26);
			this->label1->TabIndex = 0;
			this->label1->Text = L"Number of Steps\r\n(1,000\'s)";
			// 
			// numSeconds
			// 
			this->numSeconds->Location = System::Drawing::Point(112, 18);
			this->numSeconds->Maximum = System::Decimal(gcnew cli::array< System::Int32 >(4) {100000000, 0, 0, 0});
			this->numSeconds->Name = L"numSeconds";
			this->numSeconds->Size = System::Drawing::Size(101, 20);
			this->numSeconds->TabIndex = 1;
			// 
			// button1
			// 
			this->button1->Location = System::Drawing::Point(138, 101);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(75, 23);
			this->button1->TabIndex = 2;
			this->button1->Text = L"Start";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &fmrFreeRun::button1_Click);
			// 
			// button2
			// 
			this->button2->DialogResult = System::Windows::Forms::DialogResult::Cancel;
			this->button2->Enabled = false;
			this->button2->Location = System::Drawing::Point(23, 101);
			this->button2->Name = L"button2";
			this->button2->Size = System::Drawing::Size(75, 23);
			this->button2->TabIndex = 3;
			this->button2->Text = L"Cancel";
			this->button2->UseVisualStyleBackColor = true;
			this->button2->Click += gcnew System::EventHandler(this, &fmrFreeRun::button2_Click);
			// 
			// progressBar1
			// 
			this->progressBar1->Location = System::Drawing::Point(23, 59);
			this->progressBar1->Name = L"progressBar1";
			this->progressBar1->Size = System::Drawing::Size(190, 23);
			this->progressBar1->TabIndex = 4;
			// 
			// backgroundWorker1
			// 
			this->backgroundWorker1->WorkerReportsProgress = true;
			this->backgroundWorker1->WorkerSupportsCancellation = true;
			// 
			// fmrFreeRun
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(234, 141);
			this->Controls->Add(this->progressBar1);
			this->Controls->Add(this->button2);
			this->Controls->Add(this->button1);
			this->Controls->Add(this->numSeconds);
			this->Controls->Add(this->label1);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedSingle;
			this->MaximizeBox = false;
			this->Name = L"fmrFreeRun";
			this->SizeGripStyle = System::Windows::Forms::SizeGripStyle::Hide;
			this->Text = L"emuThor - Free Run";
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numSeconds))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
private: void InitializeBackgroundWorker() {
	backgroundWorker1->DoWork += gcnew DoWorkEventHandler(this, &fmrFreeRun::backgroundWorker1_DoWork);
	backgroundWorker1->RunWorkerCompleted += gcnew RunWorkerCompletedEventHandler(this, &fmrFreeRun::backgroundWorker1_RunWorkerCompleted);
	backgroundWorker1->ProgressChanged += gcnew ProgressChangedEventHandler(this, &fmrFreeRun::backgroundWorker1_ProgressChanged);
}
	private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {
				 int xx;
				 int ticks = (int)this->numSeconds->Value * 1000;

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
		isRunning = false;
		mut->ReleaseMutex();
		e->Result = 0;
	}
	private: void backgroundWorker1_ProgressChanged(Object^ sender, ProgressChangedEventArgs^ e) {
		this->progressBar1->Value = e->ProgressPercentage;
	}
	private: void backgroundWorker1_RunWorkerCompleted( Object^ , RunWorkerCompletedEventArgs^ e) {
		if (e->Error != nullptr) {
			MessageBox::Show(e->Error->Message);
		}
		else if (e->Cancelled) {
			/* possibly display cancelled message in a label */
		}
		else {
			/* possibly display result status */
		}
		this->button2->Enabled = false;
		this->button1->Enabled = true;
		this->progressBar1->Value = 0;
	}
};
}
