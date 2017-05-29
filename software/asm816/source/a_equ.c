/* ---------------------------------------------------------------
	Description :
		Defines a macro that doesn't take parameters. The
	macro definition is assumed to be the remaining text on the
	line unless the last character is '\' which continues the
	definition with the next line.

		Associate symbols with numeric values. During pass one
	any symbols encountered should not be previously defined.
	If a symbol that already exists is encountered in an equ
	statement during pass one then it is multiplely defined.
	This is an error.

	Returns:
		FALSE if the line isn't an equ statement, otherwise
	TRUE.
--------------------------------------------------------------- */

int a_equ(char *iid)
{
   CSymbol *p, tdef;
   __int64 n;
   char size,
      label[50];
   char *sptr, *eptr, *ptr;
   char tbuf[80];
   int idlen;
   SValue v;

//   printf("m_equ(%s)\n", iid);

   /* --------------------------------------------------------------
   -------------------------------------------------------------- */
   ptr = ibuf.Ptr();    // Save off starting point // inptr;
    if (*ptr=='=')
       ibuf.NextCh();
    else
    {
       idlen = ibuf.GetIdentifier(&sptr, &eptr);
       if (idlen == 0)
       {
          ibuf.setptr(ptr); // restore starting point
          return FALSE;
       }

       if (idlen == 3)
       {
          if (strnicmp(sptr, "equ", 3))
          {
             ibuf.setptr(ptr);
             return (FALSE);
          }
       }
       else
       {
          ibuf.setptr(ptr);
          return (FALSE);
       }
    }

   /* -------------------------------------------------------
         Attempt to find the symbol in the symbol tree. If
      found during pass one then it is a redefined symbol
      error.
   ------------------------------------------------------- */
   tdef.SetName(iid);
   p = NULL;
   if (LocalSymTbl)
      p = LocalSymTbl->find(&tdef);
   if (p == NULL)
      p = SymbolTbl->find(&tdef);
   if(pass == 1)
   {
      if(p != NULL)
      {
         err(NULL, E_DEFINED, label);    // Symbol already defined.
         return (TRUE);
      }

      size = (char)GetSzChar();
      if (size != 0 && !strchr("BCHWLDS", size))
      {
         err(NULL, E_LENGTH);       //Wrong length.
         return (TRUE);
      }

      if (LocalSymTbl)
         p = LocalSymTbl->allocsym();
      else
         p = SymbolTbl->allocsym();
      if (p == NULL) {
         err(NULL, E_MEMORY);
         return TRUE;
      }
      // assume a size if not specified
      if (size==0)
      {
          if (gProcessor==102||gProcessor==65102)
              size = 'W';
            else
                size = 'C';
      }
      p->SetSize(size);
      p->SetName(iid);
	  p->SetLabel(0);
      p->Def(NO_OCLASS, File[CurFileNum].LastLine, CurFileNum);

      if (LocalSymTbl)
         LocalSymTbl->insert(p);
      else
         SymbolTbl->insert(p);
      v = ibuf.expeval(&eptr);
	  n = v.value;
	  // If the value is unsized set the size to long if it might
	  // contain a forward reference, otherwise set the size based
	  // on what the symbol evaluates to.
	  if (size == 0) {
		  if (v.fForwardRef) {
              if (gProcessor==102||gProcessor==65102) {
			        p->SetSize('W');
			        size = 'W';
              }
              else { 
    			  p->SetSize('C');
			        size = 'C';
              }
		  }
		  else {
			  p->SetSize(v.size);
		  }
	  }
      p->SetValue(n);
      p->SetDefined(1);
   }
   /* --------------------------------------------------------
         During pass two the symbol should be in the symbol
      tree as it would have been encountered during the
      first pass.
   -------------------------------------------------------- */
   else if(pass >= 2)
   {
      if(p == NULL)
      {
         err(NULL, E_NOTDEFINED, iid); // Undefined symbol.
         return (TRUE);
      }

      // skip over size spec
      size = (char)GetSzChar();
      if (size != 0 && !strchr("BWCHLDS", size))
      {
         err(NULL, E_LENGTH);       //Wrong length.
         return (TRUE);
      }

      /* -----------------------------------------------------
            Calculate what the symbol is equated to since
         forward references may now be filled in causing the
         value of the equate to be different than pass one 
         during pass two.
      ------------------------------------------------------ */
      v = ibuf.expeval(&eptr);
	  n = v.value;
      if(errtype == FALSE)
      {
         return (TRUE);
      }
      p->SetValue(n);

      /* ---------------------------------------------------------------------
            Print symbol value if in listing mode. The monkey business with
         tbuf is neccessary to chop off leading 'FF's when the value is
         negative.
      --------------------------------------------------------------------- */
      if(bGen && fListing)
      {
         switch(toupper(v.size/*  size*/))
         {
            case 'B':
               sprintf(tbuf, "%08.8X", (int)n);
               memmove(tbuf, &tbuf[6], 3);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-14,"");
               col = SRC_COL-1;
               break;

            case 'C':
            case 'H':
               sprintf(tbuf, "%08.8X", (int)n);
               memmove(tbuf, &tbuf[4], 5);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-16, "");
               col = SRC_COL-1;
               break;

            case 'W':
            case 'L':
               sprintf(tbuf, "%08.8X", (int)n);
               memmove(tbuf, &tbuf[0], 9);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-20, "");
               col = SRC_COL-1;
               break;

			case 'S':
			case 'D':
               sprintf(tbuf, "%08.8X", (int)(n >> 32));
               memmove(tbuf, &tbuf[0], 9);
               sprintf(&tbuf[6], "%08.8X", (int)n);
               memmove(&tbuf[6], &tbuf[8], 7);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-14, "");
               col = SRC_COL-1;
               break;
         }
//         OutListLine();
      }
   }
   return (TRUE);
}


