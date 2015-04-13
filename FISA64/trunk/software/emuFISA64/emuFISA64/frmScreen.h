#pragma once
#include <Windows.h>
#include <string>
#include "clsSystem.h"
extern clsSystem system1;
extern char refscreen;

namespace emuFISA64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

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
	private: System::Windows::Forms::Timer^  timer1;
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
			this->SuspendLayout();
			// 
			// timer1
			// 
			this->timer1->Enabled = true;
			this->timer1->Tick += gcnew System::EventHandler(this, &frmScreen::timer1_Tick);
			// 
			// frmScreen
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(684, 262);
			this->ControlBox = false;
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
			this->Name = L"frmScreen";
			this->Text = L"emuFISA64 Test System Screen";
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
				 for (xx = 0; xx < 672; xx += 8) {
					 for (yy = 0; yy < 248; yy += 8) {
						 ndx = (xx/8 + yy/8 * 84);
						 v = system1.VideoMem[ndx];
						 r = ((((v >> 10) >> 9) >> 6) & 7) << 5;
						 g = ((((v >> 10) >> 9) >> 3) & 7) << 5;
						 b = ((((v >> 10) >> 9) >> 0) & 7) << 5;
						 bkbr->Color = col->FromArgb(255,r,g,b);
						 r = ((((v >> 10)) >> 6) & 7) << 5;
						 g = ((((v >> 10)) >> 3) & 7)<< 5;
						 b = ((((v >> 10)) >> 0) & 7)<< 5;
						 fgbr->Color = col->FromArgb(255,r,g,b);
						 sprintf(buf,"%c",ScreenToAscii(system1.VideoMem[ndx]&0xff));
						 str = std::string(buf);
						 gr->FillRectangle(bkbr,xx,yy,8,8);
						 gr->DrawString(gcnew String(str.c_str()),myfont,fgbr,xx,yy);
					 }
				 }
			 }
	private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
				 if (refscreen) {
					refscreen = false;
					this->Refresh();
				 }
			 }
	};
}
