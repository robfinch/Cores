// E64.cpp : main project file.

#include "stdafx.h"
#include "frmRegisters.h"
#include "frmMain.h"
#include "frmScreen.h"
#include "clsCPU.h"
#include "clsSystem.h"
#include "clsKeyboard.h"

clsCPU cpu1;
clsPIC pic1;
clsSystem system1;
clsKeyboard keybd;
volatile unsigned __int8 keybd_scancode;
volatile unsigned __int8 keybd_status;
volatile unsigned int interval1024;
volatile unsigned int interval30;

char refscreen;
unsigned int breakpoints[30];
unsigned int dataBreakpoints[30];
int numBreakpoints;
int numDataBreakpoints;
int runstop;
bool irq1024Hz;
bool irq30Hz;
bool irqKeyboard;
bool trigger30;
bool trigger1024;


using namespace E64;

[STAThreadAttribute]
int main(cli::array<System::String ^> ^args)
{
	// Enabling Windows XP visual effects before any controls are created
	Application::EnableVisualStyles();
	Application::SetCompatibleTextRenderingDefault(false); 

	// Create the main window and run it
	Application::Run(gcnew frmMain());
	return 0;
}
