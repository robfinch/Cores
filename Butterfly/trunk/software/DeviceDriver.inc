; Device Control Block
;
DCB_Name			EQU		0		; string: first byte is length, 11 chars max
DCB_Type			EQU		0x0C
DCB_nBPB			EQU		0x0E
DCB_LastErc			EQU		0x10		; last error code
DCB_StartBlock		EQU		0x14		; starting block number (partitioned devices)
DCB_nBlocks			EQU		0x18		; number of blocks on device
DCB_pCmdProc		EQU		0x1C		; pointer to command processor routine
DCB_ReentCount		EQU		0x20		; re-entrancy count (1 to 255)
DCB_fSingleUser		EQU		0x21
DCB_hJob			EQU		0x22		; handle to associated job
DCB_Mbx				EQU		0x24
DCB_pSema			EQU		0x26		; pointer to device semaphore
DCB_Resv1			EQU		0x28		; reserved
DCB_Size			EQU		0x30

MAX_DEV_OP			EQU		31

