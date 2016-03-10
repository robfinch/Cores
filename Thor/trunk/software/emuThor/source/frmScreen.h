#pragma once
#include <Windows.h>
#include <string>
#include "clsSystem.h"
extern clsSystem system1;
extern char refscreen;
extern bool screenClosed;
extern bool dbgScreenClosed;

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Threading;

	/// <summary>
	/// Summary for frmScreen
	/// </summary>
	public ref class frmScreen : public System::Windows::Forms::Form
	{
		 System::Drawing::Rectangle ur;
	public:
		Mutex^ mut;
		frmScreen(Mutex^ m, String^ tbs)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			this->Text = L"emuFISA64 Test System Screen - " + tbs;
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmScreen()
		{
			if (components)
			{
				delete components;
			}
		}
	public: int which;
	public: unsigned long *pVidMem;
	public: bool *pVidDirty;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::Windows::Forms::PictureBox^  pictureBox1;
	protected: 
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
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->pictureBox1 = (gcnew System::Windows::Forms::PictureBox());
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->BeginInit();
			this->SuspendLayout();
			// 
			// timer1
			// 
			this->timer1->Enabled = true;
			this->timer1->Tick += gcnew System::EventHandler(this, &frmScreen::timer1_Tick);
			// 
			// pictureBox1
			// 
			this->pictureBox1->BackgroundImageLayout = System::Windows::Forms::ImageLayout::None;
			this->pictureBox1->Location = System::Drawing::Point(2, 0);
			this->pictureBox1->Name = L"pictureBox1";
			this->pictureBox1->Size = System::Drawing::Size(681, 328);
			this->pictureBox1->TabIndex = 0;
			this->pictureBox1->TabStop = false;
			this->pictureBox1->Click += gcnew System::EventHandler(this, &frmScreen::pictureBox1_Click);
			this->pictureBox1->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &frmScreen::pictureBox1_Paint);
			// 
			// frmScreen
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->BackgroundImageLayout = System::Windows::Forms::ImageLayout::None;
			this->ClientSize = System::Drawing::Size(684, 332);
			this->Controls->Add(this->pictureBox1);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
			this->MaximizeBox = false;
			this->Name = L"frmScreen";
			this->Text = L"emuFISA64 Test System Screen";
			this->FormClosed += gcnew System::Windows::Forms::FormClosedEventHandler(this, &frmScreen::frmScreen_FormClosed);
			this->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &frmScreen::frmScreen_Paint);
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->EndInit();
			this->ResumeLayout(false);

		}
#pragma endregion
	private: char ScreenToAscii(char ch)
{
     ch &= 0xFF;
     if (ch==0x1B)
        return 0x5B;
     if (ch==0x1D)
        return 0x5D;
     if (ch < 27)
        ch += 0x60;
     return ch;
}
  
	private: System::Void frmScreen_OnPaintBackground(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
			 }
	private: System::Void frmScreen_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
			 }
	private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
				 int nn;
				 int xx,yy;
				 int maxx,maxy,minx,miny;
				 maxx = 0; maxy = 0;
				 minx = 1000; miny = 1000;
				 if (refscreen) {
					 for (nn = 0; nn < 4096; nn++) {
						 if (pVidDirty) {
							 mut->WaitOne();
							 if (pVidDirty[nn]) {
								 xx = nn % 84;
								 yy = nn / 84;
								 maxx = max(xx,maxx);
								 maxy = max(yy,maxy);
								 minx = min(xx,minx);
								 miny = min(yy,miny);
							 }
							 mut->ReleaseMutex();
						 }
					 }
					ur.X = minx<<3;
					ur.Y = miny * 10;
					ur.Width = (maxx - minx)<<3;
					ur.Height = (maxy - miny) * 10;
					this->pictureBox1->Invalidate(ur);
					refscreen = false;
//					this->Refresh();
				 }
			 }
	private: System::Void pictureBox1_Click(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void frmScreen_FormClosed(System::Object^  sender, System::Windows::Forms::FormClosedEventArgs^  e) {
			 if (which==0)
				 screenClosed = true;
			 else
				 dbgScreenClosed = true;
		 }
private: System::Void pictureBox1_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
				 char buf[10];
				 unsigned int ndx;
				 int r,g,b;
				 unsigned int v;
				 System::Drawing::Font^ myfont;
				 std::string str;
				 Graphics^ gr = e->Graphics;
				 SolidBrush^ bkbr;
				 SolidBrush^ fgbr;
				 Color^ col;
				 myfont = gcnew System::Drawing::Font("Courier New", 6);
				 col = gcnew System::Drawing::Color;
				 bkbr = gcnew System::Drawing::SolidBrush(System::Drawing::Color::Blue);
				 fgbr = gcnew System::Drawing::SolidBrush(System::Drawing::Color::White);
				 int xx, yy;
				 for (xx = ur.X; xx < ur.X + ur.Width; xx += 8) {
					 for (yy = ur.Y; yy < ur.Y + ur.Height; yy += 10) {
						 ndx = (xx/8 + yy/10 * 84);
//						 if (system1.VideoMemDirty[ndx]) {
							if (pVidMem) {
								mut->WaitOne();
								v = pVidMem[ndx];
								mut->ReleaseMutex();
								r = ((((v >> 10) >> 9) >> 6) & 7) << 5;
								g = ((((v >> 10) >> 9) >> 3) & 7) << 5;
								b = ((((v >> 10) >> 9) >> 0) & 7) << 5;
								bkbr->Color = col->FromArgb(255,r,g,b);
								gr->FillRectangle(bkbr,xx,yy,8,10);
								r = ((((v >> 10)) >> 6) & 7) << 5;
								g = ((((v >> 10)) >> 3) & 7)<< 5;
								b = ((((v >> 10)) >> 0) & 7)<< 5;
								fgbr->Color = col->FromArgb(255,r,g,b);
								sprintf(buf,"%c",ScreenToAscii(v&0xff));
								str = std::string(buf);
								gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,xx,yy);
								if (pVidDirty) {
									mut->WaitOne();
									pVidDirty[ndx] = false;
									mut->ReleaseMutex();
								}
							}
//						 }
					 }
				 }
		 }
};
}
