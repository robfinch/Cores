#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include "fwstr.h"
#include "err.h"
#include "fstreamS19.h"
#include "Assembler.h"

namespace RTFClasses
{
	// needed to reorder the output bytes for proper display
	// of word values
	static int toggle = 0;
	static char ch_stack[9];

	// Emit a byte to an object file
	void Assembler::emit8Obj(unsigned int byte)
	{
		static int LastArea;	/* set this ? */
		int type;

		// If no object code has been output yet then output manufacturer
		// record and object name.
		if (bFirstObj)
		{
			ObjFilex.uWrite(T_MFCTR, verstr2, strlen(verstr2));
			ObjFilex.uWrite(T_NAME, File[0].name.buf(), File[0].name.len());
			bFirstObj = false;
		}

		// Flush output buffer if output area changed since last time.
		if (LastArea != CurrentArea)
			ObjFilex.flush();

		// If the output buffer had to be flushed then we want to set up a
		// new object record.
		if (ObjFilex.bWrite(T_VDATA, (char *)&byte, 1))
			ObjFilex.clearBuf();

		// If no data has been output to record yet then output the start
		// of a verbatium data record.
		if (ObjFilex.getLength() == 0)
		{
			switch(CurrentArea)
			{
			case DATA_AREA:
				type = A_DATA;
				ObjFilex.bWrite(T_VDATA, (char *)&type, 1);
				ObjFilex.bWrite(T_VDATA, (char *)&DataCounter.val, 4);
				break;
			case BSS_AREA:  // No output for uninitialized data
				break;
			case CODE_AREA:
			default:
				type = A_CODE;
				ObjFilex.bWrite(T_VDATA, (char *)&type, 1);
				ObjFilex.bWrite(T_VDATA, (char *)&ProgramCounter.val, 4);
				break;
			}
			ObjFilex.bWrite(T_VDATA, (char *)&byte, 1);
		}

		LastArea = CurrentArea;
	}

	// Emit a byte to a binary file
	void Assembler::emit8Bin(unsigned int byte)
	{
		// There is no output to the BSS area
		if (CurrentArea != BSS_AREA)
		{
			fputc(byte, fpBin);
			if(ferror(fpBin))
				Err(E_WRITEOUT);
		}
	}

	// output a byte to mem file
	void Assembler::emit8Mem(unsigned int byte)
	{
		static int memcnt = 0;

		if (CurrentArea != BSS_AREA)
		{
			if (memcnt % 8 == 7)
				fprintf(fpMem, "%02X\r\n", byte);
			else
				fprintf(fpMem, "%02X ", byte);
			memcnt++;
//			   if (getCounter().byte == 2) {
//				   fprintf(fpMem, "%02X %02X %02X\r\n",
//					   b[0]&0xff, b[1] & 0xff, b[2] & 0xff);
//			   }
        }
	}

	int Assembler::par32(unsigned int word)
	{
		int n;
		int p;

		for (p = n = 0; n < 32; n++) {
			p = p ^ (word & 1);
			word >>= 1;
		}
		return p;
	}

	// output a byte to mem file
	void Assembler::emit8Verilog(unsigned int byte)
	{
		static int memcnt = 0;
		static unsigned int buf[4];
		unsigned int word;

		if (CurrentArea != BSS_AREA)
		{
			buf[memcnt %4] = byte & 0xff;
			if (memcnt %4 == 3) {
				word = (buf[3] << 24) + (buf[2] << 16) + (buf[1] << 8) + buf[0];
				checksum = checksum + word;
				//printf("word=%08.8x\r\n", word);
				fprintf(fpVer, "rommem[%d] = 33'h%01.1X%08.8X;\r\n", memcnt/4,par32(word)&0x0f,word);
			}
			memcnt++;
        }
	}

	// output a byte to mem file
	void Assembler::emit8VerilogDP(unsigned int byte)
	{
		static int memcnt = 0;
		static unsigned int buf[32];
		unsigned int word;
        int nn;
 
		if (CurrentArea != BSS_AREA)
		{
			buf[memcnt %32] = byte & 0xff;
			if (memcnt % 32 == 31) {
                fprintf(fpVerDP,"urom.rom%d.INIT_%02X=256'h",memcnt/2048,(memcnt/32)%64);
                for (nn = 31; nn >=0; nn--)
                    fprintf(fpVerDP, "%02X", buf[nn]&0xff);
                fprintf(fpVerDP, ",\r\n");
			}
			memcnt++;
        }
	}

