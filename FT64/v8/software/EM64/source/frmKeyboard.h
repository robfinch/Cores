#pragma once
#include "stdafx.h"
#include "clsKeyboard.h"

extern clsKeyboard keybd;
extern clsPIC pic1;
extern volatile unsigned __int8 keybd_status;
extern volatile unsigned __int8 keybd_scancode;

namespace E64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for frmKeyboard
	/// </summary>
	public ref class frmKeyboard : public System::Windows::Forms::Form
	{

	public:
		frmKeyboard(void)
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
		~frmKeyboard()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::Button^  btnQ;
	protected: 
	private: System::Windows::Forms::Button^  btnW;
	private: System::Windows::Forms::Button^  btnE;
	private: System::Windows::Forms::Button^  btnQuest;
	private: System::Windows::Forms::Button^  btnEnter;
	private: System::Windows::Forms::Button^  btnR;
	private: System::Windows::Forms::Button^  btnT;
	private: System::Windows::Forms::Button^  btnY;
	private: System::Windows::Forms::Button^  btnU;
	private: System::Windows::Forms::Button^  btnI;
	private: System::Windows::Forms::Button^  btnRshift;
	private: System::Windows::Forms::Button^  btnO;
	private: System::Windows::Forms::Button^  btnLshift;
	private: System::Windows::Forms::Button^  btnP;
	private: System::Windows::Forms::Button^  btnA;
	private: System::Windows::Forms::Button^  btnS;
	private: System::Windows::Forms::Button^  btnD;
	private: System::Windows::Forms::Button^  btnF;
	private: System::Windows::Forms::Button^  btnG;
	private: System::Windows::Forms::Button^  btnZ;
	private: System::Windows::Forms::Button^  btnH;
	private: System::Windows::Forms::Button^  btnJ;
	private: System::Windows::Forms::Button^  btnK;
	private: System::Windows::Forms::Button^  btnL;
	private: System::Windows::Forms::Button^  btnX;
	private: System::Windows::Forms::Button^  btnC;
	private: System::Windows::Forms::Button^  btnV;
	private: System::Windows::Forms::Button^  btnB;
	private: System::Windows::Forms::Button^  btnN;
	private: System::Windows::Forms::Button^  btnM;
	private: System::Windows::Forms::Button^  btn1;
	private: System::Windows::Forms::Button^  btn2;
	private: System::Windows::Forms::Button^  btn3;
	private: System::Windows::Forms::Button^  btn4;
	private: System::Windows::Forms::Button^  btn5;
	private: System::Windows::Forms::Button^  btn6;
	private: System::Windows::Forms::Button^  btn7;
	private: System::Windows::Forms::Button^  btn8;
	private: System::Windows::Forms::Button^  btn9;
	private: System::Windows::Forms::Button^  btn0;
	private: System::Windows::Forms::Button^  btnSpace;
	private: System::Windows::Forms::Button^  button1;
	private: System::Windows::Forms::Button^  button2;
	private: System::Windows::Forms::Button^  button3;
	private: System::Windows::Forms::Button^  button4;
	private: System::Windows::Forms::Button^  button5;
	private: System::Windows::Forms::Button^  button6;
	private: System::Windows::Forms::Button^  button7;
	private: System::Windows::Forms::Button^  btnMinus;

	private: System::Windows::Forms::Button^  button9;
	private: System::Windows::Forms::Button^  btnBackspace;
	private: System::Windows::Forms::Button^  btnRctrl;
	private: System::Windows::Forms::Button^  btnLalt;
	private: System::Windows::Forms::Button^  button10;
	private: System::Windows::Forms::Button^  button11;
	private: System::Windows::Forms::Button^  button12;
	private: System::Windows::Forms::Button^  button13;
	private: System::Windows::Forms::Button^  button14;
	private: System::Windows::Forms::Button^  button15;
	private: System::Windows::Forms::Button^  button16;
	private: System::Windows::Forms::Button^  button17;
	private: System::Windows::Forms::Button^  button18;
	private: System::Windows::Forms::Button^  button19;
	private: System::Windows::Forms::Button^  button8;
	private: System::Windows::Forms::Button^  button20;
	private: System::Windows::Forms::Button^  buttonLctrl;
	private: System::Windows::Forms::Button^  buttonEsc;
	private: System::Windows::Forms::Button^  buttonF1;
	private: System::Windows::Forms::Button^  buttonF2;
	private: System::Windows::Forms::Button^  buttonF3;
	private: System::Windows::Forms::Button^  buttonF4;
	private: System::Windows::Forms::Button^  buttonF5;
	private: System::Windows::Forms::Button^  buttonF6;
	private: System::Windows::Forms::Button^  buttonF7;
	private: System::Windows::Forms::Button^  buttonF8;
	private: System::Windows::Forms::Button^  buttonF9;
	private: System::Windows::Forms::Button^  buttonF10;
	private: System::Windows::Forms::Button^  buttonF11;
	private: System::Windows::Forms::Button^  buttonF12;
private: System::Windows::Forms::Button^  buttonCapslock;
private: System::Windows::Forms::Button^  button21;
private: System::Windows::Forms::Button^  button22;
private: System::Windows::Forms::Button^  button23;
private: System::Windows::Forms::Button^  buttonTab;

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
			this->btnQ = (gcnew System::Windows::Forms::Button());
			this->btnW = (gcnew System::Windows::Forms::Button());
			this->btnE = (gcnew System::Windows::Forms::Button());
			this->btnQuest = (gcnew System::Windows::Forms::Button());
			this->btnEnter = (gcnew System::Windows::Forms::Button());
			this->btnR = (gcnew System::Windows::Forms::Button());
			this->btnT = (gcnew System::Windows::Forms::Button());
			this->btnY = (gcnew System::Windows::Forms::Button());
			this->btnU = (gcnew System::Windows::Forms::Button());
			this->btnI = (gcnew System::Windows::Forms::Button());
			this->btnRshift = (gcnew System::Windows::Forms::Button());
			this->btnO = (gcnew System::Windows::Forms::Button());
			this->btnLshift = (gcnew System::Windows::Forms::Button());
			this->btnP = (gcnew System::Windows::Forms::Button());
			this->btnA = (gcnew System::Windows::Forms::Button());
			this->btnS = (gcnew System::Windows::Forms::Button());
			this->btnD = (gcnew System::Windows::Forms::Button());
			this->btnF = (gcnew System::Windows::Forms::Button());
			this->btnG = (gcnew System::Windows::Forms::Button());
			this->btnZ = (gcnew System::Windows::Forms::Button());
			this->btnH = (gcnew System::Windows::Forms::Button());
			this->btnJ = (gcnew System::Windows::Forms::Button());
			this->btnK = (gcnew System::Windows::Forms::Button());
			this->btnL = (gcnew System::Windows::Forms::Button());
			this->btnX = (gcnew System::Windows::Forms::Button());
			this->btnC = (gcnew System::Windows::Forms::Button());
			this->btnV = (gcnew System::Windows::Forms::Button());
			this->btnB = (gcnew System::Windows::Forms::Button());
			this->btnN = (gcnew System::Windows::Forms::Button());
			this->btnM = (gcnew System::Windows::Forms::Button());
			this->btn1 = (gcnew System::Windows::Forms::Button());
			this->btn2 = (gcnew System::Windows::Forms::Button());
			this->btn3 = (gcnew System::Windows::Forms::Button());
			this->btn4 = (gcnew System::Windows::Forms::Button());
			this->btn5 = (gcnew System::Windows::Forms::Button());
			this->btn6 = (gcnew System::Windows::Forms::Button());
			this->btn7 = (gcnew System::Windows::Forms::Button());
			this->btn8 = (gcnew System::Windows::Forms::Button());
			this->btn9 = (gcnew System::Windows::Forms::Button());
			this->btn0 = (gcnew System::Windows::Forms::Button());
			this->btnSpace = (gcnew System::Windows::Forms::Button());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->button2 = (gcnew System::Windows::Forms::Button());
			this->button3 = (gcnew System::Windows::Forms::Button());
			this->button4 = (gcnew System::Windows::Forms::Button());
			this->button5 = (gcnew System::Windows::Forms::Button());
			this->button6 = (gcnew System::Windows::Forms::Button());
			this->button7 = (gcnew System::Windows::Forms::Button());
			this->btnMinus = (gcnew System::Windows::Forms::Button());
			this->button9 = (gcnew System::Windows::Forms::Button());
			this->btnBackspace = (gcnew System::Windows::Forms::Button());
			this->btnRctrl = (gcnew System::Windows::Forms::Button());
			this->btnLalt = (gcnew System::Windows::Forms::Button());
			this->button10 = (gcnew System::Windows::Forms::Button());
			this->button11 = (gcnew System::Windows::Forms::Button());
			this->button12 = (gcnew System::Windows::Forms::Button());
			this->button13 = (gcnew System::Windows::Forms::Button());
			this->button14 = (gcnew System::Windows::Forms::Button());
			this->button15 = (gcnew System::Windows::Forms::Button());
			this->button16 = (gcnew System::Windows::Forms::Button());
			this->button17 = (gcnew System::Windows::Forms::Button());
			this->button18 = (gcnew System::Windows::Forms::Button());
			this->button19 = (gcnew System::Windows::Forms::Button());
			this->button8 = (gcnew System::Windows::Forms::Button());
			this->button20 = (gcnew System::Windows::Forms::Button());
			this->buttonLctrl = (gcnew System::Windows::Forms::Button());
			this->buttonEsc = (gcnew System::Windows::Forms::Button());
			this->buttonF1 = (gcnew System::Windows::Forms::Button());
			this->buttonF2 = (gcnew System::Windows::Forms::Button());
			this->buttonF3 = (gcnew System::Windows::Forms::Button());
			this->buttonF4 = (gcnew System::Windows::Forms::Button());
			this->buttonF5 = (gcnew System::Windows::Forms::Button());
			this->buttonF6 = (gcnew System::Windows::Forms::Button());
			this->buttonF7 = (gcnew System::Windows::Forms::Button());
			this->buttonF8 = (gcnew System::Windows::Forms::Button());
			this->buttonF9 = (gcnew System::Windows::Forms::Button());
			this->buttonF10 = (gcnew System::Windows::Forms::Button());
			this->buttonF11 = (gcnew System::Windows::Forms::Button());
			this->buttonF12 = (gcnew System::Windows::Forms::Button());
			this->buttonCapslock = (gcnew System::Windows::Forms::Button());
			this->button21 = (gcnew System::Windows::Forms::Button());
			this->button22 = (gcnew System::Windows::Forms::Button());
			this->button23 = (gcnew System::Windows::Forms::Button());
			this->buttonTab = (gcnew System::Windows::Forms::Button());
			this->SuspendLayout();
			// 
			// btnQ
			// 
			this->btnQ->Location = System::Drawing::Point(83, 90);
			this->btnQ->Name = L"btnQ";
			this->btnQ->Size = System::Drawing::Size(36, 34);
			this->btnQ->TabIndex = 0;
			this->btnQ->Text = L"Q";
			this->btnQ->UseVisualStyleBackColor = true;
			this->btnQ->Click += gcnew System::EventHandler(this, &frmKeyboard::btnQ_Click);
			// 
			// btnW
			// 
			this->btnW->Location = System::Drawing::Point(125, 90);
			this->btnW->Name = L"btnW";
			this->btnW->Size = System::Drawing::Size(35, 34);
			this->btnW->TabIndex = 1;
			this->btnW->Text = L"W";
			this->btnW->UseVisualStyleBackColor = true;
			this->btnW->Click += gcnew System::EventHandler(this, &frmKeyboard::btnW_Click);
			// 
			// btnE
			// 
			this->btnE->Location = System::Drawing::Point(166, 90);
			this->btnE->Name = L"btnE";
			this->btnE->Size = System::Drawing::Size(35, 34);
			this->btnE->TabIndex = 2;
			this->btnE->Text = L"E";
			this->btnE->UseVisualStyleBackColor = true;
			this->btnE->Click += gcnew System::EventHandler(this, &frmKeyboard::btnE_Click);
			// 
			// btnQuest
			// 
			this->btnQuest->Location = System::Drawing::Point(474, 170);
			this->btnQuest->Name = L"btnQuest";
			this->btnQuest->Size = System::Drawing::Size(39, 33);
			this->btnQuest->TabIndex = 3;
			this->btnQuest->Text = L"\?/";
			this->btnQuest->UseVisualStyleBackColor = true;
			this->btnQuest->Click += gcnew System::EventHandler(this, &frmKeyboard::btnQuest_Click);
			// 
			// btnEnter
			// 
			this->btnEnter->Location = System::Drawing::Point(580, 90);
			this->btnEnter->Name = L"btnEnter";
			this->btnEnter->Size = System::Drawing::Size(46, 74);
			this->btnEnter->TabIndex = 4;
			this->btnEnter->Text = L"Enter";
			this->btnEnter->UseVisualStyleBackColor = true;
			this->btnEnter->Click += gcnew System::EventHandler(this, &frmKeyboard::btnEnter_Click);
			// 
			// btnR
			// 
			this->btnR->Location = System::Drawing::Point(206, 90);
			this->btnR->Name = L"btnR";
			this->btnR->Size = System::Drawing::Size(34, 34);
			this->btnR->TabIndex = 5;
			this->btnR->Text = L"R";
			this->btnR->UseVisualStyleBackColor = true;
			this->btnR->Click += gcnew System::EventHandler(this, &frmKeyboard::btnR_Click);
			// 
			// btnT
			// 
			this->btnT->Location = System::Drawing::Point(246, 90);
			this->btnT->Name = L"btnT";
			this->btnT->Size = System::Drawing::Size(35, 34);
			this->btnT->TabIndex = 6;
			this->btnT->Text = L"T";
			this->btnT->UseVisualStyleBackColor = true;
			this->btnT->Click += gcnew System::EventHandler(this, &frmKeyboard::btnT_Click);
			// 
			// btnY
			// 
			this->btnY->Location = System::Drawing::Point(287, 90);
			this->btnY->Name = L"btnY";
			this->btnY->Size = System::Drawing::Size(34, 34);
			this->btnY->TabIndex = 7;
			this->btnY->Text = L"Y";
			this->btnY->UseVisualStyleBackColor = true;
			this->btnY->Click += gcnew System::EventHandler(this, &frmKeyboard::btnY_Click);
			// 
			// btnU
			// 
			this->btnU->Location = System::Drawing::Point(327, 90);
			this->btnU->Name = L"btnU";
			this->btnU->Size = System::Drawing::Size(35, 34);
			this->btnU->TabIndex = 8;
			this->btnU->Text = L"U";
			this->btnU->UseVisualStyleBackColor = true;
			this->btnU->Click += gcnew System::EventHandler(this, &frmKeyboard::btnU_Click);
			// 
			// btnI
			// 
			this->btnI->Location = System::Drawing::Point(368, 90);
			this->btnI->Name = L"btnI";
			this->btnI->Size = System::Drawing::Size(34, 34);
			this->btnI->TabIndex = 9;
			this->btnI->Text = L"I";
			this->btnI->UseVisualStyleBackColor = true;
			this->btnI->Click += gcnew System::EventHandler(this, &frmKeyboard::btnI_Click);
			// 
			// btnRshift
			// 
			this->btnRshift->Location = System::Drawing::Point(519, 170);
			this->btnRshift->Name = L"btnRshift";
			this->btnRshift->Size = System::Drawing::Size(107, 33);
			this->btnRshift->TabIndex = 10;
			this->btnRshift->Text = L"shift";
			this->btnRshift->UseVisualStyleBackColor = true;
			this->btnRshift->Click += gcnew System::EventHandler(this, &frmKeyboard::btnRshift_Click);
			// 
			// btnO
			// 
			this->btnO->Location = System::Drawing::Point(408, 90);
			this->btnO->Name = L"btnO";
			this->btnO->Size = System::Drawing::Size(34, 34);
			this->btnO->TabIndex = 11;
			this->btnO->Text = L"O";
			this->btnO->UseVisualStyleBackColor = true;
			this->btnO->Click += gcnew System::EventHandler(this, &frmKeyboard::btnO_Click);
			// 
			// btnLshift
			// 
			this->btnLshift->Location = System::Drawing::Point(24, 170);
			this->btnLshift->Name = L"btnLshift";
			this->btnLshift->Size = System::Drawing::Size(39, 33);
			this->btnLshift->TabIndex = 12;
			this->btnLshift->Text = L"shift";
			this->btnLshift->UseVisualStyleBackColor = true;
			// 
			// btnP
			// 
			this->btnP->Location = System::Drawing::Point(448, 90);
			this->btnP->Name = L"btnP";
			this->btnP->Size = System::Drawing::Size(38, 34);
			this->btnP->TabIndex = 13;
			this->btnP->Text = L"P";
			this->btnP->UseVisualStyleBackColor = true;
			this->btnP->Click += gcnew System::EventHandler(this, &frmKeyboard::btnP_Click);
			// 
			// btnA
			// 
			this->btnA->Location = System::Drawing::Point(93, 130);
			this->btnA->Name = L"btnA";
			this->btnA->Size = System::Drawing::Size(34, 34);
			this->btnA->TabIndex = 14;
			this->btnA->Text = L"A";
			this->btnA->UseVisualStyleBackColor = true;
			this->btnA->Click += gcnew System::EventHandler(this, &frmKeyboard::btnA_Click);
			// 
			// btnS
			// 
			this->btnS->Location = System::Drawing::Point(133, 130);
			this->btnS->Name = L"btnS";
			this->btnS->Size = System::Drawing::Size(36, 34);
			this->btnS->TabIndex = 15;
			this->btnS->Text = L"S";
			this->btnS->UseVisualStyleBackColor = true;
			this->btnS->Click += gcnew System::EventHandler(this, &frmKeyboard::btnS_Click);
			// 
			// btnD
			// 
			this->btnD->Location = System::Drawing::Point(175, 130);
			this->btnD->Name = L"btnD";
			this->btnD->Size = System::Drawing::Size(35, 34);
			this->btnD->TabIndex = 16;
			this->btnD->Text = L"D";
			this->btnD->UseVisualStyleBackColor = true;
			this->btnD->Click += gcnew System::EventHandler(this, &frmKeyboard::btnD_Click);
			// 
			// btnF
			// 
			this->btnF->Location = System::Drawing::Point(216, 130);
			this->btnF->Name = L"btnF";
			this->btnF->Size = System::Drawing::Size(33, 34);
			this->btnF->TabIndex = 17;
			this->btnF->Text = L"F";
			this->btnF->UseVisualStyleBackColor = true;
			this->btnF->Click += gcnew System::EventHandler(this, &frmKeyboard::btnF_Click);
			// 
			// btnG
			// 
			this->btnG->Location = System::Drawing::Point(256, 130);
			this->btnG->Name = L"btnG";
			this->btnG->Size = System::Drawing::Size(36, 34);
			this->btnG->TabIndex = 18;
			this->btnG->Text = L"G";
			this->btnG->UseVisualStyleBackColor = true;
			this->btnG->Click += gcnew System::EventHandler(this, &frmKeyboard::btnG_Click);
			// 
			// btnZ
			// 
			this->btnZ->Location = System::Drawing::Point(102, 170);
			this->btnZ->Name = L"btnZ";
			this->btnZ->Size = System::Drawing::Size(34, 33);
			this->btnZ->TabIndex = 19;
			this->btnZ->Text = L"Z";
			this->btnZ->UseVisualStyleBackColor = true;
			this->btnZ->Click += gcnew System::EventHandler(this, &frmKeyboard::btnZ_Click);
			// 
			// btnH
			// 
			this->btnH->Location = System::Drawing::Point(298, 130);
			this->btnH->Name = L"btnH";
			this->btnH->Size = System::Drawing::Size(33, 34);
			this->btnH->TabIndex = 21;
			this->btnH->Text = L"H";
			this->btnH->UseVisualStyleBackColor = true;
			this->btnH->Click += gcnew System::EventHandler(this, &frmKeyboard::btnH_Click);
			// 
			// btnJ
			// 
			this->btnJ->Location = System::Drawing::Point(339, 130);
			this->btnJ->Name = L"btnJ";
			this->btnJ->Size = System::Drawing::Size(32, 34);
			this->btnJ->TabIndex = 22;
			this->btnJ->Text = L"J";
			this->btnJ->UseVisualStyleBackColor = true;
			this->btnJ->Click += gcnew System::EventHandler(this, &frmKeyboard::btnJ_Click);
			// 
			// btnK
			// 
			this->btnK->Location = System::Drawing::Point(377, 130);
			this->btnK->Name = L"btnK";
			this->btnK->Size = System::Drawing::Size(34, 34);
			this->btnK->TabIndex = 23;
			this->btnK->Text = L"K";
			this->btnK->UseVisualStyleBackColor = true;
			this->btnK->Click += gcnew System::EventHandler(this, &frmKeyboard::btnK_Click);
			// 
			// btnL
			// 
			this->btnL->Location = System::Drawing::Point(417, 130);
			this->btnL->Name = L"btnL";
			this->btnL->Size = System::Drawing::Size(39, 34);
			this->btnL->TabIndex = 24;
			this->btnL->Text = L"L";
			this->btnL->UseVisualStyleBackColor = true;
			this->btnL->Click += gcnew System::EventHandler(this, &frmKeyboard::btnL_Click);
			// 
			// btnX
			// 
			this->btnX->Location = System::Drawing::Point(142, 170);
			this->btnX->Name = L"btnX";
			this->btnX->Size = System::Drawing::Size(42, 33);
			this->btnX->TabIndex = 20;
			this->btnX->Text = L"X";
			this->btnX->UseVisualStyleBackColor = true;
			this->btnX->Click += gcnew System::EventHandler(this, &frmKeyboard::btnX_Click);
			// 
			// btnC
			// 
			this->btnC->Location = System::Drawing::Point(190, 170);
			this->btnC->Name = L"btnC";
			this->btnC->Size = System::Drawing::Size(32, 33);
			this->btnC->TabIndex = 25;
			this->btnC->Text = L"C";
			this->btnC->UseVisualStyleBackColor = true;
			this->btnC->Click += gcnew System::EventHandler(this, &frmKeyboard::btnC_Click);
			// 
			// btnV
			// 
			this->btnV->Location = System::Drawing::Point(228, 170);
			this->btnV->Name = L"btnV";
			this->btnV->Size = System::Drawing::Size(34, 33);
			this->btnV->TabIndex = 26;
			this->btnV->Text = L"V";
			this->btnV->UseVisualStyleBackColor = true;
			this->btnV->Click += gcnew System::EventHandler(this, &frmKeyboard::btnV_Click);
			// 
			// btnB
			// 
			this->btnB->Location = System::Drawing::Point(267, 170);
			this->btnB->Name = L"btnB";
			this->btnB->Size = System::Drawing::Size(35, 33);
			this->btnB->TabIndex = 27;
			this->btnB->Text = L"B";
			this->btnB->UseVisualStyleBackColor = true;
			this->btnB->Click += gcnew System::EventHandler(this, &frmKeyboard::btnB_Click);
			// 
			// btnN
			// 
			this->btnN->Location = System::Drawing::Point(308, 170);
			this->btnN->Name = L"btnN";
			this->btnN->Size = System::Drawing::Size(34, 33);
			this->btnN->TabIndex = 28;
			this->btnN->Text = L"N";
			this->btnN->UseVisualStyleBackColor = true;
			this->btnN->Click += gcnew System::EventHandler(this, &frmKeyboard::btnN_Click);
			// 
			// btnM
			// 
			this->btnM->Location = System::Drawing::Point(348, 170);
			this->btnM->Name = L"btnM";
			this->btnM->Size = System::Drawing::Size(36, 33);
			this->btnM->TabIndex = 29;
			this->btnM->Text = L"M";
			this->btnM->UseVisualStyleBackColor = true;
			this->btnM->Click += gcnew System::EventHandler(this, &frmKeyboard::btnM_Click);
			// 
			// btn1
			// 
			this->btn1->Location = System::Drawing::Point(69, 48);
			this->btn1->Name = L"btn1";
			this->btn1->Size = System::Drawing::Size(39, 36);
			this->btn1->TabIndex = 30;
			this->btn1->Text = L"!1";
			this->btn1->UseVisualStyleBackColor = true;
			this->btn1->Click += gcnew System::EventHandler(this, &frmKeyboard::btn1_Click);
			// 
			// btn2
			// 
			this->btn2->Location = System::Drawing::Point(114, 48);
			this->btn2->Name = L"btn2";
			this->btn2->Size = System::Drawing::Size(37, 36);
			this->btn2->TabIndex = 31;
			this->btn2->Text = L"@2";
			this->btn2->UseVisualStyleBackColor = true;
			this->btn2->Click += gcnew System::EventHandler(this, &frmKeyboard::btn2_Click);
			// 
			// btn3
			// 
			this->btn3->Location = System::Drawing::Point(159, 48);
			this->btn3->Name = L"btn3";
			this->btn3->Size = System::Drawing::Size(34, 36);
			this->btn3->TabIndex = 32;
			this->btn3->Text = L"#3";
			this->btn3->UseVisualStyleBackColor = true;
			this->btn3->Click += gcnew System::EventHandler(this, &frmKeyboard::btn3_Click);
			// 
			// btn4
			// 
			this->btn4->Location = System::Drawing::Point(199, 48);
			this->btn4->Name = L"btn4";
			this->btn4->Size = System::Drawing::Size(32, 36);
			this->btn4->TabIndex = 33;
			this->btn4->Text = L"$4";
			this->btn4->UseVisualStyleBackColor = true;
			this->btn4->Click += gcnew System::EventHandler(this, &frmKeyboard::btn4_Click);
			// 
			// btn5
			// 
			this->btn5->Location = System::Drawing::Point(235, 48);
			this->btn5->Name = L"btn5";
			this->btn5->Size = System::Drawing::Size(36, 36);
			this->btn5->TabIndex = 34;
			this->btn5->Text = L"%5";
			this->btn5->UseVisualStyleBackColor = true;
			this->btn5->Click += gcnew System::EventHandler(this, &frmKeyboard::btn5_Click);
			// 
			// btn6
			// 
			this->btn6->Location = System::Drawing::Point(277, 48);
			this->btn6->Name = L"btn6";
			this->btn6->Size = System::Drawing::Size(35, 36);
			this->btn6->TabIndex = 35;
			this->btn6->Text = L"^6";
			this->btn6->UseVisualStyleBackColor = true;
			this->btn6->Click += gcnew System::EventHandler(this, &frmKeyboard::btn6_Click);
			// 
			// btn7
			// 
			this->btn7->Location = System::Drawing::Point(317, 48);
			this->btn7->Name = L"btn7";
			this->btn7->Size = System::Drawing::Size(35, 36);
			this->btn7->TabIndex = 36;
			this->btn7->Text = L"&&7";
			this->btn7->UseVisualStyleBackColor = true;
			this->btn7->Click += gcnew System::EventHandler(this, &frmKeyboard::btn7_Click);
			// 
			// btn8
			// 
			this->btn8->Location = System::Drawing::Point(358, 48);
			this->btn8->Name = L"btn8";
			this->btn8->Size = System::Drawing::Size(35, 36);
			this->btn8->TabIndex = 37;
			this->btn8->Text = L"*8";
			this->btn8->UseVisualStyleBackColor = true;
			this->btn8->Click += gcnew System::EventHandler(this, &frmKeyboard::btn8_Click);
			// 
			// btn9
			// 
			this->btn9->Location = System::Drawing::Point(399, 48);
			this->btn9->Name = L"btn9";
			this->btn9->Size = System::Drawing::Size(32, 36);
			this->btn9->TabIndex = 38;
			this->btn9->Text = L"(9";
			this->btn9->UseVisualStyleBackColor = true;
			this->btn9->Click += gcnew System::EventHandler(this, &frmKeyboard::btn9_Click);
			// 
			// btn0
			// 
			this->btn0->Location = System::Drawing::Point(437, 48);
			this->btn0->Name = L"btn0";
			this->btn0->Size = System::Drawing::Size(34, 36);
			this->btn0->TabIndex = 39;
			this->btn0->Text = L")0";
			this->btn0->UseVisualStyleBackColor = true;
			this->btn0->Click += gcnew System::EventHandler(this, &frmKeyboard::btn0_Click);
			// 
			// btnSpace
			// 
			this->btnSpace->Location = System::Drawing::Point(206, 209);
			this->btnSpace->Name = L"btnSpace";
			this->btnSpace->Size = System::Drawing::Size(250, 33);
			this->btnSpace->TabIndex = 40;
			this->btnSpace->UseVisualStyleBackColor = true;
			this->btnSpace->Click += gcnew System::EventHandler(this, &frmKeyboard::btnSpace_Click);
			// 
			// button1
			// 
			this->button1->Location = System::Drawing::Point(390, 170);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(36, 33);
			this->button1->TabIndex = 41;
			this->button1->Text = L"<,";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &frmKeyboard::button1_Click);
			// 
			// button2
			// 
			this->button2->Location = System::Drawing::Point(432, 170);
			this->button2->Name = L"button2";
			this->button2->Size = System::Drawing::Size(36, 33);
			this->button2->TabIndex = 42;
			this->button2->Text = L">.";
			this->button2->UseVisualStyleBackColor = true;
			this->button2->Click += gcnew System::EventHandler(this, &frmKeyboard::button2_Click);
			// 
			// button3
			// 
			this->button3->Location = System::Drawing::Point(462, 130);
			this->button3->Name = L"button3";
			this->button3->Size = System::Drawing::Size(39, 34);
			this->button3->TabIndex = 43;
			this->button3->Text = L":;";
			this->button3->UseVisualStyleBackColor = true;
			this->button3->Click += gcnew System::EventHandler(this, &frmKeyboard::button3_Click);
			// 
			// button4
			// 
			this->button4->Location = System::Drawing::Point(506, 130);
			this->button4->Name = L"button4";
			this->button4->Size = System::Drawing::Size(39, 34);
			this->button4->TabIndex = 44;
			this->button4->Text = L"\"\'";
			this->button4->UseVisualStyleBackColor = true;
			this->button4->Click += gcnew System::EventHandler(this, &frmKeyboard::button4_Click);
			// 
			// button5
			// 
			this->button5->Location = System::Drawing::Point(551, 130);
			this->button5->Name = L"button5";
			this->button5->Size = System::Drawing::Size(39, 34);
			this->button5->TabIndex = 45;
			this->button5->Text = L"|\\";
			this->button5->UseVisualStyleBackColor = true;
			this->button5->Click += gcnew System::EventHandler(this, &frmKeyboard::button5_Click);
			// 
			// button6
			// 
			this->button6->Location = System::Drawing::Point(492, 90);
			this->button6->Name = L"button6";
			this->button6->Size = System::Drawing::Size(38, 34);
			this->button6->TabIndex = 46;
			this->button6->Text = L"{[";
			this->button6->UseVisualStyleBackColor = true;
			this->button6->Click += gcnew System::EventHandler(this, &frmKeyboard::button6_Click);
			// 
			// button7
			// 
			this->button7->Location = System::Drawing::Point(536, 90);
			this->button7->Name = L"button7";
			this->button7->Size = System::Drawing::Size(38, 34);
			this->button7->TabIndex = 47;
			this->button7->Text = L"}]";
			this->button7->UseVisualStyleBackColor = true;
			this->button7->Click += gcnew System::EventHandler(this, &frmKeyboard::button7_Click);
			// 
			// btnMinus
			// 
			this->btnMinus->Location = System::Drawing::Point(474, 48);
			this->btnMinus->Name = L"btnMinus";
			this->btnMinus->Size = System::Drawing::Size(34, 36);
			this->btnMinus->TabIndex = 48;
			this->btnMinus->Text = L"_-";
			this->btnMinus->UseVisualStyleBackColor = true;
			this->btnMinus->Click += gcnew System::EventHandler(this, &frmKeyboard::btnMinus_Click);
			// 
			// button9
			// 
			this->button9->Location = System::Drawing::Point(514, 48);
			this->button9->Name = L"button9";
			this->button9->Size = System::Drawing::Size(34, 36);
			this->button9->TabIndex = 49;
			this->button9->Text = L"+=";
			this->button9->UseVisualStyleBackColor = true;
			this->button9->Click += gcnew System::EventHandler(this, &frmKeyboard::button9_Click);
			// 
			// btnBackspace
			// 
			this->btnBackspace->Location = System::Drawing::Point(554, 48);
			this->btnBackspace->Name = L"btnBackspace";
			this->btnBackspace->Size = System::Drawing::Size(72, 36);
			this->btnBackspace->TabIndex = 50;
			this->btnBackspace->Text = L"<--";
			this->btnBackspace->UseVisualStyleBackColor = true;
			this->btnBackspace->Click += gcnew System::EventHandler(this, &frmKeyboard::btnBackspace_Click);
			// 
			// btnRctrl
			// 
			this->btnRctrl->Location = System::Drawing::Point(568, 212);
			this->btnRctrl->Name = L"btnRctrl";
			this->btnRctrl->Size = System::Drawing::Size(58, 33);
			this->btnRctrl->TabIndex = 51;
			this->btnRctrl->Text = L"Ctrl";
			this->btnRctrl->UseVisualStyleBackColor = true;
			this->btnRctrl->Click += gcnew System::EventHandler(this, &frmKeyboard::btnRctrl_Click);
			// 
			// btnLalt
			// 
			this->btnLalt->Location = System::Drawing::Point(142, 209);
			this->btnLalt->Name = L"btnLalt";
			this->btnLalt->Size = System::Drawing::Size(58, 33);
			this->btnLalt->TabIndex = 52;
			this->btnLalt->Text = L"Alt";
			this->btnLalt->UseVisualStyleBackColor = true;
			this->btnLalt->Click += gcnew System::EventHandler(this, &frmKeyboard::btnLalt_Click);
			// 
			// button10
			// 
			this->button10->Location = System::Drawing::Point(643, 212);
			this->button10->Name = L"button10";
			this->button10->Size = System::Drawing::Size(36, 33);
			this->button10->TabIndex = 53;
			this->button10->Text = L"<";
			this->button10->UseVisualStyleBackColor = true;
			this->button10->Click += gcnew System::EventHandler(this, &frmKeyboard::button10_Click);
			// 
			// button11
			// 
			this->button11->Location = System::Drawing::Point(685, 212);
			this->button11->Name = L"button11";
			this->button11->Size = System::Drawing::Size(36, 33);
			this->button11->TabIndex = 54;
			this->button11->Text = L"V";
			this->button11->UseVisualStyleBackColor = true;
			this->button11->Click += gcnew System::EventHandler(this, &frmKeyboard::button11_Click);
			// 
			// button12
			// 
			this->button12->Location = System::Drawing::Point(727, 212);
			this->button12->Name = L"button12";
			this->button12->Size = System::Drawing::Size(36, 33);
			this->button12->TabIndex = 55;
			this->button12->Text = L">";
			this->button12->UseVisualStyleBackColor = true;
			this->button12->Click += gcnew System::EventHandler(this, &frmKeyboard::button12_Click);
			// 
			// button13
			// 
			this->button13->Location = System::Drawing::Point(685, 173);
			this->button13->Name = L"button13";
			this->button13->Size = System::Drawing::Size(36, 33);
			this->button13->TabIndex = 56;
			this->button13->Text = L"^";
			this->button13->UseVisualStyleBackColor = true;
			this->button13->Click += gcnew System::EventHandler(this, &frmKeyboard::button13_Click);
			// 
			// button14
			// 
			this->button14->Location = System::Drawing::Point(641, 90);
			this->button14->Name = L"button14";
			this->button14->Size = System::Drawing::Size(38, 34);
			this->button14->TabIndex = 57;
			this->button14->Text = L"Del";
			this->button14->UseVisualStyleBackColor = true;
			this->button14->Click += gcnew System::EventHandler(this, &frmKeyboard::button14_Click);
			// 
			// button15
			// 
			this->button15->Location = System::Drawing::Point(683, 90);
			this->button15->Name = L"button15";
			this->button15->Size = System::Drawing::Size(38, 34);
			this->button15->TabIndex = 58;
			this->button15->Text = L"End";
			this->button15->UseVisualStyleBackColor = true;
			this->button15->Click += gcnew System::EventHandler(this, &frmKeyboard::button15_Click);
			// 
			// button16
			// 
			this->button16->Location = System::Drawing::Point(641, 50);
			this->button16->Name = L"button16";
			this->button16->Size = System::Drawing::Size(38, 34);
			this->button16->TabIndex = 59;
			this->button16->Text = L"Ins";
			this->button16->UseVisualStyleBackColor = true;
			this->button16->Click += gcnew System::EventHandler(this, &frmKeyboard::button16_Click);
			// 
			// button17
			// 
			this->button17->Location = System::Drawing::Point(683, 50);
			this->button17->Name = L"button17";
			this->button17->Size = System::Drawing::Size(38, 34);
			this->button17->TabIndex = 60;
			this->button17->Text = L"Home";
			this->button17->UseVisualStyleBackColor = true;
			this->button17->Click += gcnew System::EventHandler(this, &frmKeyboard::button17_Click);
			// 
			// button18
			// 
			this->button18->Location = System::Drawing::Point(727, 90);
			this->button18->Name = L"button18";
			this->button18->Size = System::Drawing::Size(38, 34);
			this->button18->TabIndex = 61;
			this->button18->Text = L"PgDn";
			this->button18->UseVisualStyleBackColor = true;
			this->button18->Click += gcnew System::EventHandler(this, &frmKeyboard::button18_Click);
			// 
			// button19
			// 
			this->button19->Location = System::Drawing::Point(727, 50);
			this->button19->Name = L"button19";
			this->button19->Size = System::Drawing::Size(38, 34);
			this->button19->TabIndex = 62;
			this->button19->Text = L"PgUp";
			this->button19->UseVisualStyleBackColor = true;
			this->button19->Click += gcnew System::EventHandler(this, &frmKeyboard::button19_Click);
			// 
			// button8
			// 
			this->button8->Location = System::Drawing::Point(24, 48);
			this->button8->Name = L"button8";
			this->button8->Size = System::Drawing::Size(39, 36);
			this->button8->TabIndex = 63;
			this->button8->Text = L"~`";
			this->button8->UseVisualStyleBackColor = true;
			this->button8->Click += gcnew System::EventHandler(this, &frmKeyboard::button8_Click);
			// 
			// button20
			// 
			this->button20->Location = System::Drawing::Point(462, 209);
			this->button20->Name = L"button20";
			this->button20->Size = System::Drawing::Size(58, 33);
			this->button20->TabIndex = 64;
			this->button20->Text = L"Alt";
			this->button20->UseVisualStyleBackColor = true;
			this->button20->Click += gcnew System::EventHandler(this, &frmKeyboard::button20_Click);
			// 
			// buttonLctrl
			// 
			this->buttonLctrl->Location = System::Drawing::Point(24, 209);
			this->buttonLctrl->Name = L"buttonLctrl";
			this->buttonLctrl->Size = System::Drawing::Size(58, 33);
			this->buttonLctrl->TabIndex = 65;
			this->buttonLctrl->Text = L"Ctrl";
			this->buttonLctrl->UseVisualStyleBackColor = true;
			this->buttonLctrl->Click += gcnew System::EventHandler(this, &frmKeyboard::buttonLctrl_Click);
			// 
			// buttonEsc
			// 
			this->buttonEsc->Location = System::Drawing::Point(24, -3);
			this->buttonEsc->Name = L"buttonEsc";
			this->buttonEsc->Size = System::Drawing::Size(39, 36);
			this->buttonEsc->TabIndex = 66;
			this->buttonEsc->Text = L"Esc";
			this->buttonEsc->UseVisualStyleBackColor = true;
			this->buttonEsc->Click += gcnew System::EventHandler(this, &frmKeyboard::buttonEsc_Click);
			// 
			// buttonF1
			// 
			this->buttonF1->Location = System::Drawing::Point(112, -3);
			this->buttonF1->Name = L"buttonF1";
			this->buttonF1->Size = System::Drawing::Size(39, 36);
			this->buttonF1->TabIndex = 67;
			this->buttonF1->Text = L"F1";
			this->buttonF1->UseVisualStyleBackColor = true;
			this->buttonF1->Click += gcnew System::EventHandler(this, &frmKeyboard::buttonF1_Click);
			// 
			// buttonF2
			// 
			this->buttonF2->Location = System::Drawing::Point(154, -3);
			this->buttonF2->Name = L"buttonF2";
			this->buttonF2->Size = System::Drawing::Size(39, 36);
			this->buttonF2->TabIndex = 68;
			this->buttonF2->Text = L"F2";
			this->buttonF2->UseVisualStyleBackColor = true;
			this->buttonF2->Click += gcnew System::EventHandler(this, &frmKeyboard::buttonF2_Click);
			// 
			// buttonF3
			// 
			this->buttonF3->Location = System::Drawing::Point(192, -3);
			this->buttonF3->Name = L"buttonF3";
			this->buttonF3->Size = System::Drawing::Size(39, 36);
			this->buttonF3->TabIndex = 69;
			this->buttonF3->Text = L"F3";
			this->buttonF3->UseVisualStyleBackColor = true;
			// 
			// buttonF4
			// 
			this->buttonF4->Location = System::Drawing::Point(235, -3);
			this->buttonF4->Name = L"buttonF4";
			this->buttonF4->Size = System::Drawing::Size(39, 36);
			this->buttonF4->TabIndex = 70;
			this->buttonF4->Text = L"F4";
			this->buttonF4->UseVisualStyleBackColor = true;
			// 
			// buttonF5
			// 
			this->buttonF5->Location = System::Drawing::Point(287, -3);
			this->buttonF5->Name = L"buttonF5";
			this->buttonF5->Size = System::Drawing::Size(39, 36);
			this->buttonF5->TabIndex = 71;
			this->buttonF5->Text = L"F5";
			this->buttonF5->UseVisualStyleBackColor = true;
			// 
			// buttonF6
			// 
			this->buttonF6->Location = System::Drawing::Point(327, -3);
			this->buttonF6->Name = L"buttonF6";
			this->buttonF6->Size = System::Drawing::Size(39, 36);
			this->buttonF6->TabIndex = 72;
			this->buttonF6->Text = L"F6";
			this->buttonF6->UseVisualStyleBackColor = true;
			// 
			// buttonF7
			// 
			this->buttonF7->Location = System::Drawing::Point(363, -3);
			this->buttonF7->Name = L"buttonF7";
			this->buttonF7->Size = System::Drawing::Size(39, 36);
			this->buttonF7->TabIndex = 73;
			this->buttonF7->Text = L"F7";
			this->buttonF7->UseVisualStyleBackColor = true;
			// 
			// buttonF8
			// 
			this->buttonF8->Location = System::Drawing::Point(403, -3);
			this->buttonF8->Name = L"buttonF8";
			this->buttonF8->Size = System::Drawing::Size(39, 36);
			this->buttonF8->TabIndex = 74;
			this->buttonF8->Text = L"F8";
			this->buttonF8->UseVisualStyleBackColor = true;
			// 
			// buttonF9
			// 
			this->buttonF9->Location = System::Drawing::Point(462, -3);
			this->buttonF9->Name = L"buttonF9";
			this->buttonF9->Size = System::Drawing::Size(39, 36);
			this->buttonF9->TabIndex = 75;
			this->buttonF9->Text = L"F9";
			this->buttonF9->UseVisualStyleBackColor = true;
			// 
			// buttonF10
			// 
			this->buttonF10->Location = System::Drawing::Point(506, -3);
			this->buttonF10->Name = L"buttonF10";
			this->buttonF10->Size = System::Drawing::Size(39, 36);
			this->buttonF10->TabIndex = 76;
			this->buttonF10->Text = L"F10";
			this->buttonF10->UseVisualStyleBackColor = true;
			// 
			// buttonF11
			// 
			this->buttonF11->Location = System::Drawing::Point(551, -3);
			this->buttonF11->Name = L"buttonF11";
			this->buttonF11->Size = System::Drawing::Size(39, 36);
			this->buttonF11->TabIndex = 77;
			this->buttonF11->Text = L"F11";
			this->buttonF11->UseVisualStyleBackColor = true;
			// 
			// buttonF12
			// 
			this->buttonF12->Location = System::Drawing::Point(596, -3);
			this->buttonF12->Name = L"buttonF12";
			this->buttonF12->Size = System::Drawing::Size(39, 36);
			this->buttonF12->TabIndex = 78;
			this->buttonF12->Text = L"F12";
			this->buttonF12->UseVisualStyleBackColor = true;
			// 
			// buttonCapslock
			// 
			this->buttonCapslock->Location = System::Drawing::Point(24, 130);
			this->buttonCapslock->Name = L"buttonCapslock";
			this->buttonCapslock->Size = System::Drawing::Size(63, 33);
			this->buttonCapslock->TabIndex = 79;
			this->buttonCapslock->Text = L"CapsLock";
			this->buttonCapslock->UseVisualStyleBackColor = true;
			this->buttonCapslock->Click += gcnew System::EventHandler(this, &frmKeyboard::buttonCapslock_Click);
			// 
			// button21
			// 
			this->button21->Location = System::Drawing::Point(641, -1);
			this->button21->Name = L"button21";
			this->button21->Size = System::Drawing::Size(38, 34);
			this->button21->TabIndex = 80;
			this->button21->Text = L"Prt Scr";
			this->button21->UseVisualStyleBackColor = true;
			// 
			// button22
			// 
			this->button22->Location = System::Drawing::Point(683, -1);
			this->button22->Name = L"button22";
			this->button22->Size = System::Drawing::Size(38, 34);
			this->button22->TabIndex = 81;
			this->button22->Text = L"Scr Lck";
			this->button22->UseVisualStyleBackColor = true;
			// 
			// button23
			// 
			this->button23->Location = System::Drawing::Point(727, -1);
			this->button23->Name = L"button23";
			this->button23->Size = System::Drawing::Size(38, 34);
			this->button23->TabIndex = 82;
			this->button23->Text = L"Pause";
			this->button23->UseVisualStyleBackColor = true;
			// 
			// buttonTab
			// 
			this->buttonTab->Location = System::Drawing::Point(24, 90);
			this->buttonTab->Name = L"buttonTab";
			this->buttonTab->Size = System::Drawing::Size(53, 33);
			this->buttonTab->TabIndex = 83;
			this->buttonTab->Text = L"Tab <-|";
			this->buttonTab->UseVisualStyleBackColor = true;
			this->buttonTab->Click += gcnew System::EventHandler(this, &frmKeyboard::buttonTab_Click);
			// 
			// frmKeyboard
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(778, 252);
			this->Controls->Add(this->buttonTab);
			this->Controls->Add(this->button23);
			this->Controls->Add(this->button22);
			this->Controls->Add(this->button21);
			this->Controls->Add(this->buttonCapslock);
			this->Controls->Add(this->buttonF12);
			this->Controls->Add(this->buttonF11);
			this->Controls->Add(this->buttonF10);
			this->Controls->Add(this->buttonF9);
			this->Controls->Add(this->buttonF8);
			this->Controls->Add(this->buttonF7);
			this->Controls->Add(this->buttonF6);
			this->Controls->Add(this->buttonF5);
			this->Controls->Add(this->buttonF4);
			this->Controls->Add(this->buttonF3);
			this->Controls->Add(this->buttonF2);
			this->Controls->Add(this->buttonF1);
			this->Controls->Add(this->buttonEsc);
			this->Controls->Add(this->buttonLctrl);
			this->Controls->Add(this->button20);
			this->Controls->Add(this->button8);
			this->Controls->Add(this->button19);
			this->Controls->Add(this->button18);
			this->Controls->Add(this->button17);
			this->Controls->Add(this->button16);
			this->Controls->Add(this->button15);
			this->Controls->Add(this->button14);
			this->Controls->Add(this->button13);
			this->Controls->Add(this->button12);
			this->Controls->Add(this->button11);
			this->Controls->Add(this->button10);
			this->Controls->Add(this->btnLalt);
			this->Controls->Add(this->btnRctrl);
			this->Controls->Add(this->btnBackspace);
			this->Controls->Add(this->button9);
			this->Controls->Add(this->btnMinus);
			this->Controls->Add(this->button7);
			this->Controls->Add(this->button6);
			this->Controls->Add(this->button5);
			this->Controls->Add(this->button4);
			this->Controls->Add(this->button3);
			this->Controls->Add(this->button2);
			this->Controls->Add(this->button1);
			this->Controls->Add(this->btnSpace);
			this->Controls->Add(this->btn0);
			this->Controls->Add(this->btn9);
			this->Controls->Add(this->btn8);
			this->Controls->Add(this->btn7);
			this->Controls->Add(this->btn6);
			this->Controls->Add(this->btn5);
			this->Controls->Add(this->btn4);
			this->Controls->Add(this->btn3);
			this->Controls->Add(this->btn2);
			this->Controls->Add(this->btn1);
			this->Controls->Add(this->btnM);
			this->Controls->Add(this->btnN);
			this->Controls->Add(this->btnB);
			this->Controls->Add(this->btnV);
			this->Controls->Add(this->btnC);
			this->Controls->Add(this->btnL);
			this->Controls->Add(this->btnK);
			this->Controls->Add(this->btnJ);
			this->Controls->Add(this->btnH);
			this->Controls->Add(this->btnX);
			this->Controls->Add(this->btnZ);
			this->Controls->Add(this->btnG);
			this->Controls->Add(this->btnF);
			this->Controls->Add(this->btnD);
			this->Controls->Add(this->btnS);
			this->Controls->Add(this->btnA);
			this->Controls->Add(this->btnP);
			this->Controls->Add(this->btnLshift);
			this->Controls->Add(this->btnO);
			this->Controls->Add(this->btnRshift);
			this->Controls->Add(this->btnI);
			this->Controls->Add(this->btnU);
			this->Controls->Add(this->btnY);
			this->Controls->Add(this->btnT);
			this->Controls->Add(this->btnR);
			this->Controls->Add(this->btnEnter);
			this->Controls->Add(this->btnQuest);
			this->Controls->Add(this->btnE);
			this->Controls->Add(this->btnW);
			this->Controls->Add(this->btnQ);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
			this->MaximizeBox = false;
			this->Name = L"frmKeyboard";
			this->Text = L"E64 Keyboard";
			this->Load += gcnew System::EventHandler(this, &frmKeyboard::frmKeyboard_Load);
			this->MouseUp += gcnew System::Windows::Forms::MouseEventHandler(this, &frmKeyboard::frmKeyboard_MouseUp);
			this->ResumeLayout(false);

		}
