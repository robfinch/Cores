#pragma once

class Counter {
public:
	int byte;
	U32 val;

	Counter() { byte = 0; val = 0; };
	void reset() { byte = 0; val = 0; };
	void set(U32 pos) { byte = 0; val = pos; };
	void ByteInc(int stride) {
		byte++;
		if (byte == stride) {
			byte = 0;
			val++;
		}
	};
	void inc() {
		val++;
	};
};