	void Assembler::emit8DoingDc(unsigned int byte)
	{
        switch(gSzChar) {

		case 'B':
        case 'C':
        case 'W':
			if (getCpu()->stride==1) {
				fprintf(fpList, "%02.2X ", byte);
				col += 3;
			}
			else {
				sprintf(ch_stack, "%02.2X", byte);
				col += 2;
				toggle = 1;
			}
            break;

		case 'S':
        case 'L':
  			if (getCpu()->stride==1) {
				fprintf(fpList, "%02.2X ", byte);
				col += 3;
			}
			else {
				sprintf(ch_stack, "%02.2X", byte);
				col += 2;
				toggle = 1;
			}
            break;

		default:
			if (getCpu()->stride==1) {
				fprintf(fpList, "%02.2X", byte);
				fputc(' ', fpList);
				col += 3;
			}
			else {
				sprintf(ch_stack, "%02.2X", byte);
				col += 2;
				toggle = 1;
			}
            break;
        }
	}

	void Assembler::emit8FirstListCol(unsigned int byte)
	{
		col = listAddr();
        if (CurrentArea != BSS_AREA) {
			if (DoingDc)
				emit8DoingDc(byte);
            else {
				if (getCpu()->stride==1) {
					fprintf(fpList, "%02.2X", byte);
					fputc(' ', fpList);
					col += 3;
				}
				else {
					sprintf(ch_stack, "%02.2X", byte);
					col += 2;
					toggle = 1;
				}
            }
        }
	}


	void Assembler::flushStack2()
	{
		char ch;

		toggle++;
		col += 2;
		if (toggle == 2)
		{
			// reverse string order, bytes not chars!
			ch = ch_stack[0]; ch_stack[0] = ch_stack[2]; ch_stack[2] = ch;
			ch = ch_stack[1]; ch_stack[1] = ch_stack[3]; ch_stack[3] = ch;
			fputs(ch_stack, fpList);
			fputc(' ', fpList);
			col++;
			toggle = 0;
		}
	}


	void Assembler::flushStack4()
	{
		char ch;

		toggle++;
		col += 2;
        if (toggle == 4) {
            // reverse string order, bytes not chars!
            ch = ch_stack[0]; ch_stack[0] = ch_stack[6]; ch_stack[6] = ch;
            ch = ch_stack[1]; ch_stack[1] = ch_stack[7]; ch_stack[7] = ch;
            ch = ch_stack[2]; ch_stack[2] = ch_stack[4]; ch_stack[4] = ch;
            ch = ch_stack[3]; ch_stack[3] = ch_stack[5]; ch_stack[5] = ch;
			fputs(ch_stack, fpList);
			fputc(' ', fpList);
			col++;
			toggle = 0;
		}
	}


	void Assembler::emit8ListCol(unsigned int byte)
	{
        if (CurrentArea != BSS_AREA) {
            if (DoingDc) {
                switch(gSzChar)
                {
                case 'B':
                case 'C':
                case 'W':
					if (getCpu()->stride==1) {
						fprintf(fpList, "%02.2X", byte);
						fputc(' ', fpList);
						col += 3;
					}
					else {
						sprintf(&ch_stack[toggle << 1], "%02.2X",byte);
						flushStack2();
					}
                    break;
                case 'S':
                case 'L':
 					if (getCpu()->stride==1) {
						fprintf(fpList, "%02.2X", byte);
						fputc(' ', fpList);
						col += 3;
					}
					else {
	               // At first byte of long, check to see if it will fit
                // on the line.
                    if (toggle == 0) {
                        if (col > 19) {
//                                    for (; col < SRC_COL; col++)
//                                        fputc(' ', fpList);
                            OutListLine();
                            //*sol = '\0';   // to prevent duplicates
							ibuf->buf()[sol] = '\0';
							emit8(byte);	// try again
							return;
                        }
                    }
					sprintf(&ch_stack[toggle << 1], "%02.2X",byte);
					flushStack4();
					}
                    break;

                default:
					if (getCpu()->stride==1) {
						fprintf(fpList, "%02.2X", byte);
						fputc(' ', fpList);
						col += 3;
					}
					else {
						sprintf(&ch_stack[toggle << 1], "%02.2X",byte);
						flushStack2();
					}
                }
            } // doingDc
            else
            {
				if (getCpu()->stride==1) {
					fprintf(fpList, "%02.2X", byte);
					fputc(' ', fpList);
					col += 3;
				}
				else {
					sprintf(&ch_stack[toggle << 1], "%02.2X",byte);
					flushStack2();
				}
            }
        }
	}


