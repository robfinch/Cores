#include "MyString.h"
#include "Assembler.h"

namespace RTFClasses
{
	static Opa byteAsm[] = { {&Assembler::db, 'B', -1}, NULL };
	static Opa dbAsm[] = { {Assembler::db, 'B', -1}, NULL };
	static Opa dcAsm[] = { {Assembler::db, 'C', -1}, NULL };
	static Opa dwAsm[] = { {Assembler::db, 'C', -1}, NULL };
	static Opa charAsm[] = { {Assembler::db, 'C', -1}, NULL };
	static Opa alignAsm[] = { {a_align,0,1 }, NULL };
	static Opa bssAsm[] = { {a_bss}, NULL };
	static Opa codeAsm[] = { {a_code,0,0}, NULL };
	static Opa cpuAsm[] = { {a_cpu,0,-1}, NULL };
	static Opa dataAsm[] = { {a_data}, NULL };
	static Opa endAsm[] = { {a_end}, NULL };
	static Opa externAsm[] = {{a_extern,0,-1}, NULL };
	static Opa fillAsm[] = { {a_fill,0,2}, NULL };
	static Opa includeAsm[] = { {a_include,0,1}, NULL };
	static Opa messageAsm[] = { {a_message,0,1}, NULL };
	static Opa orgAsm[] = { {Assembler::org,0,1}, NULL };
	static Opa commentAsm[] = { {a_comment,0,-1}, NULL };
	static Opa endmAsm[] = { {a_endm}, NULL};
	static Opa wordAsm[] = { {Assembler::db,'C',-1}, NULL };
	static Opa publicAsm[] = { {a_public,0, -1}, NULL };
	static Opa listAsm[] = {{a_list,0,1}, NULL};
	static Opa macroAsm[] = {{a_macro,0,-1}, NULL};

	bool Assembler::processPseudoop(String str)
	{
		String s;

		s.copy(str);
		s.toLower();
		if (s[0]=='.') {
		}
		else if (s[0]=='a') {
			if (s.len()==5 && s[1]=='l' && s[2]=='i' && s[3]=='g' && s[4]=='n') {
				align();
				return true;
			}
			return false;
		}
		else if (s[0]=='b') {
			if (s.len()==4 && s[1]=='y' && s[2]=='t' && s[3]=='e') {
				db();
				return true;
			}
			return false;
		}
		else if (s[0]=='d') {
			if (s.len()==2) {
				if (s[1]=='b') {
					db();
					return true;
				}
				if (s[1]=='c') {
				}
	}
}
