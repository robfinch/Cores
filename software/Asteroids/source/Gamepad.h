#pragma once

class Gamepad
{
public:
	XINPUT_STATE states[4];
	float normalizedLX[4], normalizedLY[4];
	float normalizedMagnitude[4];
	__int8 leftTrigger[4];
	__int8 rightTrigger[4];
	WORD buttons[4];
	static int GetNumbers();
	void GetState(int n);
	void CalcStates(int n);
};
