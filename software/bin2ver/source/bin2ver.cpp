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
	int start_address = 0x0;
	bool memfile = false;
	int modulus = 32768;

	if (argv[1] == nullptr) {
		printf("bin2ver <filename> [-b<bits>] [-mod<n>] [-m] [-s<start offset in hex>]\n");
		exit(0);
	}

	// Process command line arguments.
	kk = 0;
	for (n = 2; n < argc; n++) {
j1:
		switch (argv[n][kk]) {
		// Skip over +/-
		case '+':
		case '-':
			kk++;
			goto j1;
		// b=< number of bits >
		case 'b':
			kk++;
			if (argv[n][kk] == '=')
				kk++;
			vebits = atoi(&argv[n][kk]);
			if (vebits != 32 && vebits != 64 && vebits != 128 && vebits != 256) {
				printf("Bad number of bits.");
				exit(0);
			}
			kk = 0;
			continue;
		// mod=<modulus>
		// m for mem file
		case 'm':
			kk++;
			switch (argv[n][kk]) {
			case 'o':
				kk++;
				if (argv[n][kk] == 'd')
					kk++;
				if (argv[n][kk] == '=')
					kk++;
				modulus = atoi(&argv[n][kk]);
				kk = 0;
				continue;
			default:
				memfile = true;
				kk = 0;
				continue;
			}
		case 's':
			kk++;
			if (argv[n][kk] == '=')
				kk++;
			start_address = strtoul(&argv[n][kk], nullptr, 16);
			continue;
		default:
			;
		}
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

	fopen_s(&vfp, memfile ? "rom.mem" : "rom.ver", "wb");
	if (vfp == nullptr) {
		printf("Can't open %s\n", memfile ? "rom.mem" : "rom.ver");
		exit(0);
	}
	if (vebits == 256) {
		for (kk = 0; kk < binndx; kk += 32) {
			if (memfile)
				fprintf(vfp,	"%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8
											"%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8
					"\n",
					binfile[kk + 31], binfile[kk + 30], binfile[kk + 29], binfile[kk + 28],
					binfile[kk + 27], binfile[kk + 26], binfile[kk + 25], binfile[kk + 24],
					binfile[kk + 23], binfile[kk + 22], binfile[kk + 21], binfile[kk + 20],
					binfile[kk + 19], binfile[kk + 18], binfile[kk + 17], binfile[kk + 16],
					binfile[kk + 15], binfile[kk + 14], binfile[kk + 13], binfile[kk + 12],
					binfile[kk + 11], binfile[kk + 10], binfile[kk + 9], binfile[kk + 8],
					binfile[kk + 7], binfile[kk + 6], binfile[kk + 5], binfile[kk + 4],
					binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
			else
				fprintf(vfp, "\trommem[%d] = 256'h%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X;\n",
				((((unsigned int)start_address + kk) / 32) % modulus), //checksum64((int64_t *)&binfile[kk]),
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
			if (memfile)
				fprintf(vfp, "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "\n",
					binfile[kk + 15], binfile[kk + 14], binfile[kk + 13], binfile[kk + 12],
					binfile[kk + 11], binfile[kk + 10], binfile[kk + 9], binfile[kk + 8],
					binfile[kk + 7], binfile[kk + 6], binfile[kk + 5], binfile[kk + 4],
					binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
			else
				fprintf(vfp, "\trommem[%d] = 128'h%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 "%02" PRIX8 ";\n",
					((((unsigned int)start_address + kk) / 16) % modulus), //checksum64((int64_t *)&binfile[kk]),
					binfile[kk + 15], binfile[kk + 14], binfile[kk + 13], binfile[kk + 12],
					binfile[kk + 11], binfile[kk + 10], binfile[kk + 9], binfile[kk + 8],
					binfile[kk + 7], binfile[kk + 6], binfile[kk + 5], binfile[kk + 4],
					binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
		}
		/*
		if (!memfile) {
			fprintf(vfp, "\trommem[10238] = 128'h00000000000000000000000000000000;\n");
			fprintf(vfp, "\trommem[10239] = 128'h%08X%08X0000000000000000;\n", binlen, checksum);
		}
		*/
	}
	else if (vebits == 64) {
		for (kk = 0; kk < binndx; kk += 8) {
			fprintf(vfp, "\trommem[%d] = 64'h%02X%02X%02X%02X%02X%02X%02X%02X;\n",
				((((unsigned int)start_address + kk) / 8) % modulus), //checksum64((int64_t *)&binfile[kk]),
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
			if (memfile)
				fprintf(vfp, "%02X%02X%02X%02X\n",
					binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
			else
				fprintf(vfp, "\trommem[%d] = 32'h%02X%02X%02X%02X;\n",
					((((unsigned int)start_address + kk) / 4) % modulus), //checksum64((int64_t *)&binfile[kk]),
					binfile[kk + 3], binfile[kk + 2], binfile[kk + 1], binfile[kk]);
		}
		if (!memfile) {
			fprintf(vfp, "\trommem[49144] = 32'h00000000;\n");
			fprintf(vfp, "\trommem[49145] = 32'h00000000;\n");
			fprintf(vfp, "\trommem[49146] = 32'h00000000;\n");
			fprintf(vfp, "\trommem[49147] = 32'h00000000;\n");
			fprintf(vfp, "\trommem[49148] = 32'h00000000;\n");
			fprintf(vfp, "\trommem[49149] = 32'h00000000;\n");
			fprintf(vfp, "\trommem[49150] = 32'h%08X;\n", binlen);
			fprintf(vfp, "\trommem[49151] = 32'h%08X;\n", checksum);
		}
	}
	fclose(vfp);
}
