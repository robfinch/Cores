#include "config.h"	// for NR_ACBS
#include "types.h"
#include "proto.h"

extern ACB *IOFocusNdx;
extern int IOFocusTbl[4];
extern int iof_sema;
extern ACB *ACBPtrs[64];

extern hMBX hFocusSwitchMbx;

void FocusSwitcher()
{
     int d1,d2,d3;

     if firstcall {
         FMTK_AllocMbx(&hFocusSwitchMbx);
     }
     forever {
         FMTK_WaitMsg(hFocusSwitchMbx, &d1, &d2, &d3, 0x7FFFFFFFL);
         SwitchIOFocus();
     }
}


void ForceIOFocus(ACB *j)
{
    RequestIOFocus(j);   // In case it isn't requested yet.
     if (LockIOFSemaphore(-1)) {
        if (j != IOFocusNdx) {
            CopyScreenToVirtualScreen();
            j->pVidMem = j->pVirtVidMem;
            IOFocusNdx = j;
            j->pVidMem = 0xFFD00000;
            CopyVirtualScreenToScreen();
        }
        UnlockIOFSemaphore();
     }
}


// First check if it's even possible to switch the focus to another
// task. The I/O focus list could be empty or there may be only a
// single task in the list. In either case it's not possible to
// switch.
void SwitchIOFocus()
{
     ACB *j, *p;

     if (LockIOFSemaphore(-1)) {
         j = IOFocusNdx;
         if (j) {
             p = IOFocusNdx->iof_next;
             if (p <> IOFocusNdx) {
                 if (p) {
                     CopyScreenToVirtualScreen();
                     j->pVidMem = j->pVirtVidMem;
                     IOFocusNdx = p;
                     p->pVidMem = 0xFFD00000;
                     CopyVirtualScreenToScreen();
                 }
             }
         }
         UnlockIOFSemaphore();
     }
}

//-----------------------------------------------------------------------------
// The I/O focus list is an array indicating which jobs are requesting the
// I/O focus. The I/O focus is user controlled by pressing ALT-TAB on the
// keyboard.
//-----------------------------------------------------------------------------

void RequestIOFocus(ACB *j)
{
     int nj, nn;
     int stat;

     nj = j->number;
	 if (nj < 0 || nj >= NR_ACB)
		 return;
     if (LockIOFSemaphore(100000)) {
		 asm {
			 ldi	r1,#256
			 sc		r1,$FFDC0600
		 }
		nn = nj >> 5;	// 32 bits per table entry
		nj &= 0x1f;		// max bit number
        stat = (IOFocusTbl[nn] >> nj) & 1;
		 asm {
			 ldi	r1,#257
			 sc		r1,$FFDC0600
		 }
        if (!stat) {
		 asm {
			 ldi	r1,#258
			 sc		r1,$FFDC0600
		 }
           if (IOFocusNdx==null) {
               IOFocusNdx = j;
               j->iof_next = j;
               j->iof_prev = j;
           }
           else {
		 asm {
			 ldi	r1,#259
			 sc		r1,$FFDC0600
		 }
               j->iof_prev = IOFocusNdx->iof_prev;
               j->iof_next = IOFocusNdx;
               IOFocusNdx->iof_prev->iof_next = j;
               IOFocusNdx->iof_prev = j;
           }
		 asm {
			 ldi	r1,#260
			 sc		r1,$FFDC0600
		 }
           IOFocusTbl[nn] |= (1 << nj);
		 asm {
			 ldi	r1,#261
			 sc		r1,$FFDC0600
		 }
        }
		 asm {
			 ldi	r1,#262
			 sc		r1,$FFDC0600
		 }
        UnlockIOFSemaphore();
     }
}
        
//-----------------------------------------------------------------------------
// Release the IO focus for the current job.
//-----------------------------------------------------------------------------
void ReleaseIOFocus()
{
     ForceReleaseIOFocus(GetACBPtr());
}

//-----------------------------------------------------------------------------
// Releasing the I/O focus causes the focus to switch if the running job
// had the I/O focus.
// ForceReleaseIOFocus forces the release of the IO focus for a job
// different than the one currently running.
//-----------------------------------------------------------------------------

void ForceReleaseIOFocus(ACB * j)
{
     ACB *p;
	 int nj;
     int nn;

     if (LockIOFSemaphore(-1)) {
		 nj = j->number;
		 nn = nj >> 5;
		 nj &= 0x1f;
         if (IOFocusTbl[nn] & (1 << nj)) {
             IOFocusTbl[nn] &= ~(1 << nj);
             if (j == IOFocusNdx)
                SwitchIOFocus();
             p = j->iof_next;
             if (p) {
                  if (p <> j) {
                        p->iof_prev = j->iof_prev;
                        j->iof_prev->iof_next = p;
                  } 
                  else {
                       IOFocusNdx = null;
                  }
                  j->iof_next = null;
                  j->iof_prev = null;
             }
         }
         UnlockIOFSemaphore();
     }
}

void CopyVirtualScreenToScreen()
{
	int *p, *q;
	ACB *j;
	int nn, pos;

	j = IOFocusNdx;
	p = j->pVidMem;
	q = j->pVirtVidMem;
	nn = j->VideoRows * j->VideoCols;
	for (; nn >= 0; nn--)
		p[nn] = q[nn];
    pos = j->CursorRow * j->VideoCols + j->CursorCol;
    SetVideoReg(11,pos);
}

void CopyScreenToVirtualScreen()
{
	int *p, *q;
	ACB *j;
	int nn;

	j = IOFocusNdx;
	p = j->pVidMem;
	q = j->pVirtVidMem;
	nn = j->VideoRows * j->VideoCols;
	for (; nn >= 0; nn--)
		q[nn] = p[nn];
}

