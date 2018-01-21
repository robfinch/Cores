#pragma once
#include <Windows.h>
#include <string>
#include "clsSystem.h"
extern clsSystem system1;
extern char refscreen;

namespace E64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	using namespace System::Drawing::Imaging;
	using namespace System::IO;
	using namespace System::Threading;
	using namespace System::Runtime::InteropServices;

	/// <summary>
	/// Summary for frmScreen
	/// </summary>
	public ref class frmScreen : public System::Windows::Forms::Form
	{
	public:
		frmScreen(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			this->SetStyle(ControlStyles::AllPaintingInWmPaint
				| ControlStyles::Opaque, true);
			myfont = gcnew System::Drawing::Font("Courier New", 6);
			ur.X = 0;
			ur.Y = 0;
			ur.Width = 80*8;
			ur.Height = 31*8;
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

	private:
		/// <summary>
		/// Required designer variable.
		/// </summary>
		System::ComponentModel::Container ^components;
		System::Drawing::Rectangle ur;
		System::Drawing::Font^ myfont;

#pragma region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		void InitializeComponent(void)
		{
			this->SuspendLayout();
			// 
			// frmScreen
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(1002, 334);
			this->Name = L"frmScreen";
			this->Text = L"EM64 Screen";
			this->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &frmScreen::frmScreen_Paint);
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
  
	private: System::Void frmScreen_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
				 char buf[10];
				 unsigned int ndx;
				 int r,g,b;
				 unsigned int v;
				 std::string str;
				 Graphics^ gr = e->Graphics;
				 SolidBrush^ bkbr;
				 SolidBrush^ fgbr;
				 Color^ col;
				 LARGE_INTEGER perf_count;
				 static LARGE_INTEGER operf_count = { 0 };
				 int nn;
				 int xx,yy;
				 int maxx,maxy,minx,miny;
				 maxx = 0; maxy = 0;
				 minx = 1000; miny = 1000;

				 do {
   					QueryPerformanceCounter(&perf_count);
				 }	while (perf_count.QuadPart - operf_count.QuadPart < 45000LL);
				operf_count = perf_count;

				 col = gcnew System::Drawing::Color;
				 bkbr = gcnew System::Drawing::SolidBrush(System::Drawing::Color::Blue);
				 fgbr = gcnew System::Drawing::SolidBrush(System::Drawing::Color::White);

				 for (xx = ur.X; xx < ur.X + ur.Width; xx += 8) {
					 for (yy = ur.Y; yy < ur.Y + ur.Height; yy += 8) {
						 ndx = (xx/8 + yy/8 * 84);
//						 if (system1.VideoMemDirty[ndx]) {
							v = system1.VideoMem[ndx];
							r = ((((v >> 10) >> 9) >> 6) & 7) << 5;
							g = ((((v >> 10) >> 9) >> 3) & 7) << 5;
							b = ((((v >> 10) >> 9) >> 0) & 7) << 5;
							bkbr->Color = col->FromArgb(255,r,g,b);
							gr->FillRectangle(bkbr,xx,yy,8,8);
							r = ((((v >> 10)) >> 6) & 7) << 5;
							g = ((((v >> 10)) >> 3) & 7)<< 5;
							b = ((((v >> 10)) >> 0) & 7)<< 5;
							fgbr->Color = col->FromArgb(255,r,g,b);
							sprintf(buf,"%c",ScreenToAscii(system1.VideoMem[ndx]&0xff));
							str = std::string(buf);
							gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,xx,yy);
							system1.VideoMemDirty[ndx] = false;
//						 }
					 }
				 }
				minx = 640;
				miny = 248;
				maxx = 0;
				maxy = 0;
				for (nn = 0; nn < 4096; nn++) {
					if (system1.VideoMemDirty[nn]) {
						xx = nn % 84;
						yy = nn / 84;
						maxx = max(xx,maxx);
						maxy = max(yy,maxy);
						minx = min(xx,minx);
						miny = min(yy,miny);
					}
				}
				ur.X = minx<<3;
				ur.Y = miny<<3;
				ur.Width = (maxx - minx)<<3;
				ur.Height = (maxy - miny)<<3;
				this->Invalidate(ur);
			 }
	};
}
