#include "stdafx.h"

#pragma once
FinitronClasses::MNGFile mngFile;

namespace FNG {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Runtime::InteropServices;
	using namespace FinitronClasses;

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
	private: System::Windows::Forms::ToolStripMenuItem^  fileToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  mergeToolStripMenuItem;
	private: System::Windows::Forms::GroupBox^  groupBox1;
	private: System::Windows::Forms::TextBox^  textBox1;
	private: System::Windows::Forms::Label^  label7;
	private: System::Windows::Forms::Label^  label6;
	private: System::Windows::Forms::NumericUpDown^  numericUpDown6;
	private: System::Windows::Forms::Label^  label5;
	private: System::Windows::Forms::NumericUpDown^  numericUpDown5;
	private: System::Windows::Forms::Label^  label4;
	private: System::Windows::Forms::NumericUpDown^  numericUpDown4;
	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::NumericUpDown^  numericUpDown3;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::NumericUpDown^  numericUpDown2;
	private: System::Windows::Forms::NumericUpDown^  numericUpDown1;
	private: System::Windows::Forms::PictureBox^  pictureBox1;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::ListBox^  listBox1;
	private: System::Windows::Forms::SaveFileDialog^  saveFileDialog1;
	private: System::Windows::Forms::ToolStripMenuItem^  displayToolStripMenuItem;
	private: System::Windows::Forms::Button^  button1;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::Windows::Forms::TrackBar^  trackBar1;
	private: System::Windows::Forms::Label^  label8;
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
			this->fileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->mergeToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->displayToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->groupBox1 = (gcnew System::Windows::Forms::GroupBox());
			this->textBox1 = (gcnew System::Windows::Forms::TextBox());
			this->label7 = (gcnew System::Windows::Forms::Label());
			this->label6 = (gcnew System::Windows::Forms::Label());
			this->numericUpDown6 = (gcnew System::Windows::Forms::NumericUpDown());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->numericUpDown5 = (gcnew System::Windows::Forms::NumericUpDown());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->numericUpDown4 = (gcnew System::Windows::Forms::NumericUpDown());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->numericUpDown3 = (gcnew System::Windows::Forms::NumericUpDown());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->numericUpDown2 = (gcnew System::Windows::Forms::NumericUpDown());
			this->numericUpDown1 = (gcnew System::Windows::Forms::NumericUpDown());
			this->pictureBox1 = (gcnew System::Windows::Forms::PictureBox());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->listBox1 = (gcnew System::Windows::Forms::ListBox());
			this->saveFileDialog1 = (gcnew System::Windows::Forms::SaveFileDialog());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->trackBar1 = (gcnew System::Windows::Forms::TrackBar());
			this->label8 = (gcnew System::Windows::Forms::Label());
			this->menuStrip1->SuspendLayout();
			this->groupBox1->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown6))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown5))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown4))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown3))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown2))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown1))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->BeginInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->trackBar1))->BeginInit();
			this->SuspendLayout();
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->fileToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(969, 24);
			this->menuStrip1->TabIndex = 0;
			this->menuStrip1->Text = L"menuStrip1";
			// 
			// fileToolStripMenuItem
			// 
			this->fileToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->mergeToolStripMenuItem, 
				this->displayToolStripMenuItem});
			this->fileToolStripMenuItem->Name = L"fileToolStripMenuItem";
			this->fileToolStripMenuItem->Size = System::Drawing::Size(37, 20);
			this->fileToolStripMenuItem->Text = L"&File";
			// 
			// mergeToolStripMenuItem
			// 
			this->mergeToolStripMenuItem->Name = L"mergeToolStripMenuItem";
			this->mergeToolStripMenuItem->Size = System::Drawing::Size(112, 22);
			this->mergeToolStripMenuItem->Text = L"&Merge";
			this->mergeToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::mergeToolStripMenuItem_Click);
			// 
			// displayToolStripMenuItem
			// 
			this->displayToolStripMenuItem->Name = L"displayToolStripMenuItem";
			this->displayToolStripMenuItem->Size = System::Drawing::Size(112, 22);
			this->displayToolStripMenuItem->Text = L"&Display";
			this->displayToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::displayToolStripMenuItem_Click);
			// 
			// groupBox1
			// 
			this->groupBox1->Controls->Add(this->textBox1);
			this->groupBox1->Controls->Add(this->label7);
			this->groupBox1->Controls->Add(this->label6);
			this->groupBox1->Controls->Add(this->numericUpDown6);
			this->groupBox1->Controls->Add(this->label5);
			this->groupBox1->Controls->Add(this->numericUpDown5);
			this->groupBox1->Controls->Add(this->label4);
			this->groupBox1->Controls->Add(this->numericUpDown4);
			this->groupBox1->Controls->Add(this->label3);
			this->groupBox1->Controls->Add(this->numericUpDown3);
			this->groupBox1->Controls->Add(this->label2);
			this->groupBox1->Controls->Add(this->label1);
			this->groupBox1->Controls->Add(this->numericUpDown2);
			this->groupBox1->Controls->Add(this->numericUpDown1);
			this->groupBox1->Location = System::Drawing::Point(28, 38);
			this->groupBox1->Name = L"groupBox1";
			this->groupBox1->Size = System::Drawing::Size(286, 248);
			this->groupBox1->TabIndex = 16;
			this->groupBox1->TabStop = false;
			this->groupBox1->Text = L"MNG Header";
			// 
			// textBox1
			// 
			this->textBox1->Location = System::Drawing::Point(148, 207);
			this->textBox1->Name = L"textBox1";
			this->textBox1->Size = System::Drawing::Size(100, 20);
			this->textBox1->TabIndex = 29;
			// 
			// label7
			// 
			this->label7->AutoSize = true;
			this->label7->Location = System::Drawing::Point(39, 209);
			this->label7->Name = L"label7";
			this->label7->Size = System::Drawing::Size(32, 13);
			this->label7->TabIndex = 28;
			this->label7->Text = L"Flags";
			// 
			// label6
			// 
			this->label6->AutoSize = true;
			this->label6->Location = System::Drawing::Point(39, 183);
			this->label6->Name = L"label6";
			this->label6->Size = System::Drawing::Size(53, 13);
			this->label6->TabIndex = 27;
			this->label6->Text = L"Play Time";
			// 
			// numericUpDown6
			// 
			this->numericUpDown6->Location = System::Drawing::Point(148, 181);
			this->numericUpDown6->Maximum = System::Decimal(gcnew cli::array< System::Int32 >(4) {10000000, 0, 0, 0});
			this->numericUpDown6->Name = L"numericUpDown6";
			this->numericUpDown6->Size = System::Drawing::Size(68, 20);
			this->numericUpDown6->TabIndex = 26;
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Location = System::Drawing::Point(39, 157);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(67, 13);
			this->label5->TabIndex = 25;
			this->label5->Text = L"Frame Count";
			// 
			// numericUpDown5
			// 
			this->numericUpDown5->Location = System::Drawing::Point(148, 155);
			this->numericUpDown5->Name = L"numericUpDown5";
			this->numericUpDown5->Size = System::Drawing::Size(68, 20);
			this->numericUpDown5->TabIndex = 24;
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(39, 131);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(64, 13);
			this->label4->TabIndex = 23;
			this->label4->Text = L"Layer Count";
			// 
			// numericUpDown4
			// 
			this->numericUpDown4->Location = System::Drawing::Point(148, 129);
			this->numericUpDown4->Name = L"numericUpDown4";
			this->numericUpDown4->Size = System::Drawing::Size(68, 20);
			this->numericUpDown4->TabIndex = 22;
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(39, 105);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(92, 13);
			this->label3->TabIndex = 21;
			this->label3->Text = L"Ticks Per Second";
			// 
			// numericUpDown3
			// 
			this->numericUpDown3->Location = System::Drawing::Point(148, 103);
			this->numericUpDown3->Maximum = System::Decimal(gcnew cli::array< System::Int32 >(4) {1000, 0, 0, 0});
			this->numericUpDown3->Name = L"numericUpDown3";
			this->numericUpDown3->Size = System::Drawing::Size(68, 20);
			this->numericUpDown3->TabIndex = 20;
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(39, 79);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(70, 13);
			this->label2->TabIndex = 19;
			this->label2->Text = L"Frame Height";
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(39, 53);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(67, 13);
			this->label1->TabIndex = 18;
			this->label1->Text = L"Frame Width";
			// 
			// numericUpDown2
			// 
			this->numericUpDown2->Location = System::Drawing::Point(148, 77);
			this->numericUpDown2->Maximum = System::Decimal(gcnew cli::array< System::Int32 >(4) {4096, 0, 0, 0});
			this->numericUpDown2->Minimum = System::Decimal(gcnew cli::array< System::Int32 >(4) {1, 0, 0, 0});
			this->numericUpDown2->Name = L"numericUpDown2";
			this->numericUpDown2->Size = System::Drawing::Size(68, 20);
			this->numericUpDown2->TabIndex = 17;
			this->numericUpDown2->Value = System::Decimal(gcnew cli::array< System::Int32 >(4) {480, 0, 0, 0});
			// 
			// numericUpDown1
			// 
			this->numericUpDown1->Location = System::Drawing::Point(148, 51);
			this->numericUpDown1->Maximum = System::Decimal(gcnew cli::array< System::Int32 >(4) {4096, 0, 0, 0});
			this->numericUpDown1->Minimum = System::Decimal(gcnew cli::array< System::Int32 >(4) {1, 0, 0, 0});
			this->numericUpDown1->Name = L"numericUpDown1";
			this->numericUpDown1->Size = System::Drawing::Size(68, 20);
			this->numericUpDown1->TabIndex = 16;
			this->numericUpDown1->Value = System::Decimal(gcnew cli::array< System::Int32 >(4) {640, 0, 0, 0});
			// 
			// pictureBox1
			// 
			this->pictureBox1->BackgroundImageLayout = System::Windows::Forms::ImageLayout::Center;
			this->pictureBox1->Location = System::Drawing::Point(320, 78);
			this->pictureBox1->Name = L"pictureBox1";
			this->pictureBox1->Size = System::Drawing::Size(640, 480);
			this->pictureBox1->SizeMode = System::Windows::Forms::PictureBoxSizeMode::AutoSize;
			this->pictureBox1->TabIndex = 17;
			this->pictureBox1->TabStop = false;
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->FileName = L"openFileDialog1";
			// 
			// listBox1
			// 
			this->listBox1->AllowDrop = true;
			this->listBox1->FormattingEnabled = true;
			this->listBox1->Location = System::Drawing::Point(28, 334);
			this->listBox1->Name = L"listBox1";
			this->listBox1->Size = System::Drawing::Size(286, 225);
			this->listBox1->Sorted = true;
			this->listBox1->TabIndex = 18;
			this->listBox1->DragDrop += gcnew System::Windows::Forms::DragEventHandler(this, &Form1::listBox1_DragDrop);
			this->listBox1->DragEnter += gcnew System::Windows::Forms::DragEventHandler(this, &Form1::listBox1_DragEnter);
			// 
			// button1
			// 
			this->button1->Location = System::Drawing::Point(320, 27);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(75, 23);
			this->button1->TabIndex = 19;
			this->button1->Text = L"button1";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &Form1::button1_Click);
			// 
			// timer1
			// 
			this->timer1->Interval = 20;
			this->timer1->Tick += gcnew System::EventHandler(this, &Form1::timer1_Tick);
			// 
			// trackBar1
			// 
			this->trackBar1->Location = System::Drawing::Point(589, 27);
			this->trackBar1->Minimum = 2;
			this->trackBar1->Name = L"trackBar1";
			this->trackBar1->Size = System::Drawing::Size(104, 45);
			this->trackBar1->TabIndex = 20;
			this->trackBar1->Value = 5;
			this->trackBar1->Scroll += gcnew System::EventHandler(this, &Form1::trackBar1_Scroll);
			// 
			// label8
			// 
			this->label8->AutoSize = true;
			this->label8->Location = System::Drawing::Point(25, 305);
			this->label8->Name = L"label8";
			this->label8->Size = System::Drawing::Size(179, 26);
			this->label8->TabIndex = 21;
			this->label8->Text = L"Drag and Drop files to merge\r\nFrames must be in alphabetical order";
			// 
			// Form1
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(969, 571);
			this->Controls->Add(this->label8);
			this->Controls->Add(this->trackBar1);
			this->Controls->Add(this->button1);
			this->Controls->Add(this->listBox1);
			this->Controls->Add(this->pictureBox1);
			this->Controls->Add(this->groupBox1);
			this->Controls->Add(this->menuStrip1);
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"Form1";
			this->Text = L"Form1";
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->groupBox1->ResumeLayout(false);
			this->groupBox1->PerformLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown6))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown5))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown4))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown3))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown2))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->numericUpDown1))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->EndInit();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->trackBar1))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void mergeToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
				 int nn;
				 char buf[20];
				 this->saveFileDialog1->ShowDialog();
	 			char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->saveFileDialog1->FileName);
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
				std::ofstream fp_out;
				std::ifstream fp_in;
				fp_out.open(std::string(str),std::ios::out|std::ifstream::binary);
				mngFile.WriteHeader(fp_out);
				mngFile.mhdr.FrameWidth = (int)numericUpDown1->Value;
				mngFile.mhdr.FrameHeight = (int)numericUpDown2->Value;
				mngFile.mhdr.TicksPerSecond = (int)numericUpDown3->Value;
				mngFile.mhdr.LayerCount = (int)numericUpDown4->Value;
				mngFile.mhdr.FrameCount = (int)numericUpDown5->Value;
				mngFile.mhdr.PlayTime = (int)numericUpDown6->Value;
				mngFile.mhdr.Write(fp_out);
				mngFile.WriteTerm(fp_out);
				for (nn = 0; nn < mngFile.mhdr.FrameCount; nn++) {
		 			char* str = (char*)(void*)Marshal::StringToHGlobalAnsi((String^)this->listBox1->Items[nn]);
					fp_in.open(std::string(str),std::ios::in|std::ifstream::binary);
					fp_in.read((char *)buf,8);	// throw away PNG header
					while (!fp_in.eof()) {
						fp_in.read((char *)buf,1);
						if (!fp_in.eof())
							fp_out.write((char *)buf,1);
					}
					fp_in.close();
				}
