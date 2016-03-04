#include "stdafx.h"

#define XUSER_MAX_COUNT	4
#define INPUT_DEADZONE	

void Gamepad::GetState(int i)
{
	DWORD dwResult;

	ZeroMemory(&states[i], sizeof(XINPUT_STATE));

	dwResult = XInputGetState(i, &states[i]);
}

int Gamepad::GetNumbers()
{
	DWORD n;
	DWORD dwResult;
	DWORD i;

	XINPUT_STATE state;
	ZeroMemory(&state, sizeof(XINPUT_STATE));

	for (n = i = 0; i < XUSER_MAX_COUNT; i++) {
		dwResult = XInputGetState(i, &state);
		if (dwResult==ERROR_SUCCESS) {
			n |= (1 << i);
		}
	}
	return n;
}

void Gamepad::CalcStates(int i)
{
	XINPUT_STATE state = states[i];

	float LX = state.Gamepad.sThumbLX;
	float LY = state.Gamepad.sThumbLY;

	//determine how far the controller is pushed
	float magnitude = sqrt(LX*LX + LY*LY);

	//determine the direction the controller is pushed
	normalizedLX[i] = LX / magnitude;
	normalizedLY[i] = LY / magnitude;

	normalizedMagnitude[i] = 0;

	//check if the controller is outside a circular dead zone
	if (magnitude > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE)
	{
	  //clip the magnitude at its expected maximum value
	  if (magnitude > 32767) magnitude = 32767;
  
	  //adjust magnitude relative to the end of the dead zone
	  magnitude -= XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE;

	  //optionally normalize the magnitude with respect to its expected range
	  //giving a magnitude value of 0.0 to 1.0
	  normalizedMagnitude[i] = magnitude / (32767 - XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
	}
	else //if the controller is in the deadzone zero out the magnitude
	{
		magnitude = 0.0;
		normalizedMagnitude[i] = 0.0;
	}

	//repeat for right thumb stick
	leftTrigger[i] = state.Gamepad.bLeftTrigger;
	rightTrigger[i] = state.Gamepad.bRightTrigger;
	buttons[i] = state.Gamepad.wButtons;
}
