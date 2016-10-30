#pragma once
#include "stdafx.h"

extern Finray::RayTracer rayTracer;
extern char master_filebuf[10000000];
extern Finray::Color backGround;

namespace Finray {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Drawing::Imaging;

	/// <summary>
	/// Summary for frmRay
	/// </summary>
	public ref class frmRay : public System::Windows::Forms::Form
	{
	public:
		frmRay(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
//			AnObject *objectPtr;
//			Graphics^ gr;

			ViewWidth = 640;
			ViewHeight = 480;
			bmps = gcnew array<Bitmap^>(100);
			bmp = gcnew Bitmap(640,480,PixelFormat::Format32bppArgb);

//			parser.ParseBuffer(master_filebuf);
/*
				"view_point {\n"
				"    location ( 0.0 -5.0 -110.0 )\n"
				"    direction ( 0.0 -0.05 1.0 )\n"
				"    up ( 0.0 1.0 0.0 )\n"
				"    right ( 1.333 0.0 0.0)\n"
				"}"
				);
*/		
			backGround.r = 0.0;
			backGround.g = 0.0;
			backGround.b = 0.0;
/*
			rayTracer.viewPoint->loc.x = 0.0;
			rayTracer.viewPoint->loc.y = -5.0;
			rayTracer.viewPoint->loc.z = -110.0;
			rayTracer.viewPoint->dir.x = 0.0;
			rayTracer.viewPoint->dir.y = -0.05;
			rayTracer.viewPoint->dir.z = 1.0;
			rayTracer.viewPoint->up.x = 0.0;
			rayTracer.viewPoint->up.y = 1.0;
			rayTracer.viewPoint->up.z = 0.0;
			rayTracer.viewPoint->right.x = 1.333;
			rayTracer.viewPoint->right.y = 0.0;
			rayTracer.viewPoint->right.z = 0.0;
*/
/*
			objectPtr = new ASphere(0,0,0,25);
			objectPtr->SetAttrib(GOLD,SURFACE);

			objectPtr = new ASphere(-37.5,-30.0,-15.5,20);
			objectPtr->SetAttrib(MEDIUMFORESTGREEN,SURFACE);
*/
			/*
			objectPtr = new ASphere(52.5,-17.5,-18.0,20);
			objectPtr->SetAttrib(ORANGE1,SURFACE);

			objectPtr = new ASphere(-57.5,12.5,0.0,15);
			objectPtr->SetAttrib(COPPER,SURFACE);

			objectPtr = new ASphere(12.5,-32.5,-14.0,15);
			objectPtr->SetAttrib(COPPER,SURFACE);
*/
//			objectPtr = new APlane(0,0,-1,-200);
//			objectPtr->SetAttrib(MIDNIGHTBLUE,0.3,0.7,1.0,0.0,0.0,0.0);

//			objectPtr = new APlane(0,1,0,-50);
//			objectPtr->SetAttrib(BLUE,0.3,0.7,1.0,0.0,0.0,0.0);

//			objectPtr = new ALight(65,100,-100,1.0,1.0,1.0);

			gr = Graphics::FromImage(bmp);
//	        backgroundWorker1->RunWorkerAsync(gr);
//			this->button1->Enabled = true;
			 progressBar1->Value = 0;
			 cancelled = false;
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmRay()
		{
			if (components)
			{
				delete components;
			}
			rayTracer.DeleteList();
		}

	private: int ViewWidth;
	private: int ViewHeight;
	private: bool cancelled;
	private: Graphics^ gr;
	private:
		Bitmap^ bmp;
	private: array<Bitmap^>^ bmps;
	private: System::Windows::Forms::PictureBox^  pictureBox1;
	private: System::Windows::Forms::ProgressBar^  progressBar1;
	private: System::ComponentModel::BackgroundWorker^  backgroundWorker1;
	private: System::Windows::Forms::Button^  button1;
	private: System::Windows::Forms::Button^  button2;
	private: System::Windows::Forms::SaveFileDialog^  saveFileDialog1;
	private: System::Windows::Forms::Button^  button3;
	private: System::Windows::Forms::Button^  button4;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::Windows::Forms::RadioButton^  radioButton1;
	private: System::Windows::Forms::RadioButton^  radioButton2;
private: System::Windows::Forms::RadioButton^  radioButton3;
private: System::Windows::Forms::RadioButton^  radioButton4;
	private: System::ComponentModel::IContainer^  components;
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
			this->pictureBox1 = (gcnew System::Windows::Forms::PictureBox());
			this->progressBar1 = (gcnew System::Windows::Forms::ProgressBar());
			this->backgroundWorker1 = (gcnew System::ComponentModel::BackgroundWorker());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->button2 = (gcnew System::Windows::Forms::Button());
			this->saveFileDialog1 = (gcnew System::Windows::Forms::SaveFileDialog());
			this->button3 = (gcnew System::Windows::Forms::Button());
			this->button4 = (gcnew System::Windows::Forms::Button());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->radioButton1 = (gcnew System::Windows::Forms::RadioButton());
			this->radioButton2 = (gcnew System::Windows::Forms::RadioButton());
			this->radioButton3 = (gcnew System::Windows::Forms::RadioButton());
			this->radioButton4 = (gcnew System::Windows::Forms::RadioButton());
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->BeginInit();
			this->SuspendLayout();
			// 
			// pictureBox1
			// 
			this->pictureBox1->Location = System::Drawing::Point(85, 46);
			this->pictureBox1->Name = L"pictureBox1";
			this->pictureBox1->Size = System::Drawing::Size(640, 590);
			this->pictureBox1->SizeMode = System::Windows::Forms::PictureBoxSizeMode::StretchImage;
			this->pictureBox1->TabIndex = 0;
			this->pictureBox1->TabStop = false;
			// 
			// progressBar1
			// 
			this->progressBar1->Location = System::Drawing::Point(85, 12);
			this->progressBar1->Name = L"progressBar1";
			this->progressBar1->Size = System::Drawing::Size(640, 23);
			this->progressBar1->TabIndex = 1;
			// 
			// backgroundWorker1
			// 
			this->backgroundWorker1->WorkerReportsProgress = true;
			this->backgroundWorker1->WorkerSupportsCancellation = true;
			this->backgroundWorker1->DoWork += gcnew System::ComponentModel::DoWorkEventHandler(this, &frmRay::backgroundWorker1_DoWork);
			this->backgroundWorker1->ProgressChanged += gcnew System::ComponentModel::ProgressChangedEventHandler(this, &frmRay::backgroundWorker1_ProgressChanged);
			this->backgroundWorker1->RunWorkerCompleted += gcnew System::ComponentModel::RunWorkerCompletedEventHandler(this, &frmRay::backgroundWorker1_RunWorkerCompleted);
			// 
			// button1
			// 
			this->button1->Location = System::Drawing::Point(4, 12);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(75, 23);
			this->button1->TabIndex = 2;
			this->button1->Text = L"Cancel";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &frmRay::button1_Click);
			// 
			// button2
			// 
			this->button2->Location = System::Drawing::Point(4, 78);
			this->button2->Name = L"button2";
			this->button2->Size = System::Drawing::Size(75, 23);
			this->button2->TabIndex = 3;
			this->button2->Text = L"Save";
			this->button2->UseVisualStyleBackColor = true;
			this->button2->Click += gcnew System::EventHandler(this, &frmRay::button2_Click);
			// 
			// saveFileDialog1
			// 
			this->saveFileDialog1->DefaultExt = L"png";
			this->saveFileDialog1->FileName = L"Finray1";
			// 
			// button3
			// 
			this->button3->Location = System::Drawing::Point(4, 46);
			this->button3->Name = L"button3";
			this->button3->Size = System::Drawing::Size(75, 23);
			this->button3->TabIndex = 4;
			this->button3->Text = L"Start";
			this->button3->UseVisualStyleBackColor = true;
			this->button3->Click += gcnew System::EventHandler(this, &frmRay::button3_Click);
			// 
			// button4
			// 
			this->button4->Location = System::Drawing::Point(4, 117);
			this->button4->Name = L"button4";
			this->button4->Size = System::Drawing::Size(75, 23);
			this->button4->TabIndex = 5;
			this->button4->Text = L"Animate";
			this->button4->UseVisualStyleBackColor = true;
			this->button4->Click += gcnew System::EventHandler(this, &frmRay::button4_Click);
			// 
			// timer1
			// 
			this->timer1->Tick += gcnew System::EventHandler(this, &frmRay::timer1_Tick);
			// 
			// radioButton1
			// 
			this->radioButton1->AutoSize = true;
			this->radioButton1->Checked = true;
			this->radioButton1->Location = System::Drawing::Point(4, 157);
			this->radioButton1->Name = L"radioButton1";
			this->radioButton1->Size = System::Drawing::Size(66, 17);
			this->radioButton1->TabIndex = 6;
			this->radioButton1->TabStop = true;
			this->radioButton1->Text = L"640x480";
			this->radioButton1->UseVisualStyleBackColor = true;
			// 
			// radioButton2
			// 
			this->radioButton2->AutoSize = true;
			this->radioButton2->Location = System::Drawing::Point(4, 180);
			this->radioButton2->Name = L"radioButton2";
			this->radioButton2->Size = System::Drawing::Size(66, 17);
			this->radioButton2->TabIndex = 7;
			this->radioButton2->Text = L"320x240";
			this->radioButton2->UseVisualStyleBackColor = true;
			// 
			// radioButton3
			// 
			this->radioButton3->AutoSize = true;
			this->radioButton3->Location = System::Drawing::Point(4, 203);
			this->radioButton3->Name = L"radioButton3";
			this->radioButton3->Size = System::Drawing::Size(66, 17);
			this->radioButton3->TabIndex = 8;
			this->radioButton3->TabStop = true;
			this->radioButton3->Text = L"160x120";
			this->radioButton3->UseVisualStyleBackColor = true;
			this->radioButton3->CheckedChanged += gcnew System::EventHandler(this, &frmRay::radioButton3_CheckedChanged);
			// 
			// radioButton4
			// 
			this->radioButton4->AutoSize = true;
			this->radioButton4->Location = System::Drawing::Point(4, 226);
			this->radioButton4->Name = L"radioButton4";
			this->radioButton4->Size = System::Drawing::Size(54, 17);
			this->radioButton4->TabIndex = 9;
			this->radioButton4->TabStop = true;
			this->radioButton4->Text = L"40x30";
			this->radioButton4->UseVisualStyleBackColor = true;
			// 
			// frmRay
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(814, 661);
			this->Controls->Add(this->radioButton4);
			this->Controls->Add(this->radioButton3);
			this->Controls->Add(this->radioButton2);
			this->Controls->Add(this->radioButton1);
			this->Controls->Add(this->button4);
			this->Controls->Add(this->button3);
			this->Controls->Add(this->button2);
			this->Controls->Add(this->button1);
			this->Controls->Add(this->progressBar1);
			this->Controls->Add(this->pictureBox1);
			this->Name = L"frmRay";
			this->Text = L"Finitron Ray Trace";
			this->Load += gcnew System::EventHandler(this, &frmRay::frmRay_Load);
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	void MakeRay(unsigned int CurX, unsigned int CurY, Ray *ray) {
		double ScrnX, ScrnY;
		Vector tv1, tv2;

		if (rayTracer.viewPoint) {
			ScrnX = (CurX - (double)ViewWidth / 2.0) / (double)ViewWidth;
			ScrnY = (((double)(ViewHeight - 1) - CurY) -
						(double) ViewHeight / 2.0) /
						(double) ViewHeight;

			tv1 = Vector::Scale(rayTracer.viewPoint->up, ScrnY);
			tv2 = Vector::Scale(rayTracer.viewPoint->right, ScrnX);
			ray->dir = Vector::Add(tv1,tv2);
			ray->dir = Vector::Add(rayTracer.viewPoint->dir,ray->dir);
			ray->dir = Vector::Normalize(ray->dir);
			ray->origin = rayTracer.viewPoint->loc;
		}
	}
	void DoRayTrace(Graphics^ gr, BackgroundWorker^ worker, System::ComponentModel::DoWorkEventArgs^  e) {
		int X, Y;
		Finray::Ray ray;
		Finray::Color color;
		Pen^ pen;
		SolidBrush^ brush;
		unsigned int c;
		int area = ViewHeight * ViewWidth;
		int count;
		int percent;
		static int old_percent = 0;

		rayTracer.recurseLevel = 0;
		for (Y = 0; Y < ViewHeight; Y++) {
			for (X = 0; X < ViewWidth; X++) {
				if (worker->CancellationPending) {
					e->Cancel = true;
					goto xit;
				}
				MakeRay(X, Y, &ray);
				color.r = 0.0;
				color.g = 0.0;
				color.b = 0.0;
				ray.Trace(&color);
				if (color.r > 1.00) color.r = 1.00;
				if (color.g > 1.00) color.g = 1.00;
				if (color.b > 1.00) color.b = 1.00;
				c = (255 << 24) 
					| (((int)(255 * color.r) & 0xff) << 16) 
					| (((int)(255 * color.g) & 0xFF) << 8)
					| (int)(255 * color.b) & 0xFF;
				if (ViewWidth==640) {
					pen = gcnew Pen(System::Drawing::Color::FromArgb(c));
					gr->DrawRectangle(pen,X,Y,X+1,Y+1);
				}
				else {
					brush = gcnew SolidBrush(System::Drawing::Color::FromArgb(c));
					gr->FillRectangle(brush,X<<1,Y<<1,(X<<1)+3,(Y<<1)+3);
				}
				count = Y * ViewWidth + X;
				percent = count * 100 / area;
				if (percent != old_percent) {
					old_percent = percent;
					worker->ReportProgress(percent);
				}
			}
		}
xit:;
	}
	private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {
				 backgroundWorker1->CancelAsync();
				 this->button1->Enabled = false;
				 cancelled = true;
			 }
private: System::Void backgroundWorker1_DoWork(System::Object^  sender, System::ComponentModel::DoWorkEventArgs^  e) {
		BackgroundWorker^ worker = dynamic_cast<BackgroundWorker^>(sender);

		DoRayTrace(safe_cast<Graphics^>(e->Argument), worker, e);
		e->Result = nullptr;
		 }
private: System::Void backgroundWorker1_ProgressChanged(System::Object^  sender, System::ComponentModel::ProgressChangedEventArgs^  e) {
			this->progressBar1->Value = e->ProgressPercentage;
		 }
private: System::Void backgroundWorker1_RunWorkerCompleted(System::Object^  sender, System::ComponentModel::RunWorkerCompletedEventArgs^  e) {
			 char buf[30];
			 std::string str;
			 int first_frame,last_frame,frameno;
			if (e->Error != nullptr) {
				MessageBox::Show(e->Error->Message);
			}
			else if (e->Cancelled) {
				/* possibly display cancelled message in a label */
			}
			else {
				/* possibly display result status */
			}
			this->button1->Enabled = true;
			this->pictureBox1->Image = bmp;
			this->progressBar1->Value = 0;
			sprintf_s(buf, sizeof(buf), "_frame%07d.bmp", rayTracer.frameno);
			System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor;
			str = rayTracer.parser.path;
			str = str.append(buf);
			bmp->Save(gcnew String(str.c_str()),System::Drawing::Imaging::ImageFormat::Png);
			System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
			frameno = rayTracer.frameno;
			first_frame = rayTracer.first_frame;
			last_frame = rayTracer.last_frame;
			bmps[frameno] = (Bitmap^)bmp->Clone();
			if (frameno < last_frame-1 && !cancelled) {
				rayTracer.DeleteList();
				rayTracer.Init();
				rayTracer.frameno = frameno + 1;
				rayTracer.first_frame = first_frame;
				rayTracer.last_frame = last_frame;
				rayTracer.parser.ParseBuffer(master_filebuf);
				backgroundWorker1->RunWorkerAsync(gr);
				this->button1->Enabled = true;
				progressBar1->Value = 0;
			}
			else {
				rayTracer.DumpObjects();
				this->button3->Enabled = true;
			}
		 }
private: System::Void button2_Click(System::Object^  sender, System::EventArgs^  e) {
			 std::ofstream fp;
			 std::string path;
			if (this->saveFileDialog1->ShowDialog()  == System::Windows::Forms::DialogResult::OK ) {
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor;
				bmp->Save(this->saveFileDialog1->FileName,System::Drawing::Imaging::ImageFormat::Png);
				System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
			}
		 }
private: System::Void button3_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (radioButton2->Checked) {
				 ViewWidth = 320;
				 ViewHeight = 240;
			 }
			 else if (radioButton3->Checked) {
				 ViewWidth = 160;
				 ViewHeight = 120;
			 }
			 else if (radioButton4->Checked) {
				 ViewWidth = 40;
				 ViewHeight = 30;
			 }
			 else {
				 ViewWidth = 640;
				 ViewHeight = 480;
			 }
	        backgroundWorker1->RunWorkerAsync(gr);
			this->button1->Enabled = true;
			this->button3->Enabled = false;
			 progressBar1->Value = 0;
		 }
private: System::Void button4_Click(System::Object^  sender, System::EventArgs^  e) {
			 timer1->Enabled = true;
		 }
private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 static int nn = 0;

			 if (nn < rayTracer.first_frame)
				 nn = rayTracer.first_frame;
			 if (nn > rayTracer.last_frame) {
				 nn = rayTracer.first_frame;
				 timer1->Enabled = false;
			 }
			 this->pictureBox1->Image = bmps[nn];
			 nn++;
		 }
private: System::Void radioButton3_CheckedChanged(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void frmRay_Load(System::Object^  sender, System::EventArgs^  e) {
		 }
};
}
