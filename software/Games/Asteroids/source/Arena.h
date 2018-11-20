#pragma once
#include "stdafx.h"
#include <time.h>
#include "GameOver.h"
extern Game game;

namespace Asteroids {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Drawing::Imaging;
	using namespace System::IO;
	using namespace System::Threading;
	using namespace System::Runtime::InteropServices;

	/// <summary>
	/// Summary for Arena
	/// </summary>
	public ref class Arena : public System::Windows::Forms::Form
	{
	public:
		Arena(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			int nn;
			Graphics^ gr;
			std::string graphicsPath = "C:\\Program Files (x86)\\RTFGames\\Asteroids\\graphics\\";
			std::string soundsPath = "C:\\Program Files (x86)\\RTFGames\\Asteroids\\sounds\\";
			std::string str;

			mut = gcnew Mutex(false, "mutAsteroids");
			game.padnum = Gamepad::GetNumbers() != 0;
			game.gamepadConnected = game.padnum != 0;
			if (game.padnum & 1)
				game.padnum = 0;
			else if (game.padnum & 2)
				game.padnum = 1;
			else if (game.padnum & 4)
				game.padnum = 2;
			else if (game.padnum & 8)
				game.padnum = 3;
			gameOver = false;
			bonusActive = false;
			asteroidCount = 10;
			this->SetStyle(ControlStyles::AllPaintingInWmPaint
				| ControlStyles::Opaque, true);
			drawFont = gcnew System::Drawing::Font( "Arial",16*game.size );
			blackBrush = gcnew SolidBrush(Color::Black);
			whiteBrush = gcnew SolidBrush(Color::White);
			blueBrush = gcnew SolidBrush(Color::Blue);
			darkBlueBrush = gcnew SolidBrush(Color::DarkBlue);
			str = graphicsPath; str += "asteroid.png";
			asteroidBmp = gcnew Bitmap(gcnew String(str.c_str()));
			asteroidBmp->MakeTransparent(asteroidBmp->GetPixel(1,1));
			str = graphicsPath; str += "craft.png";
			craftBmp = gcnew Bitmap(gcnew String(str.c_str()));
			craftBmp->MakeTransparent(craftBmp->GetPixel(1,1));
			str = graphicsPath; str += "missile.png";
			missileBmp = gcnew Bitmap(gcnew String(str.c_str()));
			missileBmp->MakeTransparent(missileBmp->GetPixel(1,1));
			str = graphicsPath; str += "spaceship.png";
			bonusBmp = gcnew Bitmap(gcnew String(str.c_str()));
			bonusBmp->MakeTransparent(craftBmp->GetPixel(1,1));
			str = graphicsPath; str += "explosion.png";
			explosionBmp = gcnew Bitmap(gcnew String(str.c_str()));
			explosionBmp->MakeTransparent(explosionBmp->GetPixel(1,1));
			str = graphicsPath; str += "shield.png";
			shieldBmp = gcnew Bitmap(gcnew String(str.c_str()));
			shieldBmp->MakeTransparent(shieldBmp->GetPixel(1,1));
			explosionSound = gcnew array<System::Media::SoundPlayer^>(8);
			str = soundsPath; str += "FX264.wav";
			alienAlertSound = gcnew System::Media::SoundPlayer(gcnew String(str.c_str()));
//			explosionThread = gcnew array<Thread^>(8);
//			myThreadDelegate = gcnew array<ThreadStart^>(8);
			str = soundsPath; str += "explosion.wav";
			for (nn = 0; nn < 8; nn++) {
				explosionSound[nn] = gcnew System::Media::SoundPlayer(gcnew String(str.c_str()));
			}
//			explosionThread = gcnew Thread(&playExplosion);
//			explosionThread->IsBackground = true;
			str = graphicsPath; str += "craftx.png";
			craftxBmp = gcnew Bitmap(gcnew String(str.c_str()));
			craftxBmp->MakeTransparent(craftxBmp->GetPixel(2,2));
			asteroidRotBmp = gcnew array<Bitmap^>(192);
			craftRotBmp = gcnew array<Bitmap^>(128);
			missileRotBmp = gcnew array<Bitmap^>(64);
			craftxRotBmp = gcnew array<Bitmap^>(64);
			shieldRotBmp = gcnew array<Bitmap^>(64);
			for (nn = 0; nn < 64; nn++) {
				asteroidRotBmp[nn] = gcnew Bitmap(32*game.size,32 *game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(asteroidRotBmp[nn]);
				gr->TranslateTransform(32*game.size/2,32*game.size/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-32*game.size/2,-32*game.size/2);
				gr->DrawImage(asteroidBmp,
					System::Drawing::Rectangle(0,0,32*game.size,32*game.size),
					System::Drawing::Rectangle(0,0,433,444),GraphicsUnit::Pixel);
				asteroidRotBmp[nn+64] = gcnew Bitmap(64*game.size,64 *game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(asteroidRotBmp[nn+64]);
				gr->TranslateTransform(64*game.size/2,64*game.size/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-64*game.size/2,-64*game.size/2);
				gr->DrawImage(asteroidBmp,
					System::Drawing::Rectangle(0,0,64*game.size,64*game.size),
					System::Drawing::Rectangle(0,0,433,444),GraphicsUnit::Pixel);
				asteroidRotBmp[nn+128] = gcnew Bitmap(128*game.size,128 *game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(asteroidRotBmp[nn+128]);
				gr->TranslateTransform(128*game.size/2,128*game.size/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-128*game.size/2,-128*game.size/2);
				gr->DrawImage(asteroidBmp,
					System::Drawing::Rectangle(0,0,128*game.size,128*game.size),
					System::Drawing::Rectangle(0,0,433,444),GraphicsUnit::Pixel);
				craftRotBmp[nn] = gcnew Bitmap(48*game.size,48*game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(craftRotBmp[nn]);
				gr->TranslateTransform(48*game.size/2,48*game.size/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-48*game.size/2,-48*game.size/2);
//				gr->DrawImage(craftBmp,0,0);
				gr->DrawImage(craftBmp,
					System::Drawing::Rectangle(0,0,48*game.size,48*game.size),
					System::Drawing::Rectangle(0,0,308,308),GraphicsUnit::Pixel);
				craftRotBmp[nn+64] = gcnew Bitmap(24*game.size,24*game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(craftRotBmp[nn+64]);
				gr->TranslateTransform(24*game.size/2,24*game.size/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-24*game.size/2,-24*game.size/2);
//				gr->DrawImage(craftBmp,0,0);
				gr->DrawImage(craftBmp,
					System::Drawing::Rectangle(0,0,24*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,308,308),GraphicsUnit::Pixel);
				missileRotBmp[nn] = gcnew Bitmap(445,567,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(missileRotBmp[nn]);
				gr->TranslateTransform(445/2,567/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-445/2,-567/2);
				gr->DrawImage(missileBmp,0,0);
				craftxRotBmp[nn] = gcnew Bitmap(48*game.size,48*game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(craftxRotBmp[nn]);
				gr->TranslateTransform(48*game.size/2,48*game.size/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-48*game.size/2,-48*game.size/2);
				gr->DrawImage(craftxBmp,
					System::Drawing::Rectangle(0,0,48*game.size,48*game.size),
					System::Drawing::Rectangle(0,0,308,308),GraphicsUnit::Pixel);
				explosion2Bmp = gcnew Bitmap(1664*game.size,128*game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(explosion2Bmp);
				gr->DrawImage(explosionBmp,
					System::Drawing::Rectangle(0,0,1664*game.size,128*game.size),
					System::Drawing::Rectangle(0,0,2548,190),GraphicsUnit::Pixel);
				shieldRotBmp[nn] = gcnew Bitmap(52*game.size,52*game.size,PixelFormat::Format32bppArgb);
				gr = Graphics::FromImage(shieldRotBmp[nn]);
				gr->TranslateTransform(52*game.size/2,52*game.size/2);
				gr->RotateTransform(nn * 6);
				gr->TranslateTransform(-52*game.size/2,-52*game.size/2);
//				gr->DrawImage(craftBmp,0,0);
				gr->DrawImage(shieldBmp,
					System::Drawing::Rectangle(0,0,52*game.size,52*game.size),
					System::Drawing::Rectangle(0,0,556,556),GraphicsUnit::Pixel);
			}
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~Arena()
		{
			if (components)
			{
				delete components;
			}
		}

	private:
		int asteroidCount;
		bool gameOver;
		bool bonusActive;
		GameOver^ gameOverForm;
		System::Drawing::SolidBrush^ blackBrush;
		System::Drawing::SolidBrush^ whiteBrush;
		System::Drawing::SolidBrush^ blueBrush;
		System::Drawing::SolidBrush^ darkBlueBrush;
		System::Drawing::Bitmap^ asteroidBmp;
		System::Drawing::Bitmap^ craftBmp;
		System::Drawing::Bitmap^ missileBmp;
		System::Drawing::Bitmap^ bonusBmp;
		System::Drawing::Font^ drawFont;
		System::Drawing::Bitmap^ explosionBmp;
		System::Drawing::Bitmap^ explosion2Bmp;
		System::Drawing::Bitmap^ craftxBmp;
		System::Drawing::Bitmap^ shieldBmp;
		Mutex^ mut;
        int exhaustTicks;
	private: array<System::Drawing::Bitmap^>^ asteroidRotBmp;
	private: array<System::Drawing::Bitmap^>^ craftRotBmp;
	private: array<System::Drawing::Bitmap^>^ missileRotBmp;
	private: array<System::Drawing::Bitmap^>^ craftxRotBmp;
	private: array<System::Drawing::Bitmap^>^ shieldRotBmp;
	private: System::Windows::Forms::Timer^  timer1;
	private: System::ComponentModel::IContainer^  components;
	private: array<System::Media::SoundPlayer^>^ explosionSound;
	private: array<Thread^>^ explosionThread;
	private: array<ThreadStart^>^ myThreadDelegate;
	private: System::Media::SoundPlayer^ alienAlertSound;

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
			this->components = (gcnew System::ComponentModel::Container());
			this->timer1 = (gcnew System::Windows::Forms::Timer(this->components));
			this->SuspendLayout();
			// 
			// timer1
			// 
			this->timer1->Tick += gcnew System::EventHandler(this, &Arena::timer1_Tick);
			// 
			// Arena
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(710, 490);
			this->DoubleBuffered = true;
			this->Name = L"Arena";
			this->Text = L"Arena";
			this->WindowState = System::Windows::Forms::FormWindowState::Maximized;
			this->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &Arena::Arena_Paint);
			this->KeyDown += gcnew System::Windows::Forms::KeyEventHandler(this, &Arena::Arena_KeyDown);
			this->KeyPress += gcnew System::Windows::Forms::KeyPressEventHandler(this, &Arena::Arena_KeyPress);
			this->ResumeLayout(false);

		}
#pragma endregion
	private: System::Void Arena_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
				 Graphics^ gr = e->Graphics;
				 LARGE_INTEGER perf_count;
				 static LARGE_INTEGER operf_count = { 0 };
				 static int tick = 0;
				 int x;
				 int y;
				 int nn;
				 int sz;
				 double rot;
				 int dist;
				 int mno;
				 int oc;
				 char textbuf[100];
				 bool asteroidPresent;
				 bool superBomb;
				 int opoints;
				 static DWORD opn = 0;
				 static int fireCount = 0;
				 static int sbounceDelay = 0;
				 static int hbounceDelay = 0;

				 do {
   					QueryPerformanceCounter(&perf_count);
				 }	while (perf_count.QuadPart - operf_count.QuadPart < (game.level < 10 ? 45000LL : 35000LL));
				operf_count = perf_count;

					if (game.gamepadConnected) {
						game.gamepad.GetState(game.padnum);
						if (game.gamepad.states[game.padnum].dwPacketNumber != opn) {
							game.gamepad.CalcStates(game.padnum);
							if (game.gamepad.normalizedLX[game.padnum] < -0.9 || game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_DPAD_LEFT)
								game.craft->rotrate -= .010;
							else if (game.gamepad.normalizedLX[game.padnum] > 0.9 || game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_DPAD_RIGHT)
								game.craft->rotrate += .010;
							if (game.gamepad.rightTrigger[game.padnum] > 10 || game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_A) {
								if (fireCount > 0) {
									fireCount++;
									if (fireCount > 4)
										fireCount = 0;
								}
								if (fireCount == 0) {
									fireCount++;
									FireMissile();
									game.gamepad.rightTrigger[game.padnum] = 0;
								}
							}
//							if (game.gamepad.normalizedLY[game.padnum] > 0.9)
//								IncreaseSpeed();
							if (game.gamepad.leftTrigger[game.padnum] > 4 || game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_DPAD_UP) {
								mut->WaitOne();
								exhaustTicks = 20;
								game.craft->IncreaseSpeed((float)0.1);
								mut->ReleaseMutex();
								game.gamepad.leftTrigger[game.padnum] = 0;
							}
							if (game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_Y) {
								if (hbounceDelay > 20) {
									hbounceDelay = 0;
									game.craft->Hyperspace();
								}
								else
									hbounceDelay++;
							}
							if (game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_X) {
								if (sbounceDelay > 20) {
									sbounceDelay = 0;
									if (!game.craft->shieldOn && game.craft->shieldEnergy > 0)
										game.craft->shieldOn = !game.craft->shieldOn;
									else
										game.craft->shieldOn = false;
								}
								else
									sbounceDelay++;
							}
						}
					}

					// Clear background
					gr->FillRectangle(blackBrush, 0,0,ClientSize.Width, ClientSize.Height);

					if (game.craft->shieldOn==false && game.craft->shieldEnergy < 1000)
						game.craft->shieldEnergy++;
					gr->FillRectangle(blueBrush,0,ClientSize.Height-16,game.craft->shieldEnergy / 10,16);
					gr->FillRectangle(darkBlueBrush,game.craft->shieldEnergy / 10,ClientSize.Height-16,
						100-game.craft->shieldEnergy / 10,16);

					tick++;
					if (tick > 1000) {
 						tick = 0;
						bonusActive = true;
						game.bonusShip->rotrate = 0;
						game.bonusShip->rot = 0;
						game.bonusShip->x = (float)ClientSize.Width + 32.0*game.size;
						game.bonusShip->y = (float)30.0*game.size;
						game.bonusShip->dx = (float)-5.0;
						game.bonusShip->dy = (float)0.0;
						alienAlertSound->Play();
					}
					if (bonusActive) {
						gr->DrawImage(bonusBmp,System::Drawing::Rectangle(
							(int)game.bonusShip->x,30,
//							200,30,
							32*game.size,32*game.size),
							System::Drawing::Rectangle(0,0,524,524),GraphicsUnit::Pixel);
						if (game.bonusShip->x < (float)-32.0) {
							bonusActive = false;
						}
						else {
							game.bonusShip->Move(ClientSize.Width*2, ClientSize.Height);
						}
					}

					// Report the score and level
					sprintf(textbuf, "%04d  %02d", game.points, game.level);
					PointF drawPoint = PointF(250,10);
					gr->DrawString(gcnew System::String(textbuf),drawFont,whiteBrush,drawPoint);

					// Draw life status
					for (nn = 0; nn < game.lives; nn++)
						gr->DrawImage(craftRotBmp[45+64],
							ClientSize.Width-24 * (game.lives + nn),ClientSize.Height-24);

					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					// Handle the asteroid motion / drawing
					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					asteroidPresent = false;
					for (nn = 0; nn < asteroidCount; nn++) {
						if (game.asteroids[nn].destroyed)
							continue;
						asteroidPresent = true;

						// Move the asteroids
						game.asteroids[nn].Move(ClientSize.Width, ClientSize.Height);
						x = (int)game.asteroids[nn].x;
						y = (int)game.asteroids[nn].y;
						sz = game.asteroids[nn].size;
						// Rotate asteroids
						game.asteroids[nn].Rotate();
 						gr->DrawImage(asteroidRotBmp[(int)game.asteroids[nn].rot+64 * game.asteroids[nn].szcd],x,y);
					}


					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					// Spacecraft Motion / Drawing
					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					mut->WaitOne();
					// At start of screen, create a "safe" place for the spacecraft
					if (game.screenStart) {
						game.craft->Hyperspace();
						for (nn = 0; nn < asteroidCount; nn++) {
							if (Asteroid::Collision(game.craft,&game.asteroids[nn])) {
								game.asteroids[nn].destroyed = true;
							}
						}
						game.screenStart = false;
					}

					game.craft->Move(ClientSize.Width, ClientSize.Height);
					game.craft->Rotate();
					if (exhaustTicks > 0) {
						exhaustTicks--;
						gr->DrawImage(craftxRotBmp[(int)game.craft->rot],(int)game.craft->x,(int)game.craft->y);
					}
					else {
						gr->DrawImage(craftRotBmp[(int)game.craft->rot],(int)game.craft->x,(int)game.craft->y);
					}
					if (game.craft->shieldOn) {
						gr->DrawImage(shieldRotBmp[(int)game.craft->rot],(int)game.craft->x-4*game.size,(int)game.craft->y-4*game.size);
						game.craft->shieldEnergy--;
						if (game.craft->shieldEnergy <= 0)
							game.craft->shieldOn = false;
					}

					// Kill the spacecraft rotation rate and speed over time
					// Makes it a little easier to control.
					if (game.craft->rotrate > 0)
						game.craft->rotrate -= 0.002;
					if (game.craft->rotrate < 0)
						game.craft->rotrate += 0.002;
					game.craft->IncreaseSpeed(-0.0050);
					mut->ReleaseMutex();

					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					// Handle Missiles
					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					oc = asteroidCount;
					for (mno = 0; mno < NUM_MISSILES; mno++) {
						// If the missile isn't ready it must be in flight
						if (!game.missiles[mno].ready) {
							if (bonusActive && MovingObject::Collision((MovingObject *)&game.missiles[mno],
								(MovingObject *)game.bonusShip)) {
								bonusActive = false;
								game.bonusShip->x = -128*game.size;
								game.points += 5000;
								game.explosions[mno].x = game.missiles[mno].x;
								game.explosions[mno].y = game.missiles[mno].y;
								game.explosions[mno].t = 52;
								explosionSound[0]->Play();
							}
							for (nn = 0; nn < oc; nn++) {
								if (game.asteroids[nn].destroyed)
									continue;
								if (MovingObject::Collision((MovingObject *)&game.missiles[mno],
									(MovingObject *)&game.asteroids[nn]))	{
									game.explosions[mno].x = game.missiles[mno].x;
									game.explosions[mno].y = game.missiles[mno].y;
									game.explosions[mno].t = 52;
									explosionSound[0]->Play();
									opoints = game.points;
									switch(game.asteroids[nn].szcd) {
									case 0:	game.points += 1000; break;
									case 1: game.points += 100; break;
									default: game.points += 10; break;
									}
									// Add an extra life at 10,000 points
									if (opoints < 10000 && game.points >= 10000)
										game.lives++;
									if (opoints < 100000 && game.points >= 100000)
										game.lives++;
									game.asteroids[nn].destroyed = true;
									sz = game.asteroids[nn].size;
									// Create three more new smaller asteroids when an asteroid
									// is destroyed.
									if (game.asteroids[nn].szcd > 0) {
										switch(game.asteroids[nn].szcd-1) {
										case 0: sz = 16; break;
										case 1: sz = 32; break;
										}
										game.asteroids[asteroidCount].Init(game.asteroids[nn].x,game.asteroids[nn].y,sz);
										game.asteroids[asteroidCount+1].Init(game.asteroids[nn].x,game.asteroids[nn].y,sz);
										game.asteroids[asteroidCount+2].Init(game.asteroids[nn].x,game.asteroids[nn].y,sz);
										asteroidCount+=3;
									}
									game.missiles[mno].dist = 0;
									game.missiles[mno].ready = true;
									continue;
								}
							}
							game.missiles[mno].t++;
							game.missiles[mno].Move(ClientSize.Width, ClientSize.Height);
							rot = game.missiles[mno].rot;
							rot = RotBound(rot);
							x = (int)game.missiles[mno].x;
							y = (int)game.missiles[mno].y;
							gr->DrawImage(missileRotBmp[(int)rot],
								System::Drawing::Rectangle(x,y,24*game.size,24*game.size),
								System::Drawing::Rectangle(0,0,445,567),GraphicsUnit::Pixel);
							game.missiles[mno].dist += game.missiles[mno].speed;
							if (game.missiles[mno].dist > 600) {
								game.missiles[mno].dist = 0;
								game.missiles[mno].ready = true;
							}
						}
					}

					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					// If the screen was cleared, increment the game level
					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					if (!asteroidPresent) {
						game.screenStart = true;
						game.level++;
						if (game.level < 10) {
							asteroidCount = 5 + game.level * 5;
						}
						else {
							asteroidCount = 50;
						}
						for (nn = 0; nn < asteroidCount; nn++) {
							game.craft->shieldOn = true;
							game.craft->shieldEnergy = 1000;
							game.asteroids[nn].Init();
						}
					}

					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					// Check if ship crashed into asteroid
					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					for (nn = 0; nn < asteroidCount && !game.screenStart; nn++) {
						if (game.asteroids[nn].destroyed)
							continue;
						if (MovingObject::Collision((MovingObject *)game.craft,(MovingObject *)&game.asteroids[nn]) && game.craft->shieldOn)	{
							game.craft->shieldEnergy -= 10;
							game.asteroids[nn].dx = -game.asteroids[nn].dx;
							game.asteroids[nn].dy = -game.asteroids[nn].dy;
							if (game.craft->shieldEnergy <= 0) {
								game.craft->shieldOn = false;
							}
						}
						else if (MovingObject::Collision((MovingObject *)game.craft,(MovingObject *)&game.asteroids[nn]))	{
							game.lives--;
							if (game.lives<=0) {
								gameOver = true;
								sprintf(textbuf, "Score: %d", game.points);
								gameOverForm = gcnew GameOver();
								gameOverForm->lblScore->Text = gcnew String(textbuf);
								gameOverForm->ShowDialog();
								this->Close();
								break;
							}
							game.explosions[NUM_MISSILES].t = 52;
							game.explosions[NUM_MISSILES].x = game.craft->x;
							game.explosions[NUM_MISSILES].y = game.craft->y;
			                game.craft->Hyperspace();
							game.craft->shieldOn = true;
							game.craft->shieldEnergy = 1000;
						}
					}

					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					// Draw any explosions
					// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
					for (mno = 0; mno < NUM_MISSILES+1; mno++) {
						if (game.explosions[mno].t > 0)
						{
							game.explosions[mno].t--;
							gr->DrawImage(explosion2Bmp,(int)game.explosions[mno].x,(int)game.explosions[mno].y,
								System::Drawing::Rectangle(128*((51-game.explosions[mno].t)>>2)*game.size,0,128*game.size,128*game.size),GraphicsUnit::Pixel);
//							gr->DrawImage(explosionBmp,System::Drawing::Rectangle(
//								game.explosions[mno].x, game.explosions[mno].y,128*game.size,128*game.size),
//								System::Drawing::Rectangle(196*((51-game.explosions[mno].t)>>2),0,196,190),GraphicsUnit::Pixel);
						}
					}
				 this->Invalidate();
			 }
	private: System::Void timer1_Tick(System::Object^  sender, System::EventArgs^  e) {
				 this->Invalidate();
			 }
	private: System::Void Arena_KeyDown(System::Object^  sender, System::Windows::Forms::KeyEventArgs^  e) {

			 }

private: double RotBound(double rot) {
	if (rot >= 60) rot -= 60;
	if (rot < 0) rot += 60;
	if (rot < 0 || rot > 60)
		rot = 0;
	return rot;
}

private: System::Void Arena_KeyPress(System::Object^  sender, System::Windows::Forms::KeyPressEventArgs^  e) {
			 static int mno = 0;
			 Keys key = (Keys)e->KeyChar;
			 switch(key) {
			 case '4':
				 mut->WaitOne();
				 game.craft->rotrate -= .1;
				 if (game.craft->rot < 0)
					 game.craft->rot = 60;
				 mut->ReleaseMutex();
				 e->Handled = true;
				 break;
			 case '6':
				 mut->WaitOne();
				 game.craft->rotrate += .1;
				 if (game.craft->rot > 60)
					 game.craft->rot = 0;
				 mut->ReleaseMutex();
				 e->Handled = true;
				 break;
			 case '8':
			     mut->WaitOne();
				 game.craft->IncreaseSpeed((double)0.1);
				 mut->ReleaseMutex();
				 e->Handled = true;
				 break;
			 case '2':
				 mut->WaitOne();
				 game.craft->speed-=0.1;
				 game.craft->dx = sin(6 * RotBound(game.craft->rot+15) * PI / 180.0) * game.craft->speed;
				 game.craft->dy = -cos(6 * RotBound(game.craft->rot+15) * PI / 180.0) * game.craft->speed;
				 exhaustTicks = 20;
				 mut->ReleaseMutex();
				 e->Handled = true;
				 break;
			 case 'h':
			 case 'H':
				 game.craft->Hyperspace();
				 e->Handled = true;
				 break;
			 case ' ':
				 FireMissile();
				 e->Handled = true;
				 break;
			 case 's':
			 case 'S':
				if (!game.craft->shieldOn && game.craft->shieldEnergy > 0)
					game.craft->shieldOn = !game.craft->shieldOn;
				else
					game.craft->shieldOn = false;
				break;
			 }
		 }

void FireMissile()
{
	int mno;

	for (mno = 0; mno < NUM_MISSILES; mno++) {
		if (game.missiles[mno].ready) {
			game.missiles[mno].ready = false;
			game.missiles[mno].speed = 5 + (abs(game.craft->speed) + 0.01);
			game.missiles[mno].dx = 5 * sin(6 * RotBound(game.craft->rot+15) * PI / 180.0);
			game.missiles[mno].dy = -5 * cos(6 * RotBound(game.craft->rot+15) * PI / 180.0);
			game.missiles[mno].x = game.craft->x;
			game.missiles[mno].y = game.craft->y;
			game.missiles[mno].rot = RotBound(game.craft->rot+15);
			game.missiles[mno].dist = 0;
			game.missiles[mno].t = 0;
			break;
		}
	}
}
};
}

