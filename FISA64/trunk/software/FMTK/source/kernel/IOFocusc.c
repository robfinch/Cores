#include "types.h"
#include "proto.h"

extern JCB *IOFocusNdx;
extern int IOFocusTbl[4];
extern int iof_sema;

void ForceIOFocus(JCB *j)
{
    RequestIOFocus(j);   // In case it isn't requested yet.
     if (LockSemaphore(&iof_sema,-1)) {
        if (j != IOFocusNdx) {
            CopyScreenToVirtualScreen();
            j->pVidMem = j->pVirtVidMem;
            IOFocusNdx = j;
            j->pVidMem = 0xFFD00000;
            CopyVirtualScreenToScreen();
        }
        UnlockSemaphore(&iof_sema);
     }
}


// First check if it's even possible to switch the focus to another
// task. The I/O focus list could be empty or there may be only a
// single task in the list. In either case it's not possible to
// switch.
void SwitchIOFocus()
{
     JCB *j, *p;

     if (LockSemaphore(&iof_sema,-1)) {
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
        UnlockSemaphore(&iof_sema);
     }
}

//-----------------------------------------------------------------------------
// The I/O focus list is an array indicating which jobs are requesting the
// I/O focus. The I/O focus is user controlled by pressing ALT-TAB on the
// keyboard.
//-----------------------------------------------------------------------------

void RequestIOFocus(JCB *j)
{
     int nj;
     int stat;

     nj = j->number;
     if (LockSemaphore(&iof_sema,-1)) {
        stat = (IOFocusTbl[0] >> nj) & 1;
        if (!stat) {
           if (IOFocusNdx==null) {
               IOFocusNdx = j;
               j->iof_next = j;
               j->iof_prev = j;
           }
           else {
               j->iof_prev = IOFocusNdx->iof_prev;
               j->iof_next = IOFocusNdx;
               IOFocusNdx->iof_prev->iof_next = j;
               IOFocusNdx->iof_prev = j;
           }
           IOFocusTbl[0] |= (1 << nj);
        }
        UnlockSemaphore(&iof_sema);
     }
}
        
//-----------------------------------------------------------------------------
// Release the IO focus for the current job.
//-----------------------------------------------------------------------------
void ReleaseIOFocus()
{
     ForceReleaseIOFocus(GetJCBPtr());
}

//-----------------------------------------------------------------------------
// Releasing the I/O focus causes the focus to switch if the running job
// had the I/O focus.
// ForceReleaseIOFocus forces the release of the IO focus for a job
// different than the one currently running.
//-----------------------------------------------------------------------------

void ForceReleaseIOFocus(JCB * j)
{
     JCB *p;
     
     if (LockSemaphore(&iof_sema,-1)) {
         if (IOFocusTbl[0] & (1 << (int)j->number)) {
             IOFocusTbl[0] &= ~(1 << j->number);
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
        UnlockSemaphore(&iof_sema);
     }
}

void CopyVirtualScreenToScreen()
{
     short int *p, *q;
     JCB *j;
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
     short int *p, *q;
     JCB *j;
     int nn;

     j = IOFocusNdx;
     p = j->pVidMem;
     q = j->pVirtVidMem;
     nn = j->VideoRows * j->VideoCols;
     for (; nn >= 0; nn--)
         q[nn] = p[nn];
}