#pragma endregion
	private: System::Void btnQuest_Click(System::Object^  sender, System::EventArgs^  e) {
				 keybd.Put(0x4A);
				 keybd.Put(0xF0);
				 keybd.Put(0x4A);
				 keybd_status = 0x80;
     			 pic1.irqKeyboard = true;
			 }
private: System::Void btnEnter_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x5A);
			 keybd.Put(0xF0);
			 keybd.Put(0x5A);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnRshift_Click(System::Object^  sender, System::EventArgs^  e) {
			 static bool sh = false;

			 if (sh!=0)
			     keybd.Put(0xF0);
			 keybd.Put(0x59);
			 sh = !sh;
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn1_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x16);
			 keybd.Put(0xF0);
			 keybd.Put(0x16);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnD_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x23);
			 keybd.Put(0xF0);
			 keybd.Put(0x23);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnB_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x32);
			 keybd.Put(0xF0);
			 keybd.Put(0x32);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnG_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x34);
			 keybd.Put(0xF0);
			 keybd.Put(0x34);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnQ_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x15);
			 keybd.Put(0xF0);
			 keybd.Put(0x15);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnT_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x2C);
			 keybd.Put(0xF0);
			 keybd.Put(0x2C);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnS_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x1B);
			 keybd.Put(0xF0);
			 keybd.Put(0x1B);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnM_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x3A);
			 keybd.Put(0xF0);
			 keybd.Put(0x3A);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnMinus_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x4E);
			 keybd.Put(0xF0);
			 keybd.Put(0x4E);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnBackspace_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x66);
			 keybd.Put(0xF0);
			 keybd.Put(0x66);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button14_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x71);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x71);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnJ_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x3B);
			 keybd.Put(0xF0);
			 keybd.Put(0x3B);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnSpace_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x29);
			 keybd.Put(0xF0);
			 keybd.Put(0x29);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button10_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x6B);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x6B);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn2_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x1E);
			 keybd.Put(0xF0);
			 keybd.Put(0x1E);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn3_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x26);
			 keybd.Put(0xF0);
			 keybd.Put(0x26);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn4_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x25);
			 keybd.Put(0xF0);
			 keybd.Put(0x25);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn5_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x2E);
			 keybd.Put(0xF0);
			 keybd.Put(0x2E);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn6_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x36);
			 keybd.Put(0xF0);
			 keybd.Put(0x36);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn7_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x3D);
			 keybd.Put(0xF0);
			 keybd.Put(0x3D);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn8_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x3E);
			 keybd.Put(0xF0);
			 keybd.Put(0x3E);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn9_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x46);
			 keybd.Put(0xF0);
			 keybd.Put(0x46);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btn0_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x45);
			 keybd.Put(0xF0);
			 keybd.Put(0x45);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnA_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x1C);
			 keybd.Put(0xF0);
			 keybd.Put(0x1C);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnC_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x21);
			 keybd.Put(0xF0);
			 keybd.Put(0x21);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnE_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x24);
			 keybd.Put(0xF0);
			 keybd.Put(0x24);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnF_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x2B);
			 keybd.Put(0xF0);
			 keybd.Put(0x2B);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnX_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x22);
			 keybd.Put(0xF0);
			 keybd.Put(0x22);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnRctrl_Click(System::Object^  sender, System::EventArgs^  e) {
			 static bool sh = false;
			 keybd.Put(0xE0);
			 if (sh!=0)
			     keybd.Put(0xF0);
			 keybd.Put(0x14);
			 sh = !sh;
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button9_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x55);
			 keybd.Put(0xF0);
			 keybd.Put(0x55);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button8_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x0E);
			 keybd.Put(0xF0);
			 keybd.Put(0x0E);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnW_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x1D);
			 keybd_status = 0x80;
			 keybd.Put(0xF0);
			 keybd.Put(0x1D);
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnR_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x2D);
			 keybd.Put(0xF0);
			 keybd.Put(0x2D);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnY_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x35);
			 keybd.Put(0xF0);
			 keybd.Put(0x35);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnU_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x3C);
			 keybd.Put(0xF0);
			 keybd.Put(0x3C);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnI_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x43);
			 keybd.Put(0xF0);
			 keybd.Put(0x43);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnO_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x44);
			 keybd.Put(0xF0);
			 keybd.Put(0x44);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnP_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x4D);
			 keybd.Put(0xF0);
			 keybd.Put(0x4D);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnH_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x33);
			 keybd.Put(0xF0);
			 keybd.Put(0x33);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnK_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x42);
			 keybd.Put(0xF0);
			 keybd.Put(0x42);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnL_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x4B);
			 keybd.Put(0xF0);
			 keybd.Put(0x4B);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button3_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x4C);
			 keybd.Put(0xF0);
			 keybd.Put(0x4C);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button4_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x52);
			 keybd.Put(0xF0);
			 keybd.Put(0x52);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnZ_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x1A);
			 keybd.Put(0xF0);
			 keybd.Put(0x1A);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnV_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x2A);
			 keybd.Put(0xF0);
			 keybd.Put(0x2A);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnN_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x31);
			 keybd.Put(0xF0);
			 keybd.Put(0x31);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x41);
			 keybd.Put(0xF0);
			 keybd.Put(0x41);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button2_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x49);
			 keybd.Put(0xF0);
			 keybd.Put(0x49);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button5_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x5D);
			 keybd.Put(0xF0);
			 keybd.Put(0x5D);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void btnLalt_Click(System::Object^  sender, System::EventArgs^  e) {
			 static bool sh = false;
			 if (sh!=0)
			     keybd.Put(0xF0);
			 keybd.Put(0x11);
			 sh = !sh;
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // Alt
private: System::Void button20_Click(System::Object^  sender, System::EventArgs^  e) {
			 static bool sh = false;
			 keybd.Put(0xE0);
			 if (sh!=0)
			     keybd.Put(0xF0);
			 keybd.Put(0x11);
			 sh = !sh;
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void buttonLctrl_Click(System::Object^  sender, System::EventArgs^  e) {
			 static bool sh = false;
			 if (sh!=0)
			     keybd.Put(0xF0);
			 keybd.Put(0x14);
			 sh = !sh;
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button16_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x70);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x70);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // Home
private: System::Void button17_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x6C);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x6C);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // End
private: System::Void button15_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x69);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x69);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // Cursor down
private: System::Void button11_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x72);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x72);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // Cursor Up
private: System::Void button13_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x75);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x75);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // Cursor right
private: System::Void button12_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x74);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x74);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // page up
private: System::Void button19_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x7D);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x7D);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
		 // page down
