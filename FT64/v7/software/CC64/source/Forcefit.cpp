// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - 'C' derived language compiler
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#include "stdafx.h"

// ----------------------------------------------------------------------------
// forcefit will coerce the nodes passed into compatible
// types and return the type of the resulting expression.
//
// Generally if the promote flag is set then the whichever type is larger
// is returned. Code is emitted to convert the shorter type to the longer type.
// Unless... a explicit typecast is taking place. The typecast using the
// typecast operator OR an assignment is taking place.
// ----------------------------------------------------------------------------
TYP *forcefit(ENODE **srcnode, TYP *srctp, ENODE **dstnode, TYP *dsttp, bool promote, bool typecast)
{
	ENODE *n2;

	if (dstnode)
		n2 = *dstnode;
	else
		n2 = (ENODE *)NULL;
	switch (srctp->type) {
	case bt_byte:
	case bt_ubyte:
	case bt_char:
	case bt_uchar:
	case bt_short:
	case bt_ushort:
	case bt_long:
	case bt_ulong:
	case bt_bitfield:
	case bt_ubitfield:
	case bt_exception:
		switch (dsttp->type) {
		case bt_long:	return &stdlong;
		case bt_ulong:	return &stdulong;
		case bt_short:	return &stdlong;
		case bt_ushort:	return &stdulong;
		case bt_char:	return &stdlong;
		case bt_uchar:	return &stdulong;
		case bt_byte:	return &stdlong;
		case bt_ubyte:	return &stdulong;
		case bt_enum:	return &stdlong;
		// If we have a pointer involved we likely want a pointer result.
		case bt_pointer:return (dsttp);
		case bt_float:
		case bt_double:
			if (typecast) {
				*dstnode = makenode(en_i2d, *srcnode, *dstnode); (*dstnode)->esize = 8; return (dsttp);
			}
			else {
				*srcnode = makenode(en_i2d, *srcnode, *dstnode); (*srcnode)->esize = 8; return (dsttp);
			}
		case bt_triple:
			if (typecast) {
				*dstnode = makenode(en_i2t, *srcnode, *dstnode); (*dstnode)->esize = 12; return (dsttp);
			}
			else {
				*srcnode = makenode(en_i2t, *srcnode, *dstnode); (*srcnode)->esize = 12; return (dsttp);
			}
		case bt_quad:	
			if (typecast) {
				*dstnode = makenode(en_i2q, *srcnode, *dstnode); (*dstnode)->esize = 16; return (dsttp);
			}
			else {
				*srcnode = makenode(en_i2q, *srcnode, *dstnode); (*srcnode)->esize = 16; return (dsttp);
			}
		case bt_exception:	return &stdexception;
		case bt_vector:	return (dsttp);
		case bt_union:	return (dsttp);
		case bt_struct:
		case bt_class:
			error(ERR_MISMATCH);
			return (dsttp);
		}
		return (srctp);

	case bt_enum:
		switch (dsttp->type) {
		case bt_long:	/**srcnode = makenode(en_ccw, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdlong;
		case bt_ulong:	/**srcnode = makenode(en_ccu, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdulong;
		case bt_short:	/**srcnode = makenode(en_ccw, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdlong;
		case bt_ushort:	/**srcnode = makenode(en_ccu, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdulong;
		case bt_char:	/**srcnode = makenode(en_ccw, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdlong;
		case bt_uchar:	/**srcnode = makenode(en_ccu, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdulong;
		case bt_byte:	/**srcnode = makenode(en_ccw, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdlong;
		case bt_ubyte:	/**srcnode = makenode(en_ccu, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdulong;
		case bt_enum:	/**srcnode = makenode(en_ccw, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdlong;
		case bt_pointer:/**srcnode = makenode(en_ccu, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return dsttp;
		case bt_exception:	/**srcnode = makenode(en_ccu, *srcnode, *dstnode);*/ (*srcnode)->esize = 8; return &stdexception;
		case bt_float:
		case bt_double:
			if (typecast) {
				*dstnode = makenode(en_i2d, *srcnode, *dstnode); (*dstnode)->esize = 8;	return (dsttp);
			}
			else {
				*srcnode = makenode(en_i2d, *srcnode, *dstnode); (*srcnode)->esize = 8;	return (dsttp);
			}
		case bt_triple:
			if (typecast) {
				*dstnode = makenode(en_i2t, *srcnode, *dstnode); (*dstnode)->esize = 12; return (dsttp);
			}
			else {
				*srcnode = makenode(en_i2t, *srcnode, *dstnode); (*srcnode)->esize = 12; return (dsttp);
			}
		case bt_quad:
			if (typecast) {
				*dstnode = makenode(en_i2q, *srcnode, *dstnode); (*dstnode)->esize = 16; return (dsttp);
			}
			else {
				*srcnode = makenode(en_i2q, *srcnode, *dstnode); (*srcnode)->esize = 16; return (dsttp);
			}
		case bt_vector:	return (dsttp);
		case bt_union:	return (dsttp);
		case bt_struct:
		case bt_class:
			error(ERR_MISMATCH);
			return (dsttp);
		}
		return srctp;

	case bt_pointer:
		switch (dsttp->type)
		{
		case bt_byte:
		case bt_ubyte:
		case bt_char:
		case bt_uchar:
		case bt_short:
		case bt_ushort:
		case bt_long:
		case bt_ulong:
		case bt_pointer: return (srctp);
			// pointer to function was really desired.
		case bt_func:
		case bt_ifunc:
			return (srctp);
		case bt_struct:
			if ((*dstnode)->nodetype == en_list || (*dstnode)->nodetype == en_aggregate)
				return (srctp);
			break;
		}

	case bt_float:
		switch (dsttp->type) {
		case bt_byte:
		case bt_ubyte:
		case bt_char:
		case bt_uchar:
		case bt_short:
		case bt_ushort:
		case bt_long:	
		case bt_ulong:	
		case bt_exception:
		case bt_enum:
			if (typecast) {
				*srcnode = makenode(en_d2i, *srcnode, *dstnode);
				return (dsttp);
			}
			else {
				*dstnode = makenode(en_i2d, *dstnode, *srcnode);
				return (srctp);
			}
		case bt_pointer: return(dsttp);
		case bt_double:	
			return (dsttp);
		case bt_triple:	*srcnode = makenode(en_d2t, *srcnode, *dstnode); return (dsttp);
		case bt_quad:	*srcnode = makenode(en_d2q, *srcnode, *dstnode); return (dsttp);
		case bt_vector:	return (dsttp);
		case bt_union:	return (dsttp);
		case bt_struct:
		case bt_class:
			error(ERR_MISMATCH);
			return (dsttp);
		}
		return srctp;

	case bt_double:
		switch (dsttp->type) {
		case bt_byte:
		case bt_ubyte:
		case bt_char:
		case bt_uchar:
		case bt_short:
		case bt_ushort:
		case bt_long:
		case bt_ulong:
		case bt_exception:
		case bt_enum:
			if (typecast) {
				*dstnode = makenode(en_d2i, *srcnode, *dstnode);
				return (dsttp);
			}
			else {
				*dstnode = makenode(en_i2d, *dstnode, *srcnode);
				return (srctp);
			}
		case bt_pointer: return(dsttp);
		case bt_double:	return (dsttp);
		case bt_triple:	*srcnode = makenode(en_d2t, *srcnode, *dstnode); return (dsttp);
		case bt_quad:	*srcnode = makenode(en_d2q, *srcnode, *dstnode); return (dsttp);
		case bt_vector:	return (dsttp);
		case bt_union:	return (dsttp);
		case bt_struct:
		case bt_class:
			error(ERR_MISMATCH);
			return (dsttp);
		}
		return srctp;

	case bt_triple:
		switch (dsttp->type) {
		case bt_byte:
		case bt_ubyte:
		case bt_char:
		case bt_uchar:
		case bt_short:
		case bt_ushort:
		case bt_long:
		case bt_ulong:
		case bt_exception:
		case bt_enum:	*dstnode = makenode(en_i2t, *dstnode, *srcnode); return (srctp);
		case bt_pointer: return(dsttp);
		case bt_double:	*dstnode = makenode(en_d2t, *dstnode, *srcnode); return (srctp);
		case bt_triple:	return (dsttp);
		case bt_quad:	*srcnode = makenode(en_t2q, *srcnode, *dstnode); return (dsttp);
		case bt_vector:	return (dsttp);
		case bt_union:	return (dsttp);
		case bt_struct:
		case bt_class:
			error(ERR_MISMATCH);
			return (dsttp);
		}
		return srctp;

	case bt_quad:
		switch (dsttp->type) {
		case bt_byte:
		case bt_ubyte:
		case bt_char:
		case bt_uchar:
		case bt_short:
		case bt_ushort:
		case bt_long:
		case bt_ulong:
		case bt_exception:
		case bt_enum:	*dstnode = makenode(en_i2t, *dstnode, *srcnode); return (srctp);
		case bt_pointer: return(dsttp);
		case bt_double:	*dstnode = makenode(en_d2q, *dstnode, *srcnode); return (srctp);
		case bt_triple:	*dstnode = makenode(en_t2q, *dstnode, *srcnode); return (srctp);
		case bt_quad:	return (dsttp);
		case bt_vector:	return (dsttp);
		case bt_union:	return (dsttp);
		case bt_struct:
		case bt_class:
			error(ERR_MISMATCH);
			return (dsttp);
		}
		return srctp;

	case bt_class:
	case bt_struct:
	case bt_union:
		if (dsttp->size > srctp->size || typecast)
			return (dsttp);
		return (srctp);
		// Really working with pointers to functions.
	case bt_func:
	case bt_ifunc:
		return srctp;
	case bt_void:
		return (dsttp);
	}
	error(ERR_MISMATCH);
	return srctp;
}

