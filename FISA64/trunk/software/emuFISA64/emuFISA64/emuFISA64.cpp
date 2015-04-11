// emuFISA64.cpp : main project file.

#include "stdafx.h"
#include "frmRegisters.h"
#include "frmMain.h"
#include "frmScreen.h"
#include "clsCPU.h"
#include "clsSystem.h"

clsCPU cpu1;
clsSystem system1;
char refscreen;
unsigned int breakpoints[30];
int numBreakpoints;

using namespace emuFISA64;

[STAThreadAttribute]
int main(array<System::String ^> ^args)
{
	// Enabling Windows XP visual effects before any controls are created
	Application::EnableVisualStyles();
	Application::SetCompatibleTextRenderingDefault(false); 
	numBreakpoints = 0;
	// Create the main window and run it
	Application::Run(gcnew frmMain());
	return 0;
}
