/*
** USBHostHID.c
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
** C Source file for Vinculum II HID driver
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

#include "vos.h"

#include "USB.h"
#include "USBHost.h"
#include "USBHID.h"
#include "USBHostHID.h"
#include "USBHostHID_defs.h"



/*
** Function: usbHostHID_init(uint8 vos_dev_num)
** Description: Register the device driver interface with the device manager.
** 			This API should be called first before accessing any functionality
** Parameters: vos_dev_num: device number assigned by the device manager
** Returns:	USBHOSTHID_OK: on success
**			USBHOSTHID_FATAL_ERROR: on failure
** Requirements:
** Comments:
*/
uint8 usbHostHID_init(uint8 vos_dev_num)
{
    vos_driver_t *usbHostHID_cb;
    usbHostHID_context_t *ctx;
    usbHostHID_cb = vos_malloc(sizeof(vos_driver_t));

    if (usbHostHID_cb == NULL)
        return USBHOSTHID_FATAL_ERROR;

    ctx = vos_malloc(sizeof(usbHostHID_context_t));

    if (ctx == NULL)
    {
        vos_free(usbHostHID_cb);
        return USBHOSTHID_FATAL_ERROR;
    }

    vos_memset(ctx, 0, sizeof(usbHostHID_context_t));

    // Set up function pointers for our driver
    usbHostHID_cb->flags = 0;
    usbHostHID_cb->read = usbHostHID_read;
    usbHostHID_cb->write = usbHostHID_write;
    usbHostHID_cb->ioctl = usbHostHID_ioctl;
    usbHostHID_cb->interrupt = (PF_INT) NULL;
    usbHostHID_cb->open = usbHostHID_open;
    usbHostHID_cb->close = usbHostHID_close;

    // OK - register with device manager
    vos_dev_init(vos_dev_num, usbHostHID_cb, ctx);

    return USBHOSTHID_OK;
}



/*
** Function: usbHostHID_open()
** Description: Opens USB Host HID device
** Parameters: None
** Returns:	None
** Requirements:
** Comments:
*/
void usbHostHID_open()
{
}



/*
** Function: usbHostHID_close()
** Description: Close the USB Host HID device
** Parameters: None
** Returns:	None
** Requirements:
** Comments:
*/
void usbHostHID_close()
{
}