//				fo.load(std::string(str));
//				fo.BackupPalette();
//				foc = fo.Clone();
//				CreateBitmap(&fo);
				mngFile.WriteEnd(fp_out);
				fp_out.close();
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
			 }
private: System::Void listBox1_DragEnter(System::Object^  sender, System::Windows::Forms::DragEventArgs^  e) {
			if(e->Data->GetDataPresent(DataFormats::FileDrop))
				e->Effect = DragDropEffects::All;
			else
				e->Effect = DragDropEffects::None;
		 }
private: System::Void listBox1_DragDrop(System::Object^  sender, System::Windows::Forms::DragEventArgs^  e) {
			array<String^>^s;
			s = (array<String^>^)e->Data->GetData(DataFormats::FileDrop, false);
			int i;
			for(i = 0; i < s->Length; i++)
				listBox1->Items->Add(s[i]);
			numericUpDown4->Value = listBox1->Items->Count+1;
			numericUpDown5->Value = listBox1->Items->Count;
		 }
private: System::Void displayToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
				 this->openFileDialog1->ShowDialog();
	 			char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(this->openFileDialog1->FileName);
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
				mngFile.Load(std::string(str));
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default;
				pictureBox1->Image = mngFile.pngs[1].bmp;
		 }
private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {
			 timer1->Enabled = true;
		 }
private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 static int nn;

			 if (nn >= mngFile.mhdr.FrameCount)
				 nn = 0;
				pictureBox1->Image = mngFile.pngs[nn].bmp;
			nn = nn + 1;
		 }
private: System::Void trackBar1_Scroll(System::Object^  sender, System::EventArgs^  e) {
			 timer1->Interval = (int)pow(2,(double)trackBar1->Value);
		 }
};
}

