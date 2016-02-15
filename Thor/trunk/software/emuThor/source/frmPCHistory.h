#pragma once

namespace emuThor {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Threading;

	/// <summary>
	/// Summary for frmPCHistory
	/// </summary>
	public ref class frmPCHistory : public System::Windows::Forms::Form
	{
	public:
		frmPCHistory(Mutex^ m)
		{
			mut = m;
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			char buf[4000];
			int xx;
			buf[0] = '\0';
			for (xx = 0; xx < 40; xx++) {
				mut->WaitOne();
				sprintf(&buf[strlen(buf)], "%08I64X\r\n", system1.cpu2.pcs[xx]);
				mut->ReleaseMutex();
			}
			textBox1->Text = gcnew String(buf);
		}
		frmPCHistory(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			char buf[4000];
			int xx;
			buf[0] = '\0';
			for (xx = 0; xx < 40; xx++) {
				mut->WaitOne();
				sprintf(&buf[strlen(buf)], "%08I64X\r\n", system1.cpu2.pcs[xx]);
				mut->ReleaseMutex();
			}
			textBox1->Text = gcnew String(buf);
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~frmPCHistory()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::TextBox^  textBox1;
	public:	Mutex^ mut;
	protected: 

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
			this->textBox1 = (gcnew System::Windows::Forms::TextBox());
			this->SuspendLayout();
			// 
			// textBox1
			// 
			this->textBox1->Location = System::Drawing::Point(12, 22);
			this->textBox1->Multiline = true;
			this->textBox1->Name = L"textBox1";
			this->textBox1->Size = System::Drawing::Size(162, 385);
			this->textBox1->TabIndex = 0;
			// 
			// frmPCHistory
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(193, 438);
			this->Controls->Add(this->textBox1);
			this->FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedSingle;
			this->Name = L"frmPCHistory";
			this->Text = L"PCHistory";
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	};
}