/*
** Function: usbHostHID_read(int8 *buf, uint16 num_to_read, uint16 *num_read, usbHostHID_context_t *ctx)
** Description: Reads data from the INT IN endpoint
** Parameters: buf - data read buffer
**             num_to_read - number of bytes to read
**             num_read - number of actual bytes read
**			   ctx - driver context
** Returns:	USBHOST_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_read(int8 *buf, uint16 num_to_read, uint16 *num_read, usbHostHID_context_t *ctx)
{
    uint16 actual_read = 0;
    uint8 status = USBHOSTHID_NOT_FOUND;
    usbhost_xfer_t xfer;
    vos_semaphore_t s;

    if (ctx->hc)
    {
        // check for INT IN endpoint existing in a HID!
        if (ctx->epIntIn == NULL)
        {
            return status;
        }

        vos_init_semaphore(&s, 0);

        vos_memset(&xfer, 0, sizeof(usbhost_xfer_t));
        xfer.buf = buf;
        xfer.len = num_to_read;
        xfer.ep = ctx->epIntIn;
        xfer.s = &s;
        xfer.flags =  0;

        status = vos_dev_read(ctx->hc, (uint8 *) &xfer, sizeof(usbhost_xfer_t), NULL);

        if (status == USBHOST_OK)
        {
            status = USBHOSTHID_OK;
            actual_read = xfer.len;
        }
        else
        {
            status |= USBHOSTHID_USBHOST_ERROR;
        }
    }

    if (num_read)
    {
        *num_read = actual_read;
    }

    return status;
}


/*
** Function: usbHostHID_write(int8 *buf, uint16 num_to_read, uint16 *num_read, usbHostHID_context_t *ctx)
** Description: Writes data to the INT OUT endpoint
** Parameters: buf - data write buffer
**             num_to_write - number of bytes to write
**             num_write - number of actual bytes written
**			   ctx - driver context
** Returns:	USBHOST_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_write(int8 *buf, uint16 num_to_write, uint16 *num_written, usbHostHID_context_t *ctx)
{
    uint16 actual_written = 0;
    uint8 status = USBHOSTHID_NOT_FOUND;
    usbhost_xfer_t xfer;
    vos_semaphore_t s;

    if (ctx->hc)
    {
        // check for INT OUT endpoint existing in a HID!
        if (ctx->epIntOut == NULL)
        {
            return status;
        }

        vos_init_semaphore(&s, 0);

        vos_memset(&xfer, 0, sizeof(usbhost_xfer_t));
        xfer.buf = buf;
        xfer.len = num_to_write;
        xfer.ep = ctx->epIntOut;
        xfer.s = &s;
        xfer.flags =  0;

        status = vos_dev_write(ctx->hc, (uint8 *) &xfer, sizeof(usbhost_xfer_t), NULL);

        if (status == USBHOST_OK)
        {
            status = USBHOSTHID_OK;
            actual_written = xfer.len;
        }
        else
        {
            status |= USBHOSTHID_USBHOST_ERROR;
        }
    }

    if (num_written)
    {
        *num_written = actual_written;
    }

    return status;
}

/*
** Function: usbHostHID_attach(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
** Description: Attach a USB Host Handle to the USBHostHID  Driver
** Parameters: cb - USBHostHID ioctl block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_attach(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    usbHostHID_ioctl_cb_attach_t *atInfo;
    // ioctl request block
    usbhost_ioctl_cb_t hc_ioctl;
    // class information
    usbhost_ioctl_cb_class_t ifClass;
    // device information
    usbhost_ioctl_cb_dev_info_t ifInfo;
    // endpoint information
    usbhost_ioctl_cb_ep_info_t epInfo;
    uint8 status = USBHOSTHID_INVALID_PARAMETER;

    atInfo = cb->set.att;
    ctx->hc = atInfo->hc_handle;
    ctx->ifDev = atInfo->ifDev;


    // Check that we are a HID class interface!
    hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_GET_CLASS_INFO;
    hc_ioctl.handle.dif = ctx->ifDev;
    hc_ioctl.get = &ifClass;

    vos_dev_ioctl(ctx->hc, &hc_ioctl);

    if (ifClass.dev_class != USB_CLASS_HID)
    {
        return USBHOSTHID_NOT_FOUND;
    }

    do
    {
        // determine the interface number and alt setting of the device
        hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_GET_DEV_INFO;
        hc_ioctl.handle.dif = ctx->ifDev;
        hc_ioctl.get = &ifInfo;
        status = vos_dev_ioctl(ctx->hc, &hc_ioctl);

        ctx->ifNumber = ifInfo.interface_number;
        ctx->altSetting = ifInfo.alt;

        // user ioctl to find control endpoint on this device
        hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_GET_CONTROL_ENDPOINT_HANDLE;
        hc_ioctl.handle.dif = ctx->ifDev;
        hc_ioctl.get = &ctx->epCtrl;

        if (vos_dev_ioctl(ctx->hc, &hc_ioctl) != USBHOST_OK)
        {
            status = USBHOSTHID_NOT_FOUND;
            break;
        }

        // user ioctl to find INT IN endpoint on this device
        hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_GET_INT_IN_ENDPOINT_HANDLE;
        hc_ioctl.handle.dif = ctx->ifDev;
        hc_ioctl.get = &ctx->epIntIn;

        if (vos_dev_ioctl(ctx->hc, &hc_ioctl) != USBHOST_OK)
        {
            status = USBHOSTHID_NOT_FOUND;
            break;
        }

        // user ioctl to find interrupt endpoint information on this device
        hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_GET_ENDPOINT_INFO;
        hc_ioctl.handle.ep = ctx->epIntIn;
        hc_ioctl.get = &epInfo;

        status = vos_dev_ioctl(ctx->hc, &hc_ioctl);

        if (status != USBHOST_OK)
        {
            status = USBHOSTHID_NOT_FOUND;
            break;
        }
        
        ctx->epIntInLength = epInfo.max_size;

        // user ioctl to find INT OUT endpoint on this device
        hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_GET_INT_OUT_ENDPOINT_HANDLE;
        hc_ioctl.handle.dif = ctx->ifDev;
        hc_ioctl.get = &ctx->epIntOut;

        status = vos_dev_ioctl(ctx->hc, &hc_ioctl);
        
        if (status != USBHOST_OK)
        {
            // do not need this endpoint
            status = USBHOSTHID_OK;
            ctx->epIntOut = 0;
            break;
        }

        // user ioctl to find interrupt endpoint information on this device
        hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_GET_ENDPOINT_INFO;
        hc_ioctl.handle.ep = ctx->epIntOut;
        hc_ioctl.get = &epInfo;

        status = vos_dev_ioctl(ctx->hc, &hc_ioctl);

        if (status != USBHOST_OK)
        {
            status = USBHOSTHID_NOT_FOUND;
            break;
        }
        
        ctx->epIntOutLength = epInfo.max_size;

        status = USBHOSTHID_OK;
    }
    while (0);

    return status;
}


/*
** Function: usbHostHID_detach(usbHostHID_context_t *ctx)
** Description: Detach the USB Host handle
** Parameters: ctx - driver context
** Returns:	None
** Requirements:
** Comments:
*/
void usbHostHID_detach(usbHostHID_context_t *ctx)
{
    // remove link to host controller and endpoints
    ctx->hc = NULL;
    ctx->epCtrl = NULL;
    ctx->epIntIn = NULL;

    // free the device ID string storage if it's been used
    if (ctx->deviceId != NULL)
    {
        vos_free(ctx->deviceId);
        ctx->deviceId = NULL;
    }
}


