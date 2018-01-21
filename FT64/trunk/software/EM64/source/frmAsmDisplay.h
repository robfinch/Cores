#pragma once
#include "Disassem.h"

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
	/// Summary for frmAsmDisplay
	/// </summary>
	public ref class frmAsmDisplay : public System::Windows::Forms::Form
	{
	public:
		frmAsmDisplay(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			this->SetStyle(ControlStyles::AllPaintingInWmPaint
				| ControlStyles::Opaque, true);
			myfont = gcnew System::Drawing::Font("Courier New", 8);
			bkbr = gcnew System::Drawing::SolidBrush(System::Drawing::Color::Blue);
			fgbr = gcnew System::Drawing::SolidBrush(System::Drawing::Color::White);
			animateDelay = 300000;
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmAsmDisplay()
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
		System::Drawing::Font^ myfont;
		SolidBrush^ bkbr;
		SolidBrush^ fgbr;
	public:
		bool animate;
		int animateDelay;
		unsigned int ad;

#pragma region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		void InitializeComponent(void)
		{
			this->SuspendLayout();
			// 
			// frmAsmDisplay
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(603, 398);
			this->DoubleBuffered = true;
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedToolWindow;
			this->MaximizeBox = false;
			this->Name = L"frmAsmDisplay";
			this->Text = L"EM64 Asm Display";
			this->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &frmAsmDisplay::frmAsmDisplay_Paint);
			this->ResumeLayout(false);

		}
#pragma endregion
	private: System::Void frmAsmDisplay_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
				Graphics^ gr = e->Graphics;
				LARGE_INTEGER perf_count;
				static LARGE_INTEGER operf_count = { 0 };
				static unsigned int old_ad = -1;
				char buf[200];
				char *buf2;
				std::string str;
				unsigned int row;
				int xx, yy;
				unsigned int ad1, ad2;
				unsigned int datx, daty, dat;
				static unsigned int ticks;
				int regno;

				ticks++;
				do {
   					QueryPerformanceCounter(&perf_count);
				}	while (perf_count.QuadPart - operf_count.QuadPart < 50LL);
				operf_count = perf_count;

				//ad2 = ad;
				ad2 = cpu1.pc - 32;
				//if (ad2 != old_ad)
				{
					if (animate) {
						if ((ticks % animateDelay)==0)
							cpu1.Step();
					}
					old_ad = ad2;
					xx = 8;
					gr->FillRectangle(bkbr,0,0,600,400);
					for (row = 0; row < 32; row++) {
						yy = row * 12 + 10;
						sprintf(buf,"%06X", ad2);
						str = std::string(buf);
						datx = system1.Read(ad2);
						datx = (datx >> ((ad2 & 3)<<3)) & 0xFFFF;
						daty = system1.Read(ad2+2);
						daty = (daty >> (((ad2+2) & 3)<<3)) & 0xFFFF;
						dat = (daty << 16) | datx;
			//			dat = system1.memory[ad>>2];
						if (ad2==cpu1.pc) {
							gr->FillRectangle(fgbr,0,yy,300,12);
							gr->DrawString(gcnew String(str.c_str()),myfont,bkbr,xx,yy);
							sprintf(buf,"%08X", dat);
							str = std::string(buf);
							gr->DrawString(gcnew String(str.c_str()),myfont,bkbr,xx + 64,yy);
							str = Disassem(ad2,dat,&ad1);
							gr->DrawString(gcnew String(str.c_str()),myfont,bkbr,xx + 128,yy);
						}
						else {
							gr->FillRectangle(bkbr,0,yy,300,12);
							gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,xx,yy);
							sprintf(buf,"%08X", dat);
							str = std::string(buf);
							gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,xx + 64,yy);
							str = Disassem(ad2,dat,&ad1);
							gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,xx + 128,yy);
						}
						ad2 = ad2 + 4;
					}

					for (regno = 0; regno < 16; regno++)
					{
						yy = regno * 12 + 10;
						sprintf(buf, "r%d %08X", regno, cpu1.regs[regno]);
						str = std::string(buf);
						gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,310,yy);
					}
					for (regno = 16; regno < 32; regno++)
					{
						yy = (regno - 16) * 12 + 10;
						sprintf(buf, "r%d %08X", regno, cpu1.regs[regno]);
						str = std::string(buf);
						gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,420,yy);
					}
					yy = 17 * 12 + 10;
					sprintf(buf, "pc %08X", cpu1.pc);
					str = std::string(buf);
					gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,310,yy);

					this->Invalidate();
				}
			 }
	};
}
