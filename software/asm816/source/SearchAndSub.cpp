/* ---------------------------------------------------------------
	(C) 2000 Bird Computer
	All rights reserved

   	Description :
		Searches and substitutes macro text for macro
	identifiers. We don't want to perform substitutions while
	inside comments	or quotes.
--------------------------------------------------------------- */

void SearchAndSub()
{
   CMacro tmacr, *mp;
   char *sptr, *eptr, *sptr1;
   char *plist[MAX_MACRO_PARMS];
   char nbuf[NAME_MAX+1];
   int na;
   int idlen = 0;
   int slen, tomove;
   int ic1, ic2, iq;
   int SkipNextIdentifier = 0;
   char ch;

//   printf("Search and Sub:");
   // Copy global comment indicators
   ic1 = InComment;
   ic2 = InComment2;
   // iq should be 0 coming in since we SearchAndSub at start of line processing.
   iq = 0;
   while (ibuf.PeekCh()) {

      if (ic2) {
         while(1) {
            if (ibuf.PeekCh() == '*' && ibuf.Ptr()[1] == '/') {
               ic2--;
               ibuf.NextCh();
               goto EndOfLoop;
            }
            ch = ibuf.NextCh();
            if (ch < 1 || ch == '\n')
               goto EndOfLoop2;
         }
      }

      if (ic1) {
         while(1) {
            if (ibuf.PeekCh() == CommentChar) {
               --ic1;
               goto EndOfLoop;
            }
            ch = ibuf.NextCh();
            if (ch < 1 || ch == '\n')
               goto EndOfLoop2;
         }
      }

      // Comment to EOL ?
      if ((ibuf.PeekCh() == '/' && ibuf.Ptr()[1] == '/') || ibuf.PeekCh() == ';') {
         while(1) {
            ch = ibuf.NextCh();
            if (ch < 1 || ch == '\n')
               goto EndOfLoop2;
         }
      }

      if (ibuf.PeekCh() == '"') {
         ibuf.NextCh();
         while(1) {
            ch = ibuf.NextCh();
            if (ch < 1 || ch == '\n')
               goto EndOfLoop2;
            if (ch == '"')
               goto EndOfLoop;
         }
      }
      
      if (ibuf.PeekCh() == '\'') {
         ibuf.NextCh();
         while(1) {
            ch = ibuf.NextCh();
            if (ch < 1 || ch == '\n')
               goto EndOfLoop2;
            if (ch == '\'')
               goto EndOfLoop;
         }
      }

      if (ibuf.PeekCh() == '\n') {
         ibuf.NextCh();
         goto EndOfLoop2;
      }

      // Block comment
      if (ibuf.PeekCh() == '/' && ibuf.Ptr()[1] == '*') {
         ic2++;
         ibuf.NextCh();
         ibuf.NextCh();
         continue;
      }

      sptr1 = ibuf.Ptr();
      idlen = ibuf.GetIdentifier(&sptr, &eptr); // look for an identifier
      if (idlen) {
         if ((strncmp(sptr, "comment", 7)==0) && !IsIdentChar(sptr[7])) {
            ic1++;
            CommentChar = ibuf.NextNonSpace();
            continue;
         }
         //    If macro definition found, we want to skip over the macro name
         // otherwise the macro will substitute for the macro name during the
         // second pass.
         if ((strncmp(sptr, "macro", 5) == 0) && !IsIdentChar(sptr[5]))
            SkipNextIdentifier = TRUE;
         else {
            if (SkipNextIdentifier == TRUE)
               SkipNextIdentifier = FALSE;
            else {
               memset(nbuf, '\0', sizeof(nbuf));
               strncpy(nbuf, sptr, min(NAME_MAX, idlen));
               tmacr.SetName(nbuf);
               mp = MacroTbl->find(&tmacr);// if the identifier is a macro
               if (mp) {
                  if (mp->Nargs() > 0) {
                     na = ibuf.GetParmList(plist);
                     if (na != mp->Nargs())
                        err(NULL, E_MACROARG);
                  }
                  else
                     na = 0;
                  // slen = length of text substituted for
                  slen = ibuf.Ptr() - sptr1;
                  // tomove = number of characters to move
                  //        = buffer size - current pointer position
                  tomove = ibuf.Size() - (ibuf.Ptr() - ibuf.Buf());
                  // sptr = where to begin substitution
//                  printf("sptr:%.*s|,slen=%d,tomove=%d\n", slen, sptr,slen,tomove);
                  mp->sub(plist, sptr1, slen, tomove);
               }
            }
         }
      }
EndOfLoop:
      ibuf.NextCh();
   }
EndOfLoop2:
   ibuf.rewind();
}
