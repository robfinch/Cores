#pragma once
extern bool irq1024Hz;
extern bool irq30Hz;
extern bool irqKeyboard;
extern bool trigger30;
extern bool trigger1024;
extern volatile unsigned int interval1024;
extern volatile unsigned int interval30;

namespace E64 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for frmInterrupts
	/// </summary>
	public ref class frmInterrupts : public System::Windows::Forms::Form
	{
	public:
		frmInterrupts(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			//this->checkBox30->Checked = irq30Hz;
			//this->checkBox1024->Checked = irq1024Hz;
			//this->checkBoxKeyboard->Checked = irqKeyboard;
			trigger30 = false;
			trigger1024 = false;
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmInterrupts()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::CheckBox^  checkBox30;
	protected: 
	private: System::Windows::Forms::CheckBox^  checkBoxKeyboard;
	private: System::Windows::Forms::CheckBox^  checkBox1024;
	private: System::Windows::Forms::ComboBox^  comboBox1024;
	private: System::Windows::Forms::Button^  btnTrigger1024;
	private: System::Windows::Forms::Button^  btnTrigger30;



	private: System::Windows::Forms::ComboBox^  comboBox30;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Button^  btnOK;


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
			this->checkBox30 = (gcnew System::Windows::Forms::CheckBox());
			this->checkBoxKeyboard = (gcnew System::Windows::Forms::CheckBox());
			this->checkBox1024 = (gcnew System::Windows::Forms::CheckBox());
			this->comboBox1024 = (gcnew System::Windows::Forms::ComboBox());
			this->btnTrigger1024 = (gcnew System::Windows::Forms::Button());
			this->btnTrigger30 = (gcnew System::Windows::Forms::Button());
			this->comboBox30 = (gcnew System::Windows::Forms::ComboBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->btnOK = (gcnew System::Windows::Forms::Button());
			this->SuspendLayout();
			// 
			// checkBox30
			// 
			this->checkBox30->AutoSize = true;
			this->checkBox30->Location = System::Drawing::Point(18, 67);
			this->checkBox30->Name = L"checkBox30";
			this->checkBox30->Size = System::Drawing::Size(51, 17);
			this->checkBox30->TabIndex = 0;
			this->checkBox30->Text = L"30Hz";
			this->checkBox30->UseVisualStyleBackColor = true;
			// 
			// checkBoxKeyboard
			// 
			this->checkBoxKeyboard->AutoSize = true;
			this->checkBoxKeyboard->Location = System::Drawing::Point(18, 90);
			this->checkBoxKeyboard->Name = L"checkBoxKeyboard";
			this->checkBoxKeyboard->Size = System::Drawing::Size(71, 17);
			this->checkBoxKeyboard->TabIndex = 1;
			this->checkBoxKeyboard->Text = L"Keyboard";
			this->checkBoxKeyboard->UseVisualStyleBackColor = true;
			// 
			// checkBox1024
			// 
			this->checkBox1024->AutoSize = true;
			this->checkBox1024->Location = System::Drawing::Point(18, 44);
			this->checkBox1024->Name = L"checkBox1024";
			this->checkBox1024->Size = System::Drawing::Size(63, 17);
			this->checkBox1024->TabIndex = 2;
			this->checkBox1024->Text = L"1024Hz";
			this->checkBox1024->UseVisualStyleBackColor = true;
			// 
			// comboBox1024
			// 
			this->comboBox1024->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->comboBox1024->FormattingEnabled = true;
			this->comboBox1024->Items->AddRange(gcnew cli::array< System::Object^  >(3) {L"102 Hz", L"1 Hz", L"One shot"});
			this->comboBox1024->Location = System::Drawing::Point(115, 40);
			this->comboBox1024->Name = L"comboBox1024";
			this->comboBox1024->Size = System::Drawing::Size(121, 21);
			this->comboBox1024->TabIndex = 3;
			this->comboBox1024->SelectedIndexChanged += gcnew System::EventHandler(this, &frmInterrupts::comboBox1024_SelectedIndexChanged);
			// 
			// btnTrigger1024
			// 
			this->btnTrigger1024->Location = System::Drawing::Point(252, 38);
			this->btnTrigger1024->Name = L"btnTrigger1024";
			this->btnTrigger1024->Size = System::Drawing::Size(75, 23);
			this->btnTrigger1024->TabIndex = 4;
			this->btnTrigger1024->Text = L"Trigger";
			this->btnTrigger1024->UseVisualStyleBackColor = true;
			this->btnTrigger1024->Click += gcnew System::EventHandler(this, &frmInterrupts::btnTrigger1024_Click);
			// 
			// btnTrigger30
			// 
			this->btnTrigger30->Location = System::Drawing::Point(252, 67);
			this->btnTrigger30->Name = L"btnTrigger30";
			this->btnTrigger30->Size = System::Drawing::Size(75, 23);
			this->btnTrigger30->TabIndex = 6;
			this->btnTrigger30->Text = L"Trigger";
			this->btnTrigger30->UseVisualStyleBackColor = true;
			this->btnTrigger30->Click += gcnew System::EventHandler(this, &frmInterrupts::btnTrigger30_Click);
			// 
			// comboBox30
			// 
			this->comboBox30->DropDownStyle = System::Windows::Forms::ComboBoxStyle::DropDownList;
			this->comboBox30->FormattingEnabled = true;
			this->comboBox30->Items->AddRange(gcnew cli::array< System::Object^  >(5) {L"30Hz", L"3 Hz", L"Every 3 seconds", L"Every 30 Seconds", 
				L"One shot"});
			this->comboBox30->Location = System::Drawing::Point(115, 69);
			this->comboBox30->Name = L"comboBox30";
			this->comboBox30->Size = System::Drawing::Size(121, 21);
			this->comboBox30->TabIndex = 5;
			this->comboBox30->SelectedIndexChanged += gcnew System::EventHandler(this, &frmInterrupts::comboBox2_SelectedIndexChanged);
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(15, 18);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(77, 13);
			this->label1->TabIndex = 7;
			this->label1->Text = L"Source Enable";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(112, 18);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(57, 13);
			this->label2->TabIndex = 8;
			this->label2->Text = L"Frequency";
			// 
			// btnOK
			// 
			this->btnOK->DialogResult = System::Windows::Forms::DialogResult::OK;
			this->btnOK->Location = System::Drawing::Point(252, 112);
			this->btnOK->Name = L"btnOK";
			this->btnOK->Size = System::Drawing::Size(75, 23);
			this->btnOK->TabIndex = 9;
			this->btnOK->Text = L"OK";
			this->btnOK->UseVisualStyleBackColor = true;
			this->btnOK->Click += gcnew System::EventHandler(this, &frmInterrupts::btnOK_Click);
			// 
			// frmInterrupts
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(360, 156);
			this->Controls->Add(this->btnOK);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->btnTrigger30);
			this->Controls->Add(this->comboBox30);
			this->Controls->Add(this->btnTrigger1024);
			this->Controls->Add(this->comboBox1024);
			this->Controls->Add(this->checkBox1024);
			this->Controls->Add(this->checkBoxKeyboard);
			this->Controls->Add(this->checkBox30);
			this->MaximizeBox = false;
			this->MinimizeBox = false;
			this->Name = L"frmInterrupts";
			this->Text = L"E64 Interrupts";
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void comboBox2_SelectedIndexChanged(System::Object^  sender, System::EventArgs^  e) {
			 }
private: System::Void btnOK_Click(System::Object^  sender, System::EventArgs^  e) {
			 this->Hide();
			 //irq30Hz = this->checkBox30->Checked;
			 //irq1024Hz = this->checkBoc1024->Checked;
			 //irqKeyboard = this->checkBoxKeyboard->Checked;
		 }
private: System::Void btnTrigger1024_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (this->checkBox1024->Checked) {
			 switch(this->comboBox30->SelectedIndex) {
			 case 0: interval1024 = 98; break;
			 case 1: interval1024 = 977; break;
			 case 2: interval1024 = -1; break;
			 }
			 trigger1024 = true;
			 }
		 }
private: System::Void btnTrigger30_Click(System::Object^  sender, System::EventArgs^  e) {
			 if (this->checkBox30->Checked) {
			 switch(this->comboBox30->SelectedIndex) {
			 case 0: interval30 = 33; break;
			 case 1: interval30 = 333; break;
			 case 2: interval30 = 3333; break;
			 case 3: interval30 = 33333; break;
			 case 4: interval30 = -1; break;
			 }
			 trigger30 = true;
			 }
		 }
private: System::Void comboBox1024_SelectedIndexChanged(System::Object^  sender, System::EventArgs^  e) {
		 }
};
}
