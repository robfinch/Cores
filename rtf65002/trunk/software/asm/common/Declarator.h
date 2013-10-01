#pragma once

namespace RTFClasses
{
	class Declarator
	{
		enum DeclType {
			POINTER,
			ARRAY,
			FUNCTION
		};

		Declarator *next;		// next declarator in declaration chain
		DeclType dcl_type;		// POINTER, ARRAY, or FUNCTION.
		int num_ele;			// If class == ARRAY, # of elements.
		bool tdef;				// chain was created by a typedef.

		bool IsArray() { return dcl_type==ARRAY; };
		bool IsPointer() { return dcl_type==POINTER; };
		bool IsFunction() { return dcl_type==FUNCTION; };
		bool IsPtrType() { return IsArray() || IsPointer(); };
	};
}