/*
** Function: usbHostHID_hc_setup
** Description: Sends a setup transfer to USB Host
** Parameters: hc - USB Host handle
**             desc_dev -  USB setup packet
**             data - data received from the USB Host controller
**			   ep - USB device endpoint
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_hc_setup(VOS_HANDLE hc, usb_deviceRequest_t *desc_dev, uint8 *data, usbhost_ep_handle_ex ep)
{
    // ioctl request block
    usbhost_ioctl_cb_t hc_ioctl;

    hc_ioctl.ioctl_code = VOS_IOCTL_USBHOST_DEVICE_SETUP_TRANSFER;
    hc_ioctl.handle.ep = ep;
    hc_ioctl.set = desc_dev;
    hc_ioctl.get = data;
    return vos_dev_ioctl(hc, &hc_ioctl);
}


/*
** Function: usbHostHID_ioctl_get_descriptor
** Description: Get the HID descriptor
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl_get_descriptor(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    // setup transfer descriptor
    usb_deviceRequest_t desc_dev;

    desc_dev.bmRequestType = USB_BMREQUESTTYPE_DEV_TO_HOST |
                                USB_BMREQUESTTYPE_INTERFACE;
    desc_dev.bRequest = USB_REQUEST_CODE_GET_DESCRIPTOR;
    desc_dev.wValue = (cb->descriptorType << 8) | cb->descriptorIndex;
    desc_dev.wIndex = ctx->ifNumber;
    desc_dev.wLength = cb->Length;

    return usbHostHID_hc_setup(ctx->hc, &desc_dev, cb->get.data, ctx->epCtrl);
}


/*
** Function: usbHostHID_ioctl_get_report
** Description: Get the HID report
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl_get_report(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    // setup transfer descriptor
    usb_deviceRequest_t desc_dev;

    desc_dev.bmRequestType = USB_BMREQUESTTYPE_DEV_TO_HOST |
        USB_BMREQUESTTYPE_CLASS |
        USB_BMREQUESTTYPE_INTERFACE;
    desc_dev.bRequest = USB_HID_REQUEST_CODE_GET_REPORT;
    desc_dev.wValue = (cb->reportType << 8) | cb->reportID;
    desc_dev.wIndex = ctx->ifNumber;
    desc_dev.wLength = cb->Length;

    return usbHostHID_hc_setup(ctx->hc, &desc_dev, cb->get.data, ctx->epCtrl);
}


/*
** Function: usbHostHID_ioctl_get_idle
** Description: Get the HID idle duration
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl_get_idle(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    // setup transfer descriptor
    usb_deviceRequest_t desc_dev;

    desc_dev.bmRequestType = USB_BMREQUESTTYPE_DEV_TO_HOST |
        USB_BMREQUESTTYPE_CLASS |
        USB_BMREQUESTTYPE_INTERFACE;
    desc_dev.bRequest = USB_HID_REQUEST_CODE_GET_IDLE;
    desc_dev.wValue = cb->reportID;
    desc_dev.wIndex = ctx->ifNumber;
    desc_dev.wLength = 1;

    return usbHostHID_hc_setup(ctx->hc, &desc_dev, cb->get.data, ctx->epCtrl);
}


/*
** Function: usbHostHID_ioctl_get_protocol
** Description: Get the HID protocol
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl_get_protocol(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    // setup transfer descriptor
    usb_deviceRequest_t desc_dev;

    desc_dev.bmRequestType = USB_BMREQUESTTYPE_DEV_TO_HOST |
        USB_BMREQUESTTYPE_CLASS |
        USB_BMREQUESTTYPE_INTERFACE;
    desc_dev.bRequest = USB_HID_REQUEST_CODE_GET_PROTOCOL;
    desc_dev.wValue = 0;
    desc_dev.wIndex = ctx->ifNumber;
    desc_dev.wLength = 1;

    return usbHostHID_hc_setup(ctx->hc, &desc_dev, cb->get.data, ctx->epCtrl);
}


/*
** Function: usbHostHID_ioctl_set_report
** Description: Set the HID report
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl_set_report(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    // setup transfer descriptor
    usb_deviceRequest_t desc_dev;

    desc_dev.bmRequestType = USB_BMREQUESTTYPE_HOST_TO_DEV |
        USB_BMREQUESTTYPE_CLASS |
        USB_BMREQUESTTYPE_INTERFACE;
    desc_dev.bRequest = USB_HID_REQUEST_CODE_SET_REPORT;
    desc_dev.wValue = (cb->reportType << 8) | cb->reportID;
    desc_dev.wIndex = ctx->ifNumber;
    desc_dev.wLength = cb->Length;

    return usbHostHID_hc_setup(ctx->hc, &desc_dev, cb->set.data, ctx->epCtrl);
}


/*
** Function: usbHostHID_ioctl_set_idle
** Description: Set the HID idle duration
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl_set_idle(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    // setup transfer descriptor
    usb_deviceRequest_t desc_dev;

    desc_dev.bmRequestType = USB_BMREQUESTTYPE_HOST_TO_DEV |
        USB_BMREQUESTTYPE_CLASS |
        USB_BMREQUESTTYPE_INTERFACE;
    desc_dev.bRequest = USB_HID_REQUEST_CODE_SET_IDLE;
    desc_dev.wValue = (cb->idleDuration << 8) | cb->reportID;
    desc_dev.wIndex = ctx->ifNumber;
    desc_dev.wLength = 0;

    return usbHostHID_hc_setup(ctx->hc, &desc_dev, cb->set.data, ctx->epCtrl);
}


/*
** Function: usbHostHID_ioctl_set_protocol
** Description: Set the HID protocol
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl_set_protocol(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    // setup transfer descriptor
    usb_deviceRequest_t desc_dev;

    desc_dev.bmRequestType = USB_BMREQUESTTYPE_HOST_TO_DEV |
        USB_BMREQUESTTYPE_CLASS |
        USB_BMREQUESTTYPE_INTERFACE;
    desc_dev.bRequest = USB_HID_REQUEST_CODE_SET_PROTOCOL;
    desc_dev.wValue = cb->protocolType;
    desc_dev.wIndex = ctx->ifNumber;
    desc_dev.wLength = 0;

    return usbHostHID_hc_setup(ctx->hc, &desc_dev, cb->set.data, ctx->epCtrl);
}


/*
** Function: usbHostHID_ioctl
** Description: Handle the driver IOCTLs
** Parameters: cb - ioctl command block
**             ctx - driver context
** Returns:	USBHOSTHID_OK - on success
** Requirements:
** Comments:
*/
uint8 usbHostHID_ioctl(usbHostHID_ioctl_t *cb, usbHostHID_context_t *ctx)
{
    uint8 status = USBHOSTHID_INVALID_PARAMETER;

    switch (cb->ioctl_code)
    {
    case VOS_IOCTL_USBHOSTHID_ATTACH:
        status = usbHostHID_attach(cb, ctx);
        break;

    case VOS_IOCTL_USBHOSTHID_DETACH:
        usbHostHID_detach(ctx);
        status = USBHOSTHID_OK;
        break;

    case VOS_IOCTL_USBHOSTHID_GET_PROTOCOL:
        status = usbHostHID_ioctl_get_protocol(cb, ctx);
        break;

    case VOS_IOCTL_USBHOSTHID_SET_PROTOCOL:
        status = usbHostHID_ioctl_set_protocol(cb, ctx);
        break;


    case VOS_IOCTL_USBHOSTHID_GET_REPORT:
        status = usbHostHID_ioctl_get_report(cb, ctx);
        break;

    case VOS_IOCTL_USBHOSTHID_SET_REPORT:
        status = usbHostHID_ioctl_set_report(cb, ctx);
        break;

    case VOS_IOCTL_USBHOSTHID_GET_IDLE:
        status = usbHostHID_ioctl_get_idle(cb, ctx);
        break;

    case VOS_IOCTL_USBHOSTHID_SET_IDLE:
        status = usbHostHID_ioctl_set_idle(cb, ctx);
        break;

    case VOS_IOCTL_USBHOSTHID_GET_DESCRIPTOR:
        status = usbHostHID_ioctl_get_descriptor(cb, ctx);
        break;

    case VOS_IOCTL_USBHOSTHID_GET_IN_REPORT_SIZE:
        cb->Length = ctx->epIntInLength;
        status = USBHOSTHID_OK;
        break;

    case VOS_IOCTL_USBHOSTHID_GET_OUT_REPORT_SIZE:
        cb->Length = ctx->epIntOutLength;
        status = USBHOSTHID_OK;
        break;

    default:
        break;
    }

    return status;
}