private: System::Void button18_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0xE0);
			 keybd.Put(0x7A);
			 keybd.Put(0xE0);
			 keybd.Put(0xF0);
			 keybd.Put(0x7A);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button6_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x54);
			 keybd.Put(0xF0);
			 keybd.Put(0x54);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void button7_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x5B);
			 keybd.Put(0xF0);
			 keybd.Put(0x5B);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void buttonEsc_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x76);
			 keybd.Put(0xF0);
			 keybd.Put(0x76);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void buttonF1_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x05);
			 keybd.Put(0xF0);
			 keybd.Put(0x05);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void buttonF2_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x06);
			 keybd.Put(0xF0);
			 keybd.Put(0x06);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void buttonCapslock_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x58);
			 keybd_status = 0x80;
			 keybd.Put(0xF0);
			 keybd.Put(0x58);
			 pic1.irqKeyboard = true;
		 }
private: System::Void frmKeyboard_MouseUp(System::Object^  sender, System::Windows::Forms::MouseEventArgs^  e) {
		 }
private: System::Void buttonTab_Click(System::Object^  sender, System::EventArgs^  e) {
			 keybd.Put(0x0D);
			 keybd.Put(0xF0);
			 keybd.Put(0x0D);
			 keybd_status = 0x80;
			 pic1.irqKeyboard = true;
		 }
private: System::Void frmKeyboard_Load(System::Object^  sender, System::EventArgs^  e) {
		 }
};
}