	/* ---------------------------------------------------------------
			On the first pass just increments the appropriate
		counter. On the second pass sends a byte to output file
		and updates the appropriate counter.
	--------------------------------------------------------------- */

	void Assembler::emit8(unsigned int byte)
	{
		static unsigned int b[4];
		char ch;

		byte &= 0xff;
		b[getCounter().byte] = byte;

		// Output generation pass ?
		if(isGenerationPass())
		{
			// Default start address to first location of code
			// output, if not otherwise defined
			if (CurrentArea == CODE_AREA)
			{
				if (fFirstCode && !fStartDefined)
					StartAddress = ProgramCounter.val;
				fFirstCode = false;
			}

			if (bObjOut)
				emit8Obj(byte);

			// Here we're just outputting binary data
			if (fBinOut)
				emit8Bin(byte);

			if (fSOut) {
				if (CurrentArea != BSS_AREA)
					gSOut.putb(getCounter().val, byte);
			}

			// If a listing is being generated then output data byte
			if(fListing)
			{
	emitb1:
				if(col == 1)
					emit8FirstListCol(byte);
				else
					emit8ListCol(byte);
				if (col > SRC_COL-3) {
	//                for (; col < SRC_COL; col++)
	//                    fputc(' ', fpList);
					OutListLine();
	//                *sol = '\0';   // to prevent duplicates
				}
			}

			if (bMemOut)
				emit8Mem(byte);
			if (bVerOut) {
				emit8Verilog(byte);
				emit8VerilogDP(byte);
            }
		}

		// Increment counter for appropriate area
//		getCounter().ByteInc(getCpu()->stride);
		//if (stricmp(getCpu()->name,"RTF65002")==0) {
		//	if (CurrentArea==BSS_AREA || CurrentArea==DATA_AREA) {
		//		getCounter().ByteInc(4);
		//	}
		//	else
		//		getCounter().inc();
		//}
		//else
			getCounter().inc();
	}


	void Assembler::emit0()
	{
		if(isGenerationPass() && fListing && col == 1)
			col += listAddr();
	}


	// Send a word to output file (four bytes).
	int Assembler::emit32(unsigned int word)
	{
		emit8(word & 0xff);
		emit8((word >> 8) & 0xff);
		emit8((word >> 16) & 0xff);
		emit8((word >> 24) & 0xff);
		return (TRUE);
	}


	// Send a character to output file (two bytes).
	void Assembler::emit16(int word)
	{
		emit8(word & 0xff);
		emit8((word >> 8) & 0xff);
		return;
	}


	// Send a character to output file (two bytes).
	void Assembler::emit24(int word)
	{
		emit8(word & 0xff);
		emit8((word >> 8) & 0xff);
		emit8((word >> 16) & 0xff);
		return;
	}


	// emit the proper size operand variable 

	void Assembler::emit(int size, unsigned __int64 data)
	{
		switch(toupper(size))
		{
		case 'B':
			data &= 0xff;
			emit8((int) data);
			break;
		case 'D':
			emit32((unsigned int) (data & 0xffffffff));
			emit32((unsigned int) ((data >> 32) & 0xffffffff));
			break;
		case 0:
		case 'S':
		case 'L': 
			emit32((unsigned int) (data & 0xffffffff));
			break;
		case 'W':
			if (gProcessor.equalsNoCase("RTF65002")||gProcessor.equalsNoCase("RTF65003"))
				emit32((unsigned int) (data & 0xffffffff));
			else {
				emit8((unsigned int) (data & 0xff));
				emit8((unsigned int) ((data >> 8) & 0xff));
			}
			break;
		case 'H':
		case 'C':
			emit8((unsigned int) (data & 0xff));
			emit8((unsigned int) ((data >> 8) & 0xff));
			break;
		
		default: break;
		}
	}
}
