// emuFISA64.cpp : main project file.

#include "stdafx.h"
#include "frmRegisters.h"
#include "frmMain.h"
#include "clsCPU.h"
#include "clsSystem.h"

clsCPU cpu1;
clsSystem system1;

using namespace emuFISA64;

[STAThreadAttribute]
int main(array<System::String ^> ^args)
{
	// Enabling Windows XP visual effects before any controls are created
	Application::EnableVisualStyles();
	Application::SetCompatibleTextRenderingDefault(false); 

	// Create the main window and run it
	Application::Run(gcnew frmMain());
	return 0;
}
