#pragma once
#include <string>

#include <msclr\marshal_cppstd.h>

#include "dpcdecl.h"
#include "dmgr.h"
#include "dpti.h"

namespace PTI2 {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for PTIMain
	/// </summary>
	public ref class PTIMain : public System::Windows::Forms::Form
	{
	public:
		PTIMain(void)
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
		~PTIMain()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::MenuStrip^  menuStrip1;
	protected:
	private: System::Windows::Forms::ToolStripMenuItem^  fileToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  sendFileToolStripMenuItem;
	private: System::Windows::Forms::ToolStripMenuItem^  openFileToolStripMenuItem;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;

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
			this->menuStrip1 = (gcnew System::Windows::Forms::MenuStrip());
			this->fileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->sendFileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->openFileToolStripMenuItem = (gcnew System::Windows::Forms::ToolStripMenuItem());
			this->menuStrip1->SuspendLayout();
			this->SuspendLayout();
			// 
			// menuStrip1
			// 
			this->menuStrip1->ImageScalingSize = System::Drawing::Size(20, 20);
			this->menuStrip1->Items->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(1) { this->fileToolStripMenuItem });
			this->menuStrip1->Location = System::Drawing::Point(0, 0);
			this->menuStrip1->Name = L"menuStrip1";
			this->menuStrip1->Size = System::Drawing::Size(471, 28);
			this->menuStrip1->TabIndex = 0;
			this->menuStrip1->Text = L"menuStrip1";
			// 
			// fileToolStripMenuItem
			// 
			this->fileToolStripMenuItem->DropDownItems->AddRange(gcnew cli::array< System::Windows::Forms::ToolStripItem^  >(2) {
				this->sendFileToolStripMenuItem,
					this->openFileToolStripMenuItem
			});
			this->fileToolStripMenuItem->Name = L"fileToolStripMenuItem";
			this->fileToolStripMenuItem->Size = System::Drawing::Size(44, 24);
			this->fileToolStripMenuItem->Text = L"&File";
			// 
			// sendFileToolStripMenuItem
			// 
			this->sendFileToolStripMenuItem->Name = L"sendFileToolStripMenuItem";
			this->sendFileToolStripMenuItem->Size = System::Drawing::Size(216, 26);
			this->sendFileToolStripMenuItem->Text = L"&Send File";
			this->sendFileToolStripMenuItem->Click += gcnew System::EventHandler(this, &PTIMain::sendFileToolStripMenuItem_Click);
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->FileName = L"openFileDialog1";
			// 
			// openFileToolStripMenuItem
			// 
			this->openFileToolStripMenuItem->Name = L"openFileToolStripMenuItem";
			this->openFileToolStripMenuItem->Size = System::Drawing::Size(216, 26);
			this->openFileToolStripMenuItem->Text = L"&Open File";
			this->openFileToolStripMenuItem->Click += gcnew System::EventHandler(this, &PTIMain::openFileToolStripMenuItem_Click);
			// 
			// PTIMain
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(8, 16);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(471, 299);
			this->Controls->Add(this->menuStrip1);
			this->MainMenuStrip = this->menuStrip1;
			this->Name = L"PTIMain";
			this->Text = L"PTIMain";
			this->menuStrip1->ResumeLayout(false);
			this->menuStrip1->PerformLayout();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void sendFileToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
	}
	private: System::Void openFileToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e) {
		if (this->openFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK) {
			HIF hif;
			int cprtPti;
			DPRP dprpPti;
			int fSuccess;
			BYTE pbIn[10000];
			int prtReq = 1;
			System::String^ str;

			System::String^ text;
			System::String^ dvName = "NexysVideo";
			System::IO::StreamReader^ strm = gcnew System::IO::StreamReader(this->openFileDialog1->FileName);
			text = strm->ReadToEnd();
			//MessageBox::Show(text);
			strm->Close();
			msclr::interop::marshal_context context;
			std::string cdvName = context.marshal_as<std::string>(dvName);
			std::string cText = context.marshal_as<std::string>(text);
			if (!DmgrOpen(&hif, (char *)cdvName.c_str())) {
				MessageBox::Show(String::Format("Can't open device {0}", dvName));
				goto j1;
			}
			// Determine how many DPTI ports the device supports.
			if (!DptiGetPortCount(hif, &cprtPti)) {
				MessageBox::Show(String::Format("ERROR: failed to determine DPTI port count, erc = {0}", DmgrGetLastError()));
				goto j1;
			}
			// Make sure that the device supports DPTI.
			if (0 == cprtPti) {
				MessageBox::Show(String::Format("ERROR: {0} does not support DPTI", dvName));
				goto j1;
			}
			// Make sure that the user specified DPTI port is supported by the device.
			if (prtReq >= cprtPti) {
				MessageBox::Show(String::Format("ERROR: invalid DPTI port specified: {0}\n"
					"{1} supports DPTI on the following ports : \n", prtReq, dvName));
				str = "";
				for (int iprt = 0; iprt < cprtPti; iprt++) {
					str = str + System::Convert::ToString(iprt);
				}
				MessageBox::Show(str);
				goto j1;
			}
			// Obtain the port properties associated with the specified DPTI port.
			if (!DptiGetPortProperties(hif, prtReq, &dprpPti)) {
				MessageBox::Show(String::Format("ERROR: failed to get DPTI port properties erc = {0}\n", DmgrGetLastError()));
				goto j1;
			}
			// Enable the specified DPTI port.
			if (!DptiEnableEx(hif, prtReq)) {
				MessageBox::Show(String::Format("ERROR: failed to enable PTI, erc = {0}\n", DmgrGetLastError()));
				goto j1;
			}
			fSuccess = DptiIO(hif, (BYTE *)cText.c_str(), cText.length(), (BYTE *)pbIn, 10000, fFalse);

			// Disable the DPTI port.
			if (!DptiDisable(hif)) {
				MessageBox::Show(String::Format("ERROR: failed to disable PTI port, erc = {0}\n", DmgrGetLastError()));
				goto j1;
			}
			// Close the device handle.
			if (!DmgrClose(hif)) {
				MessageBox::Show(String::Format("ERROR: failed to close device handle, erc = {0}\n", DmgrGetLastError()));
				goto j1;
			}
			return;
		j1:;
			if (hifInvalid != hif) {
				DptiDisable(hif);
				DmgrClose(hif);
			}
		}
	}
};
}
