/*
** USBHostPrinter_defs.h
**
** Copyright © 2009-2012 Future Technology Devices International Limited
**
** THIS SOFTWARE IS PROVIDED BY FUTURE TECHNOLOGY DEVICES INTERNATIONAL LIMITED
** ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
** TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
** PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL FUTURE TECHNOLOGY DEVICES
** INTERNATIONAL LIMITED BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
** EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
** OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
** INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
** STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
** OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
** DAMAGE.
**
** C Header file for Vinculum II Printer driver
** Main module
**
** Author: FTDI
** Project: Vinculum II
** Module: Vinculum II HID Driver
** Requires: VOS
** Comments:
**
** History:
**  1 – Initial version
**
*/
#ifndef USBHOSTHID_DEFS_H
#define USBHOSTHID_DEFS_H


// USBHID Context
//
// Holds a context structure required by each instance of the driver
typedef struct _usbHostHID_context_t
{
    // host controller handle
    VOS_HANDLE			 hc;
    usbhost_device_handle_ex ifDev;

    // Interface number
    uint8		 ifNumber;
    // Interface alt setting
    uint8		 altSetting;

    // endpoint handles
    usbhost_ep_handle_ex epCtrl;
    usbhost_ep_handle_ex epIntIn;
    usbhost_ep_handle_ex epIntOut;

    // max packet sizes of endpoints
    uint8 epIntInLength;
    uint8 epIntOutLength;

    // device ID pointer
    uint8 *deviceId;
} usbHostHID_context_t;

// open function
void usbHostHID_open();

// close function
void usbHostHID_close();

// read function
uint8 usbHostHID_read
(
    char *xfer,
    uint16 num_to_read,
    uint16 *num_read,
    usbHostHID_context_t *ctx
);

// write function
uint8 usbHostHID_write
    (int8 *xfer,
    uint16 num_to_write,
    uint16 *num_written,
    usbHostHID_context_t *ctx
    );

// USB Host IOCTL function
uint8 usbHostHID_ioctl(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx);

#endif                                 // USBHOSTHID_DEFS_H

