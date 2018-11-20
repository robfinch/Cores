#pragma once
#include "stdafx.h"
#include "Arena.h"

namespace Asteroids {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

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
			RTFClasses::Random::srand(100);
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
	private: System::Windows::Forms::ToolStripMenuItem^  gameToolStripMenuItem;
	protected: 
	private: System::Windows::Forms::ToolStripMenuItem^  startToolStripMenuItem;
	private: System::Windows::Forms::MenuStrip^  menuStrip1;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Label^  label3;
	private: System::Windows::Forms::Label^  label4;
	private: System::Windows::Forms::Label^  label5;
	private: System::Windows::Forms::Label^  label6;
	private: System::Windows::Forms::ToolStripMenuItem^  optionsToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  doubleSizeToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  quadSizeToolStripMenuItem;
	private: System::Windows::Forms::Label^  label7;
	private: System::Windows::Forms::Label^  label8;
	private: System::Windows::Forms::Label^  label9;
	private: System::Windows::Forms::Label^  label10;

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
			this->gameToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->startToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->menuStrip1 = (gcnew System::Windows::Forms::MenuStrip());
			this->optionsToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->doubleSizeToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->quadSizeToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->label4 = (gcnew System::Windows::Forms::Label());
			this->label5 = (gcnew System::Windows::Forms::Label());
			this->label6 = (gcnew System::Windows::Forms::Label());
			this->label7 = (gcnew System::Windows::Forms::Label());
			this->label8 = (gcnew System::Windows::Forms::Label());
			this->label9 = (gcnew System::Windows::Forms::Label());
			this->label10 = (gcnew System::Windows::Forms::Label());
			this->menuStrip1->SuspendLayout();
			this->SuspendLayout();
			// 
			// gameToolStripMenuItem
			// 
			this->gameToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) {this->startToolStripMenuItem});
			this->gameToolStripMenuItem->Name = L"gameToolStripMenuItem";
			this->gameToolStripMenuItem->Size = System::Drawing::Size(50, 20);
			this->gameToolStripMenuItem->Text = L"Game";
			this->gameToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::gameToolStripMenuItem_Click);
			// 
			// startToolStripMenuItem
			// 
			this->startToolStripMenuItem->Name = L"startToolStripMenuItem";
			this->startToolStripMenuItem->Size = System::Drawing::Size(98, 22);
			this->startToolStripMenuItem->Text = L"Start";
			this->startToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::startToolStripMenuItem_Click);
			// 
			// menuStrip1
			// 
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->gameToolStripMenuItem, 
				this->optionsToolStripMenuItem});
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(417, 24);
			this->menuStrip1->TabIndex = 0;
			this->menuStrip1->Text = L"menuStrip1";
			// 
			// optionsToolStripMenuItem
			// 
			this->optionsToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {this->doubleSizeToolStripMenuItem, 
				this->quadSizeToolStripMenuItem});
			this->optionsToolStripMenuItem->Name = L"optionsToolStripMenuItem";
			this->optionsToolStripMenuItem->Size = System::Drawing::Size(61, 20);
			this->optionsToolStripMenuItem->Text = L"Options";
			this->optionsToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::optionsToolStripMenuItem_Click);
			// 
			// doubleSizeToolStripMenuItem
			// 
			this->doubleSizeToolStripMenuItem->Name = L"doubleSizeToolStripMenuItem";
			this->doubleSizeToolStripMenuItem->Size = System::Drawing::Size(135, 22);
			this->doubleSizeToolStripMenuItem->Text = L"Double Size";
			this->doubleSizeToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::doubleSizeToolStripMenuItem_Click);
			// 
			// quadSizeToolStripMenuItem
			// 
			this->quadSizeToolStripMenuItem->Name = L"quadSizeToolStripMenuItem";
			this->quadSizeToolStripMenuItem->Size = System::Drawing::Size(135, 22);
			this->quadSizeToolStripMenuItem->Text = L"Quad Size";
			this->quadSizeToolStripMenuItem->Click += gcnew System::EventHandler(this, &Form1::quadSizeToolStripMenuItem_Click);
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(30, 272);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(327, 13);
			this->label1->TabIndex = 1;
			this->label1->Text = L"The asteroid is a modified photo of a real asteroid found on the web.";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(30, 285);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(205, 13);
			this->label2->TabIndex = 2;
			this->label2->Text = L"Other graphics are from OpenGameArt.org";
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(30, 34);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(120, 104);
			this->label3->TabIndex = 3;
			this->label3->Text = L"Controls\r\n  h - hyperspace jump\r\n  4 - turn left \r\n  6 - turn right\r\n  8 - forwar" 
				L"d\r\n  2 - backwards\r\n  spacebar - fire missile\r\n  S - turn shields on / off";
			// 
			// label4
			// 
			this->label4->AutoSize = true;
			this->label4->Location = System::Drawing::Point(30, 156);
			this->label4->Name = L"label4";
			this->label4->Size = System::Drawing::Size(161, 91);
			this->label4->TabIndex = 4;
			this->label4->Text = L"Points\r\n  10 Big Asteroid\r\n  100 Medium Asteroid\r\n  1000 Small Asteroid\r\n  5000 A" 
				L"lien Ship\r\n\r\n10000 Points earns a bonus ship";
			// 
			// label5
			// 
			this->label5->AutoSize = true;
			this->label5->Location = System::Drawing::Point(30, 314);
			this->label5->Name = L"label5";
			this->label5->Size = System::Drawing::Size(187, 26);
			this->label5->TabIndex = 5;
			this->label5->Text = L"Missile graphics originally by Napolean\r\nCC-BY-SA 3.0";
			// 
			// label6
			// 
			this->label6->AutoSize = true;
			this->label6->Location = System::Drawing::Point(30, 346);
			this->label6->Name = L"label6";
			this->label6->Size = System::Drawing::Size(182, 26);
			this->label6->TabIndex = 6;
			this->label6->Text = L"Explosion graphics originally by Bleed\r\nCC-BY 3.0";
			// 
			// label7
			// 
			this->label7->AutoSize = true;
			this->label7->Location = System::Drawing::Point(30, 383);
			this->label7->Name = L"label7";
			this->label7->Size = System::Drawing::Size(188, 26);
			this->label7->TabIndex = 7;
			this->label7->Text = L"Explosion Sound Effect Public Domain\r\nby TinyWorlds";
			// 
			// label8
			// 
			this->label8->AutoSize = true;
			this->label8->Location = System::Drawing::Point(30, 259);
			this->label8->Name = L"label8";
			this->label8->Size = System::Drawing::Size(42, 13);
			this->label8->TabIndex = 8;
			this->label8->Text = L"Credits:";
			// 
			// label9
			// 
			this->label9->AutoSize = true;
			this->label9->Location = System::Drawing::Point(239, 314);
			this->label9->Name = L"label9";
			this->label9->Size = System::Drawing::Size(151, 26);
			this->label9->TabIndex = 9;
			this->label9->Text = L"Shield graphic by Bonsaiheldin\r\nCC-BY 3.0";
			// 
			// label10
			// 
			this->label10->AutoSize = true;
			this->label10->Location = System::Drawing::Point(173, 34);
			this->label10->Name = L"label10";
			this->label10->Size = System::Drawing::Size(124, 91);
			this->label10->TabIndex = 10;
			this->label10->Text = L"Gamepd\r\n  Y - hyperspace jump\r\nDPAD Left - turn left\r\nDPAD Right - turn right\r\nDP" 
				L"AD Up - forward\r\n  A - fire missile\r\n  X - Turn shields on / off";
			// 
			// Form1
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(417, 427);
			this->Controls->Add(this->label10);
			this->Controls->Add(this->label9);
			this->Controls->Add(this->label8);
			this->Controls->Add(this->label7);
			this->Controls->Add(this->label6);
			this->Controls->Add(this->label5);
			this->Controls->Add(this->label4);
			this->Controls->Add(this->label3);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->menuStrip1);
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"Form1";
			this->Text = L"RTF Asteroids";
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void startToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
				 game.Start();
				 Arena^ form = gcnew Arena();
				 form->Show();
			 }
	private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void gameToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void optionsToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
		 }
private: System::Void doubleSizeToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 this->doubleSizeToolStripMenuItem->Checked = !this->doubleSizeToolStripMenuItem->Checked;
			 game.doublesize = this->doubleSizeToolStripMenuItem->Checked;
			 game.size = game.doublesize ? 2 : game.size;
			 if (game.doublesize) this->quadSizeToolStripMenuItem->Checked = false;
		 }
private: System::Void quadSizeToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
			 this->quadSizeToolStripMenuItem->Checked = !this->quadSizeToolStripMenuItem->Checked;
			 game.quadsize = this->quadSizeToolStripMenuItem->Checked;
			 game.size = game.quadsize ? 4 : game.size;
			 if (game.quadsize) this->doubleSizeToolStripMenuItem->Checked = false;
		 }
};
}

