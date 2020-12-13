#include <stdio.h>
#include <inttypes.h>
#include <string>
#include <iostream>
#include <fstream>

uint8_t binfile[10000000];

std::ifstream::pos_type filesize(const char* filename) {
	std::ifstream in(filename, std::ifstream::ate | std::ifstream::binary);
	return in.tellg();
}

int main(int argc, char* argv[])
{
	int vebits = 128;
	int n, kk, binlen, binndx, checksum;
	FILE* vfp;
	int start_address = 0xFFFC0000;

	if (argv[1] == nullptr) {
		printf("bin2ver <filename> [<bits>]\n");
		exit(0);
	}

	if (argv[2])
		vebits = atoi(argv[2]);
	if (vebits != 32 && vebits != 64 && vebits != 128 && vebits != 256) {
		printf("Bad number of bits.");
		exit(0);
	}

	std::ifstream::pos_type fs = filesize(argv[1]);
	binndx = fs;

	std::ifstream ifs;
	ifs.open(argv[1], std::ios::in | std::ios::binary);
	if (ifs.fail())
		exit(0);
	ifs.read((char *)binfile, fs);
	ifs.close();

	checksum = 0;
	for (n = 0; n < binndx; n++)
		checksum += binfile[n];
	printf("Checksum: %08X\r\n", checksum);
	binlen = binndx;

	fopen_s(&vfp, "rom.ver", "wb");
	if (vfp == nullptr) {
		printf("Can't open %s\n", "rom.ver");
		exit(0);
	}
	if (vebits == 256) {
		for (kk = 0; kk < binndx; kk += 32) {
			fprintf(vfp, "\trommem[%d] = 256'h%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X;\n",
				((((unsigned int)start_address + kk) / 32) % 8192), //checksum64((int64_t *)&binfile[kk]),
				binfile[kk + 31] & 0xff, binfile[kk + 30], binfile[kk + 29], binfile[kk + 28],
				binfile[kk + 27], binfile[kk + 26], binfile[kk + 25], binfile[kk + 24],
				binfile[kk + 23], binfile[kk + 22], binfile[kk + 21], binfile[kk + 20],
				binfile[kk + 19], binfile[kk + 18], binfile[kk + 17], binfile[kk + 16],
				binfile[kk + 15], binfile[kk + 14], binfile[kk + 13], binfile[kk + 12],
				binfile[kk + 11], binfile[kk + 10], binfile[kk + 9], binfile[kk + 8],
				binfile[kk + 7], binfile[kk + 6], binfile[kk + 5], binfile[kk + 4],
				binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
		}
		fprintf(vfp, "\trommem[7166] = 256'h0000000000000000000000000000000000000000000000000000000000000000;\n");
		fprintf(vfp, "\trommem[7167] = 256'h%08X%08X000000000000000000000000000000000000000000000000;\n", binlen, checksum);
	}
	else if (vebits == 128) {
		for (kk = 0; kk < binndx; kk += 16) {
			fprintf(vfp, "\trommem[%d] = 128'h%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 ";\n",
				((((unsigned int)start_address + kk) / 16) % 16384), //checksum64((int64_t *)&binfile[kk]),
				binfile[kk + 15], binfile[kk + 14], binfile[kk + 13], binfile[kk + 12],
				binfile[kk + 11], binfile[kk + 10], binfile[kk + 9], binfile[kk + 8],
				binfile[kk + 7], binfile[kk + 6], binfile[kk + 5], binfile[kk + 4],
				binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
		}
		fprintf(vfp, "\trommem[10238] = 128'h00000000000000000000000000000000;\n");
		fprintf(vfp, "\trommem[10239] = 128'h%08X%08X0000000000000000;\n", binlen, checksum);
	}
	else if (vebits == 64) {
		for (kk = 0; kk < binndx; kk += 8) {
			fprintf(vfp, "\trommem[%d] = 64'h%02X%02X%02X%02X%02X%02X%02X%02X;\n",
				((((unsigned int)start_address + kk) / 8) % 32768), //checksum64((int64_t *)&binfile[kk]),
				binfile[kk + 7], binfile[kk + 6], binfile[kk + 5], binfile[kk + 4],
				binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
		}
		fprintf(vfp, "\trommem[24572] = 64'h0000000000000000;\n");
		fprintf(vfp, "\trommem[24573] = 64'h0000000000000000;\n");
		fprintf(vfp, "\trommem[24574] = 64'h0000000000000000;\n");
		fprintf(vfp, "\trommem[24575] = 64'h%08X%08X;\n", binlen, checksum);
	}
	else if (vebits == 32) {
		for (kk = 0; kk < binndx; kk += 4) {
			fprintf(vfp, "\trommem[%d] = 32'h%02X%02X%02X%02X;\n",
				((((unsigned int)start_address + kk) / 4) % 32768), //checksum64((int64_t *)&binfile[kk]),
				binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
		}
		fprintf(vfp, "\trommem[49144] = 32'h00000000;\n");
		fprintf(vfp, "\trommem[49145] = 32'h00000000;\n");
		fprintf(vfp, "\trommem[49146] = 32'h00000000;\n");
		fprintf(vfp, "\trommem[49147] = 32'h00000000;\n");
		fprintf(vfp, "\trommem[49148] = 32'h00000000;\n");
		fprintf(vfp, "\trommem[49149] = 32'h00000000;\n");
		fprintf(vfp, "\trommem[49150] = 32'h%08X;\n", binlen);
		fprintf(vfp, "\trommem[49151] = 32'h%08X;\n", checksum);
	}
	fclose(vfp);
}
