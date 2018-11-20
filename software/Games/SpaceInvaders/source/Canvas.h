#pragma once
#include "stdafx.h"
#include "GameOver.h"
extern Game game;

namespace SpaceInvaders {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// Summary for Canvas
	/// </summary>
	public ref class Canvas : public System::Windows::Forms::Form
	{
	public:
		Canvas(void)
		{
			InitializeComponent();
			//
			//TODO: Add the constructor code here
			//
			String^ graphicsPath, ^str;
			Graphics^ gr;
			String^ path;

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
			game.Reset();

			drawFont = gcnew System::Drawing::Font( "Arial",16*game.size );
			blackBrush = gcnew SolidBrush(Color::Black);
			whiteBrush = gcnew SolidBrush(Color::White);
			brownBrush = gcnew SolidBrush(Color::Brown);
			darkBlueBrush = gcnew SolidBrush(Color::DarkBlue);

			graphicsPath = System::Reflection::Assembly::GetExecutingAssembly()->CodeBase;
			graphicsPath = graphicsPath->Replace("\\bin\\SpaceInvaders.exe", "\\graphics\\");
			graphicsPath = graphicsPath->Replace("\\Debug\\SpaceInvaders.exe", "\\graphics\\");
			graphicsPath = graphicsPath->Replace("/bin/SpaceInvaders.exe", "/graphics/");
			graphicsPath = graphicsPath->Replace("/Debug/SpaceInvaders.exe", "/graphics/");
			graphicsPath = graphicsPath->Replace("file:///", "");
			graphicsPath = graphicsPath->Replace("/", "\\");

//			graphicsPath = "C:\\Program Files (x86)\\RTFGames\\SpaceInvaders\\graphics\\";
			str = graphicsPath; str += "alien1v.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			alien1vBmp = gcnew Bitmap(40,24);
			gr = Graphics::FromImage(alien1vBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,40*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);
			str = graphicsPath; str += "alien1x.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			alien1xBmp = gcnew Bitmap(40,24);
			gr = Graphics::FromImage(alien1xBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,40*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			str = graphicsPath; str += "alien2u.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			alien2uBmp = gcnew Bitmap(40,24);
			gr = Graphics::FromImage(alien2uBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,40*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);
			str = graphicsPath; str += "alien2d.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			alien2dBmp = gcnew Bitmap(40,24);
			gr = Graphics::FromImage(alien2dBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,40*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			str = graphicsPath; str += "alien3i.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			alien3iBmp = gcnew Bitmap(40,24);
			gr = Graphics::FromImage(alien3iBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,40*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);
			str = graphicsPath; str += "alien3o.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			alien3oBmp = gcnew Bitmap(40,24);
			gr = Graphics::FromImage(alien3oBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,40*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			str = graphicsPath; str += "bonusAlien.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			bonusBmp = gcnew Bitmap(76,24);
			gr = Graphics::FromImage(bonusBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,76*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			str = graphicsPath; str += "tank.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			tankBmp = gcnew Bitmap(40,24);
			gr = Graphics::FromImage(tankBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,40*game.size,24*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			str = graphicsPath; str += "missile.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			missileBmp = gcnew Bitmap(8*game.size,32*game.size);
			gr = Graphics::FromImage(missileBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,8*game.size,32*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			str = graphicsPath; str += "bomb.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			bombBmp = gcnew Bitmap(12*game.size,32*game.size);
			gr = Graphics::FromImage(bombBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,12*game.size,32*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			str = graphicsPath; str += "explosion.png";
			bmp = gcnew Bitmap(str);
			bmp->MakeTransparent(bmp->GetPixel(1,1));
			explosionBmp = gcnew Bitmap(624*game.size,48*game.size);
			gr = Graphics::FromImage(explosionBmp);
			gr->DrawImage(bmp,
					System::Drawing::Rectangle(0,0,624*game.size,48*game.size),
					System::Drawing::Rectangle(0,0,bmp->Width,bmp->Height),GraphicsUnit::Pixel);

			this->SetStyle(ControlStyles::AllPaintingInWmPaint
				| ControlStyles::Opaque, true);
			game.tank.x = ClientSize.Width / 2;
			BarrierInit();
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~Canvas()
		{
			if (components)
			{
				delete components;
			}
		}

	private:
		System::Drawing::Bitmap^ bmp;
		System::Drawing::Bitmap^ alien1vBmp;
		System::Drawing::Bitmap^ alien1xBmp;
		System::Drawing::Bitmap^ alien2uBmp;
		System::Drawing::Bitmap^ alien2dBmp;
		System::Drawing::Bitmap^ alien3iBmp;
		System::Drawing::Bitmap^ alien3oBmp;
		System::Drawing::Bitmap^ tankBmp;
		System::Drawing::Bitmap^ missileBmp;
		System::Drawing::Bitmap^ bombBmp;
		System::Drawing::Bitmap^ explosionBmp;
		System::Drawing::Bitmap^ bonusBmp;
		System::Drawing::Font^ drawFont;
		System::Drawing::SolidBrush^ whiteBrush;
		System::Drawing::SolidBrush^ blackBrush;
		System::Drawing::SolidBrush^ brownBrush;
		System::Drawing::SolidBrush^ darkBlueBrush;

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
			this->SuspendLayout();
			// 
			// Canvas
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(858, 526);
			this->DoubleBuffered = true;
			this->Name = L"Canvas";
			this->Text = L"Canvas";
			this->Paint += gcnew System::Windows::Forms::PaintEventHandler(this, &Canvas::Canvas_Paint);
			this->ResumeLayout(false);

		}
#pragma endregion
	private: System::Void Canvas_Paint(System::Object^  sender, System::Windows::Forms::PaintEventArgs^  e) {
				 Graphics^ gr = e->Graphics;
				 LARGE_INTEGER perf_count;
				 static LARGE_INTEGER operf_count = { 0 };
				 int row, col, mno, nn;
				 char textbuf[100];
				 static int dx = 1, dy = 0, odx = 1;
				 static int fireCount = 0;
				 static DWORD opn;
				 static int mvtick = 0;
				 bool allDestroyed = false;
				 static bool bonusActive = false;
				static int oscore = 0;
				static int tick = 1;

				 do {
   					QueryPerformanceCounter(&perf_count);
				 }	while (perf_count.QuadPart - operf_count.QuadPart < (game.level < 21 ? 21000LL - game.level * 1000: 0LL));
				 operf_count = perf_count;
				 tick++;
				 if (tick==5000) {
					 tick = 1;
					 bonusActive = true;
					 game.bonusShip.x = ClientSize.Width + 80;
					 game.bonusShip.y = 30;
				 }

				game.tank.y = ClientSize.Height - 48;
				if (game.gamepadConnected) {
					game.gamepad.GetState(game.padnum);
					if (game.gamepad.states[game.padnum].dwPacketNumber != opn) {
						game.gamepad.CalcStates(game.padnum);
						if (game.gamepad.normalizedLX[game.padnum] < -0.9 || game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_DPAD_LEFT) {
							if (game.tank.x > 0)
								game.tank.x -= 1.0;
						}
						else if (game.gamepad.normalizedLX[game.padnum] > 0.9 || game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_DPAD_RIGHT) {
							if (game.tank.x < ClientSize.Width - 48*game.size)
								game.tank.x += 1.0;
						}
						if (game.gamepad.rightTrigger[game.padnum] > 10 || game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_A) {
							if (fireCount > 0) {
								fireCount++;
								if (fireCount > 25)
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
/*
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
*/
						if (game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_X && game.lives <= 0) {
							this->Close();
						}
/*
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
						if (game.gamepad.buttons[game.padnum] & XINPUT_GAMEPAD_B) {
							if (game.craft->shieldEnergy > 500) {
								eb = false;
								energyBurst = 500;
								game.craft->shieldEnergy = 0;
								game.craft->shieldOn = false;
							}
						}
*/
					}
				}

				// Clear background
				gr->FillRectangle(darkBlueBrush, 0,0,ClientSize.Width, ClientSize.Height);

				// Report the score and level
				sprintf(textbuf, "%04d  %02d", game.score, game.level);
				PointF drawPoint = PointF(250,10);
				gr->DrawString(gcnew System::String(textbuf),drawFont,whiteBrush,drawPoint);

				if (game.lives > 0) {
				// Draw life status
				for (nn = 0; nn < game.lives; nn++)
					gr->DrawImage(tankBmp,
						ClientSize.Width-24 * (game.lives + nn),ClientSize.Height-24);

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				if (bonusActive) {
					game.bonusShip.x-=1.0;
					if (game.bonusShip.x < -80) {
						bonusActive = false;
					}
					gr->DrawImage(bonusBmp,
						(int)game.bonusShip.x,game.bonusShip.y);
				}

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Check for missile hits and drop bombs.
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				 allDestroyed = true;
				 for (row = 0; row < 5; row++) {
					 for (col = 0; col < 10; col++) {
						 if (!game.invaders[row][col].destroyed) {
							for (mno = NUM_MISSILES; mno < NUM_MISSILES+4; mno++) {
								if (game.missiles[mno].ready) {
									if (RTFClasses::Random::rand(100) < 12) {
										game.missiles[mno].ready = false;
										game.missiles[mno].x = game.invaders[row][col].x+10;
										game.missiles[mno].y = game.invaders[row][col].y+16;
										break;
									}
								}
							}
							game.invaders[row][col].x = col * 48 + game.x;
							game.invaders[row][col].y = row * 32 + game.y;
							for (mno = 0; mno < NUM_MISSILES; mno++) {
								if (game.missiles[mno].ready == false) {
									if (game.invaders[row][col].Hit(&game.missiles[mno])) {
										game.invaders[row][col].destroyed = true;
										game.missiles[mno].ready = true;
										game.AdjustPhalanx();
										game.explosions[mno].x = game.missiles[mno].x;
										game.explosions[mno].y = game.missiles[mno].y;
										game.explosions[mno].t = 104;
										switch(row) {
										case 0:	game.score += 50; break;
										case 1:	game.score += 25; break;
										case 2:	game.score += 25; break;
										case 3:	game.score += 10; break;
										case 4:	game.score += 10; break;
										}
										// Extra base at 5,000 points
										if (oscore < 5000 && game.score>=5000) {
											game.lives++;
										}
										oscore = game.score;
									}
								}
							}
						 }
						 if (!game.invaders[row][col].destroyed) {
							 allDestroyed = false;
						 }
					 }
				 }
				 if (allDestroyed) {
					 game.ResetScreen();
					 for (nn = 0; nn < NUM_BARRIERS; nn++)
					 game.score += game.barriers[nn].Points();
					 BarrierInit();
				 }
				 if (bonusActive) {
					 for (mno = 0; mno < NUM_MISSILES; mno++) {
						 if (!game.missiles[mno].ready) {
							 if (game.bonusShip.Hit(&game.missiles[mno])) {
								bonusActive = false;
								game.score += 200;
								// Extra base at 5,000 points
								if (oscore < 5000 && game.score>=5000) {
									game.lives++;
								}
								oscore = game.score;
								game.explosions[mno].x = game.missiles[mno].x;
								game.explosions[mno].y = game.missiles[mno].y;
								game.explosions[mno].t = 104;
							 }
						 }
					 }
				 }
				} // game.lives

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Draw aliens
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				 for (row = 0; row < 5; row++) {
					 for (col = 0; col < 10; col++) {
						 if (!game.invaders[row][col].destroyed) {
							switch(game.invaders[row][col].type) {
							case 0:	gr->DrawImage((game.x & 8) ? alien1vBmp : alien1xBmp,col * 48 + game.x, row * 32 + game.y); break;
							case 1:	gr->DrawImage((game.x & 8) ? alien2uBmp : alien2dBmp,col * 48 + game.x, row * 32 + game.y); break;
							case 2:	gr->DrawImage((game.x & 8) ? alien3iBmp : alien3oBmp,col * 48 + game.x, row * 32 + game.y); break;
							}
						 }
					 }
				 }

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Move alien phalanx
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				 if (game.lives > 0) {
					 if (mvtick==1) {
						 mvtick = 0;
						 odx = dx;
						 if (dx > 0 && game.x + dx + (game.rightCol+1)*48*game.size < ClientSize.Width) {
							;
						 }
						 else {
							 dx = -1;
						 }
						 if (dx < 0 && game.x + (game.leftCol * 48 * game.size) > 0)
							 ;
						 else {
							 dx = 1;
						 }
						 if (odx != dx) {
							 odx = dx;
							 if (game.y < ClientSize.Height - ((game.bottomRow+1) * 32 * game.size)-32) {
								game.y += 16;
							 }
							 else {
								 game.lives = 0;
								 sprintf(textbuf, "A L I E N S   L A N D E D !");
								 PointF drawPoint = PointF(ClientSize.Width/2-50,ClientSize.Height/2-32);
								 gr->DrawString(gcnew System::String(textbuf),drawFont,whiteBrush,drawPoint);
							 }
						 }
						 game.x += dx;
					 }
					 else mvtick++;
				 }

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Draw tank
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				gr->DrawImage(tankBmp, (int)game.tank.x, game.tank.y);

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Check for bombed targets
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				for (mno = NUM_MISSILES; mno < NUM_MISSILES+4; mno++) {
					if (!game.missiles[mno].ready) {
						if (game.tank.Hit(&game.missiles[mno])) {
							game.lives--;
							game.missiles[mno].ready = true;
							game.explosions[mno].x = game.missiles[mno].x;
							game.explosions[mno].y = game.missiles[mno].y;
							game.explosions[mno].t = 104;
//							if (game.lives==0)
//								this->Close();
						}
						for (nn = 0; nn < NUM_BARRIERS; nn++) {
							if (game.barriers[nn].Hit(&game.missiles[mno])) {
								game.missiles[mno].ready = true;
								game.explosions[mno].x = game.missiles[mno].x;
								game.explosions[mno].y = game.missiles[mno].y;
								game.explosions[mno].t = 104;
							}
						}
					}
				}

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Draw Missile
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				for (mno = 0; mno < NUM_MISSILES; mno++) {
					 if (!game.missiles[mno].ready && game.missiles[mno].y > 0) {
						 game.missiles[mno].y--;
		  				 gr->DrawImage(missileBmp, game.missiles[mno].x, game.missiles[mno].y);
					 }
					 if (!game.missiles[mno].ready && game.missiles[mno].y <= 0) {
						 game.missiles[mno].ready = true;
					 }
				}

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Draw barriers;
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				DrawBarriers(gr);

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Draw Bombs
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				for (mno = NUM_MISSILES; mno < NUM_MISSILES+4; mno++) {
					 if (!game.missiles[mno].ready && game.missiles[mno].y  < ClientSize.Height) {
						 game.missiles[mno].y++;
		  				 gr->DrawImage(bombBmp, game.missiles[mno].x, game.missiles[mno].y);
					 }
					 if (!game.missiles[mno].ready && game.missiles[mno].y  >= ClientSize.Height) {
						 game.missiles[mno].ready = true;
					 }
				}

				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				// Draw any explosions
				// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				for (mno = 0; mno < NUM_MISSILES+4; mno++) {
					if (game.explosions[mno].t > 0)
					{
						game.explosions[mno].t--;
						gr->DrawImage(explosionBmp,(int)game.explosions[mno].x,(int)game.explosions[mno].y,
							System::Drawing::Rectangle(48*((103-game.explosions[mno].t)>>3)*game.size,0,48*game.size,48*game.size),GraphicsUnit::Pixel);
					}
				}
				if (game.lives > 0)
					;
				else {
					sprintf(textbuf, "G A M E   O V E R");
					PointF drawPoint = PointF(ClientSize.Width/2-50,ClientSize.Height/2);
					gr->DrawString(gcnew System::String(textbuf),drawFont,whiteBrush,drawPoint);
				}
				this->Invalidate();
			 }
void FireMissile()
{
	int mno;

	for (mno = 0; mno < NUM_MISSILES; mno++) {
		if (game.missiles[mno].ready) {
			game.missiles[mno].ready = false;
			game.missiles[mno].x = game.tank.x+16;
			game.missiles[mno].y = game.tank.y-24*game.size;
			game.missiles[mno].dist = 0;
			game.missiles[mno].t = 0;
			break;
		}
	}
}
void BarrierInit()
{
	int nn;
	int xx;

	xx = ClientSize.Width / 5;
	for (nn = 0; nn < NUM_BARRIERS; nn++) {
		game.barriers[nn].Init();
		game.barriers[nn].y = ClientSize.Height - 80 * game.size;
		game.barriers[nn].x = xx / 2 + xx * nn;
	}
}

void DrawBarrier(Graphics^ gr, int nn)
{
	int r, c;
	int rr,cc;

	for (r = 0; r < 6; r++) {
		for (c = 0; c < 8; c++) {
			if (game.barriers[nn].blocks[r][c].destroyed==0) {
				gr->FillRectangle(blackBrush,game.barriers[nn].x+c*8,game.barriers[nn].y+r*8,8,8);
				for (rr = 0; rr < 4; rr++) {
					for (cc = 0; cc < 4; cc++) {
						if ((game.barriers[nn].blocks[r][c].bricks >> (rr * 4 + cc))&1)
							gr->FillRectangle(brownBrush,game.barriers[nn].x+c*8+cc*2,game.barriers[nn].y+r*8+rr*2,2,2);
					}
				}
			}
		}
	}
}

void DrawBarriers(Graphics^ gr)
{
	int nn;

	for (nn = 0; nn < NUM_BARRIERS; nn++)
		DrawBarrier(gr,nn);
}
	};
}
