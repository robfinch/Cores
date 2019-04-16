#include "gfx.h"
#include "gfx_regs.h"

#define GFX_STAT_COUNT_OFFSET 16
#define GFX_INSTRUCTION_FIFO_SIZE 128

#define SUBPIXEL_WIDTH 16

#define FB_BASEADDR   0xFFDC5000 /* Bus Adress to frame buffer */

#define FB_CTRL       	(FB_BASEADDR + 0x000) /* Control Register */
//#define VGA_STAT       (VGA_BASEADDR + 0x004) /* Status Register */
#define FB_REFDELAY     (FB_BASEADDR + 0x002)
#define FB_VBARA      	(FB_BASEADDR + 0x010) /* Adress to Video Base Register A */
#define FB_VBARB      	(FB_BASEADDR + 0x018) /* Adress to Video Base Register B */
#define FB_PALETTE     (FB_BASEADDR + 0x800) /* Color Palette */
#define FB_PXYZ        (FB_BASEADDR + 0x020)
#define FB_PCOLCMD     (FB_BASEADDR + 0x028)
#define FB_BMPSIZE			(FB_BASEADDR + 0x068)
#define FB_WINDOW 	    (FB_BASEADDR + 0x078)
//#define BMP_NUMFETCHES (VGA_BASEADDR + 0x034)

#define FB_STAT_AVMP 16
#define FB_HRES      16
#define FB_VRES      20
#define FB_CTRL_CD4		0x00000000
#define FB_CTRL_CD8   0x00000100
#define FB_CTRL_CD12  0x00000200
#define FB_CTRL_CD16  0x00000300 /* Color Depth 16 */
#define FB_CTRL_CD20  0x00000400 /* Color Depth 25 */
#define FB_CTRL_CD32  0x00000700 /* Color Depth 32 */
#define FB_CTRL_VBSWE 0x00000020 /* Bank switch enable */

// Generate bits from orgfx_regs.h

/* ===================== */
/* Control register bits */
/* ===================== */
#define GFX_CTRL_CD4				 (0 << GFX_CTRL_COLOR_DEPTH    ) /* Color depth 4              */
#define GFX_CTRL_CD8         (1 << GFX_CTRL_COLOR_DEPTH    ) /* Color Depth 8              */
#define GFX_CTRL_CD12        (2 << GFX_CTRL_COLOR_DEPTH    ) /* Color Depth 12             */
#define GFX_CTRL_CD16        (3 << GFX_CTRL_COLOR_DEPTH    ) /* Color Depth 16             */
#define GFX_CTRL_CD20        (4 << GFX_CTRL_COLOR_DEPTH    ) /* Color Depth 20             */ // Not supported!
#define GFX_CTRL_CD32        (7 << GFX_CTRL_COLOR_DEPTH    ) /* Color Depth 32             */
#define GFX_CTRL_CDMASK      (15 << GFX_CTRL_COLOR_DEPTH    ) /* All color depth bits       */

#define GFX_TEXTURE_ENABLE   (1 << GFX_CTRL_TEXTURE        ) /* Enable Texture Reads       */
#define GFX_BLEND_ENABLE     (1 << GFX_CTRL_BLENDING       ) /* Enable Alpha Blending      */
#define GFX_COLORKEY_ENABLE  (1 << GFX_CTRL_COLORKEY       ) /* Enable Colorkeying         */
#define GFX_CLIPPING_ENABLE  (1 << GFX_CTRL_CLIPPING       ) /* Enable Clipping/Scissoring */
#define GFX_ZBUFFER_ENABLE   (1 << GFX_CTRL_ZBUFFER        ) /* Enable depth buffer        */

#define GFX_POINT            (1 << GFX_CTRL_POINT          ) // Put point
#define GFX_RECT             (1 << GFX_CTRL_RECT           ) /* Put rect                   */
#define GFX_LINE             (1 << GFX_CTRL_LINE           ) /* Put line                   */
#define GFX_TRI              (1 << GFX_CTRL_TRI            ) /* Put triangle               */

#define GFX_CURVE            (1 << GFX_CTRL_CURVE          ) /* Put curve                  */
#define GFX_INTERP           (1 << GFX_CTRL_INTERP         ) /* Activate interpolation     */
#define GFX_INSIDE           (1 << GFX_CTRL_INSIDE         ) /* Bezier inside/outside      */

#define GFX_ACTIVE_POINT0    0                               /* Set the active point to p0 */
#define GFX_ACTIVE_POINT1    (1 << GFX_CTRL_ACTIVE_POINT   ) /* Set the active point to p1 */
#define GFX_ACTIVE_POINT2    (2 << GFX_CTRL_ACTIVE_POINT   ) /* Set the active point to p2 */
#define GFX_ACTIVE_POINTMASK (3 << GFX_CTRL_ACTIVE_POINT   )
#define GFX_FORWARD_POINT    (1 << GFX_CTRL_FORWARD_POINT  ) /* Forward the active point   */
#define GFX_TRANSFORM_POINT  (1 << GFX_CTRL_TRANSFORM_POINT) /* Transform the active point */

#define GFX_PIXEL0     0x008
#define GFX_PIXEL1     0x00c
#define GFX_COLOR      0x010

/* ==================== */
/* Status register bits */
/* ==================== */
#define GFX_BUSY        (1 << GFX_STAT_BUSY           ) /* Ready for op */


/* Register access macros */
#define REG8(add)  *((volatile unsigned __int8  *)(add))
#define REG16(add) *((volatile unsigned __int16 *)(add))
#define REG32(add) *((volatile unsigned __int32 *)(add))
#define REG64(add) *((volatile unsigned __int64 *)(add))

void LEDSTAT(register int val)
{
	__asm {
		sb		$a0,LEDS
	}
}

// Wait until req_spaces number of places in the instruction fifo are clear
pascal void gfx_wait(unsigned int reg_spaces)
{
	int stat;

//  while( in64(GFX_STATUS) & GFX_BUSY );
	do {
		stat = in64(GFX_STATUS) >> GFX_STAT_COUNT_OFFSET;
		LEDS(stat);
	}
  while( stat + reg_spaces > GFX_INSTRUCTION_FIFO_SIZE);
}

unsigned int memory_base = GFX_VMEM;
struct gfx_surface* target_surface = 0;
struct gfx_surface* tex0_surface = 0;
struct gfx_surface* zbuffer_surface = 0;
unsigned int gfx_control_reg_memory = 0;
int gfx_pen_color = 0;

// Forward or transform points?
unsigned int transformation_mode = GFX_FORWARD_POINT;

inline void gfx_set_colordepth(unsigned char bpp);
/*
void Set390x256x12_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0x800;
    REG32(BMP_VSCALE) = 0x555;
    REG32(BMP_FETCHPERIOD) = 78;  // 83
    REG32(BMP_NUMFETCHES) = 9984;
    REG32(VGA_HDISPLAYED) = 390;
    REG32(VGA_VDISPLAYED) = 256;
    REG32(GFX_TARGET_SIZE_X) = 390;
    REG32(GFX_TARGET_SIZE_Y) = 256;
}

void Set392x256x16_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0x800;
    REG32(BMP_VSCALE) = 0x555;
    REG32(BMP_FETCHPERIOD) = 61;   // 66
    REG32(BMP_NUMFETCHES) = 12544;
    REG32(VGA_HDISPLAYED) = 392;
    REG32(VGA_VDISPLAYED) = 256;
    REG32(GFX_TARGET_SIZE_X) = 392;
    REG32(GFX_TARGET_SIZE_Y) = 256;
}
*/
void gfx_Set400x300x16_60(void)
{
	out64(FB_REFDELAY,(0xFFF3<<16)|(0xFF99<<0));	
  out64(FB_WINDOW,(300<<16)|400);
  out64(FB_VBARA,0x200000);
  out64(FB_VBARB,0x280000);
  out64(FB_CTRL,(2<<FB_HRES)|(2<<FB_VRES)|FB_CTRL_CD16|1|(0<<48));   // 66
  out64(FB_BMPSIZE,(300 << 32)|400);
  gfx_wait(7);
  out64(GFX_TARGET_BASE,0x200000);
  out64(GFX_TARGET_SIZE_X,400);
  out64(GFX_TARGET_SIZE_Y,300);
  out64(GFX_TARGET_X0,0);
  out64(GFX_TARGET_Y0,0);
  out64(GFX_TARGET_X1,400);
  out64(GFX_TARGET_Y1,300);
}

void gfx_Set800x600x16_60(void)
{
	out64(FB_REFDELAY,(0xFFEA<<16)|(0xFF31<<0));	
  out64(FB_WINDOW,(600<<16)|800);
  out64(FB_VBARA,0x200000);
  out64(FB_VBARB,0x300000);
  out64(FB_CTRL,(1<<FB_HRES)|(1<<FB_VRES)|FB_CTRL_CD16|1|(0<<48));   // 66
  out64(FB_BMPSIZE,(600 << 32)|800);
  gfx_wait(7);
  out64(GFX_TARGET_BASE,0x200000);
  out64(GFX_TARGET_SIZE_X,800);
  out64(GFX_TARGET_SIZE_Y,600);
  out64(GFX_TARGET_X0,0);
  out64(GFX_TARGET_Y0,0);
  out64(GFX_TARGET_X1,800);
  out64(GFX_TARGET_Y1,600);
}

// These configs for a 42,xx MHz dot clock
/*
void Set450x256_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0xAAA;
    REG32(BMP_VSCALE) = 0x555;
    REG32(BMP_FETCHPERIOD) = 40;
    REG32(BMP_NUMFETCHES) = 11519;
    REG32(VGA_HDISPLAYED) = 450;
    REG32(VGA_VDISPLAYED) = 256;
    REG32(GFX_TARGET_SIZE_X) = 450;
    REG32(GFX_TARGET_SIZE_Y) = 256;
}

void Set448x256x16_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0xAAA;
    REG32(BMP_VSCALE) = 0x555;
    REG32(BMP_FETCHPERIOD) = 53;
    REG32(BMP_NUMFETCHES) = 14336;
    REG32(VGA_HDISPLAYED) = 448;
    REG32(VGA_VDISPLAYED) = 256;
    REG32(GFX_TARGET_SIZE_X) = 448;
    REG32(GFX_TARGET_SIZE_Y) = 256;
}

void Set336x256x8_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0x800;
    REG32(BMP_VSCALE) = 0x555;
    REG32(BMP_FETCHPERIOD) = 150;
    REG32(BMP_NUMFETCHES) = 5375;
    REG32(VGA_HDISPLAYED) = 336;
    REG32(VGA_VDISPLAYED) = 256;
    REG32(GFX_TARGET_SIZE_X) = 336;
    REG32(GFX_TARGET_SIZE_Y) = 256;
}

void Set336x256x16_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0x800;
    REG32(BMP_VSCALE) = 0x555;
    REG32(BMP_FETCHPERIOD) = 72;
    REG32(BMP_NUMFETCHES) = 10752;
    REG32(VGA_HDISPLAYED) = 336;
    REG32(VGA_VDISPLAYED) = 256;
    REG32(GFX_TARGET_SIZE_X) = 336;
    REG32(GFX_TARGET_SIZE_Y) = 256;
}

void Set340x256x12_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0x800;
    REG32(BMP_VSCALE) = 0x555;
    REG32(BMP_FETCHPERIOD) = 90;
    REG32(BMP_NUMFETCHES) = 8703;
    REG32(VGA_HDISPLAYED) = 340;
    REG32(VGA_VDISPLAYED) = 256;
    REG32(GFX_TARGET_SIZE_X) = 340;
    REG32(GFX_TARGET_SIZE_Y) = 256;
}

// Sample calc's
// 16 pixels fit into 1 128 bit memory strip
// 672 pixels = 42x16 so 42 memory strips
// 42 * 384 pixel rows = 16128 fetches per screen
// 16128 fetches in 60 Hz =
// 0.0166666 / 16128 = 1.0333us per fetch
// 1.033us @ 50MHz memory clock rate = 51.67 clock cycles.
// To be safe we round down to 50 clock cycles.

void Set672x384x8_60(void)
{
    gfx_wait(2);
    REG32(BMP_HSCALE) = 0x1000;
    REG32(BMP_VSCALE) = 0x0800;
    REG32(BMP_FETCHPERIOD) = 50;        // number of 50MHz clocks per fetch
    REG32(BMP_NUMFETCHES) = 16127;
    REG32(VGA_HDISPLAYED) = 680;
    REG32(VGA_VDISPLAYED) = 384;
    REG32(GFX_TARGET_SIZE_X) = 680;
    REG32(GFX_TARGET_SIZE_Y) = 384;
}
*/

// Sample calc's
// 16 pixels fit into 1 128 bit memory strip
// 1344 pixels = 84x16 so 84 memory strips
// 84 * 768 pixel rows = 64512 fetches per screen
// 64512 fetches in 60 Hz =
// 0.0166666 / 64512 = 258ns per fetch
// 1.033us @ 50MHz memory clock rate = 12.9 clock cycles.
// To be safe we round down to 10 clock cycles.
// Since it takes a number of clock cycles to access memory this would be
// about the max that could be supported. However, the video buffer is only
// 256 kbytes and 1344x768 would require a megabyte buffer. Also this mode 
// would use virtually 100% of the available memory bandwidth, meaning there
// would be none left for the CPU(s), GFX accelerator etc.


pascal void gfx_init(unsigned int memoryArea)
{
    memory_base = memoryArea;

    // Reset VGA+GFX first
//    REG32(VGA_CTRL) = 0;

    gfx_control_reg_memory = 0;
    gfx_wait(2);
    out64(GFX_CONTROL, gfx_control_reg_memory);

    gfx_vga_set_vbara(memory_base);
    gfx_vga_set_vbarb(memory_base);

    out64(GFX_TARGET_BASE, memory_base);
}

inline void gfx_vga_set_vbara(unsigned int addr)
{
    // Set base address for Video Base Register A
    out64(FB_VBARA, addr);
}

inline void gfx_vga_set_vbarb(unsigned int addr)
{
    // Set base address for Video Base Register B
    out64(FB_VBARB, addr);
}

inline void gfx_vga_bank_switch()
{
    gfx_wait(GFX_INSTRUCTION_FIFO_SIZE);
//    REG32(VGA_CTRL) |= VGA_CTRL_VBSWE;
}


inline unsigned int gfx_vga_AVMP()
{
    // Get the active memory page bit
//    unsigned int status_reg = REG32(VGA_STAT);
//    status_reg = status_reg >> VGA_STAT_AVMP;
//    return status_reg & 1;
	return (0);
}

void gfx_set_colordepth(unsigned char bpp)
{
    unsigned int vga_bpp = 0, gfx_bpp = 0;
    int vga_ctrl;
    switch(bpp)
    {
    case 8:  vga_bpp = FB_CTRL_CD8;  gfx_bpp = GFX_CTRL_CD8;  break;
    case 12: vga_bpp = FB_CTRL_CD12; gfx_bpp = GFX_CTRL_CD12; break;
    case 16: vga_bpp = FB_CTRL_CD16; gfx_bpp = GFX_CTRL_CD16; break;
        //	case 24: vga_bpp = VGA_CTRL_CD24; gfx_bpp = GFX_CTRL_CD24; break; // Unsupported by gfx
    case 32: vga_bpp = FB_CTRL_CD32; gfx_bpp = GFX_CTRL_CD32; break;
    default: break;
    }

    vga_ctrl = in64(FB_CTRL);
    vga_ctrl &= ~0xF00;
    vga_ctrl |= vga_bpp;
    out64(FB_CTRL,vga_ctrl);
    gfx_control_reg_memory &= ~GFX_CTRL_CDMASK;
    gfx_control_reg_memory |= gfx_bpp;
    gfx_wait(1);
    out64(GFX_CONTROL, gfx_control_reg_memory);
}

void gfx_set_videomode(unsigned int width, unsigned int height, unsigned char bpp)
{
	if (width==400 && height==300 && bpp==16)
		gfx_Set400x300x16_60();
	if (width==800 && height==600 && bpp==16)
		gfx_Set800x600x16_60();
/*
    else if(width == 392 && height == 256 && bpp==16)
        Set392x256x16_60();
    else if(width == 392 && height == 256 && bpp==18)
        Set392x256x18_60();
    else if(width == 390 && height == 256)
        Set390x256x12_60();
    else
        Set392x256x16_60();
*/
     /*
    if(width == 450 && height == 256)
        Set450x256_60();
    else if(width == 340 && height == 256 && bpp==12)
        Set340x256x12_60();
    else if(width == 672 && height == 384 && bpp==8)
        Set672x384x8_60();
    else if(width == 336 && height == 256 && bpp==8)
        Set336x256x8_60();
    else if(width == 336 && height == 256 && bpp==16)
        Set336x256x16_60();
    else if(width == 336 && height == 256 && bpp==15)
        Set336x256x16_60();
    else if(width == 448 && height == 256 && (bpp==16||bpp==15))
        Set448x256x16_60();
    else // Default mode
        Set340x256x12_60();
    */
    gfx_set_colordepth(bpp);
}

struct gfx_surface *gfx_init_surface(struct gfx_surface *surface, unsigned int width, unsigned int height)
{
    surface->addr = memory_base;
    surface->w = width;
    surface->h = height;
    memory_base += (width << 1) * height; // TODO: Only true for 16 bit surfaces!
    return surface;
}

void gfx_bind_rendertarget(struct gfx_surface *surface)
{
    target_surface = surface;
    gfx_wait(3);
    out64(GFX_TARGET_BASE, surface->addr);
    out64(GFX_TARGET_SIZE_X, surface->w);
    out64(GFX_TARGET_SIZE_Y, surface->h);
    // Clear clip rect
    gfx_cliprect(0,0,surface->w,surface->h);
}

void gfx_enable_zbuffer(unsigned int enable)
{
    if(enable)
        gfx_control_reg_memory |= GFX_ZBUFFER_ENABLE;
    else
        gfx_control_reg_memory &= ~GFX_ZBUFFER_ENABLE;

    gfx_wait(1);
    out64(GFX_CONTROL, gfx_control_reg_memory);
}

void gfx_bind_zbuffer(struct gfx_surface *surface)
{
    zbuffer_surface = surface;
    gfx_wait(1);
    out64(GFX_ZBUFFER_BASE, surface->addr);
}

void gfx_clear_zbuffer()
{
    int y, x;
    for(y = 0; y < zbuffer_surface->h; ++y)
    {
        for(x = 0; x < zbuffer_surface->w; x+=2)
        {
            int addr = (y*zbuffer_surface->w + x)*2; // TODO: only works for 16bits
            out16(zbuffer_surface->addr+addr, 0x8000);
        }
    }
}

void gfx_enable_cliprect(unsigned int enable)
{
    if(enable)
        gfx_control_reg_memory |= GFX_CLIPPING_ENABLE;
    else
        gfx_control_reg_memory &= ~GFX_CLIPPING_ENABLE;

    gfx_wait(1);
    out64(GFX_CONTROL, gfx_control_reg_memory);
}

void gfx_cliprect(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1)
{
    gfx_wait(4);
    out64(GFX_CLIP_PIXEL0_X, x0);
    out64(GFX_CLIP_PIXEL0_Y, y0);
    out64(GFX_CLIP_PIXEL1_X, x1);
    out64(GFX_CLIP_PIXEL1_Y, y1);
}

void gfx_srcrect(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1)
{
    gfx_wait(4);
    out64(GFX_SRC_PIXEL0_X, x0);
    out64(GFX_SRC_PIXEL0_Y, y0);
    out64(GFX_SRC_PIXEL1_X, x1);
    out64(GFX_SRC_PIXEL1_Y, y1);
}

void gfx_init_src()
{
    if((gfx_control_reg_memory & GFX_TEXTURE_ENABLE) && tex0_surface)
        gfx_srcrect(0, 0, tex0_surface->w, tex0_surface->h);
    else if(target_surface)
        gfx_srcrect(0, 0, target_surface->w, target_surface->h);
}

/*
void gfx_set_pixel(int x, int y, unsigned int color)
{
    int stripx,stripy;
    int addr;
    int dat;
    int mask;

    if(x >= 0 && y >= 0)
    {
        stripx = x / 5; 
        stripy = y * 68;
        addr = (stripy + stripx) << 3;
        mask = 0xFFF << ((x % 5) * 12);
        dat = REG64(target_surface->addr+addr);
        dat &= ~mask;
        dat |= color << ((x % 5) * 12);
        REG64(target_surface->addr+addr) = dat;
    }
}
*/
pascal void gfx_set_pixel(int x, int y, int color)
{
    unsigned int stat;

    gfx_wait(1);
    gfx_set_color(color);
    do {
    	stat = in64(FB_PCOLCMD);
    } while (stat & 3);
    out64(FB_PXYZ,(y<<16)|x);
    out64(FB_PCOLCMD,(color<<32)|(1 << 16)|1);
    /*
    REG32(GFX_DEST_PIXEL_X) = x;
    REG32(GFX_DEST_PIXEL_Y) = y;
    REG32(GFX_CONTROL) = gfx_control_reg_memory | GFX_ACTIVE_POINT0 | transformation_mode;
    REG32(GFX_CONTROL) = gfx_control_reg_memory | GFX_POINT;
    */
/*
    do {
        stat = ((unsigned)REG32(BMP_XY) >> 30);
    } while (stat != 0);    
    REG32(BMP_XY) = 0x80000000 | y | (x >> 16);
*/
}

pascal void gfx_get_pixel(int x, int y, int *color)
{
    unsigned int stat;

    if (color==0)
       return;
    out64(FB_PXYZ,(y<<16)|x);
    out64(FB_PCOLCMD,(1 << 16)|2);
    do {
    	stat = in64(FB_PCOLCMD);
    } while (stat & 3);
    *color = stat >> 32;
    /*
    do {
        stat = REG32(BMP_XY) >> 30;
    } while (stat != 0);    
    REG32(BMP_XY) = 0x40000000 | y | (x >> 16);
    do {
        stat = REG32(BMP_XY) >> 30;
    } while (stat != 0);    
    *color = REG32(BMP_COLOR);
    */
}

// Copies a buffer into the current render target
void gfx_memcpy(unsigned int *mem, unsigned int size)
{
    unsigned int i;
    int *adr;

		adr = (int *)(target_surface->addr);
    for(i=0; i < size; ++i)
        adr[i] = mem[i];
}

void gfx_set_color(unsigned int color)
{
	unsigned int pcolcmd;

    gfx_wait(1);
    pcolcmd = in64(FB_PCOLCMD);
    out64(FB_PCOLCMD, (color<<32)|(pcolcmd & 0xFFFFFFFF));
    out64(GFX_COLOR0, color);
    gfx_pen_color = color;
}


void gfx_set_colors(unsigned int color0, unsigned int color1, unsigned int color2)
{
    gfx_wait(3);
    out64(GFX_COLOR0, color0);
    out64(GFX_COLOR1, color1);
    out64(GFX_COLOR2, color2);
}

pascal void gfx_solid_rect(int x0, int y0, int x1, int y1)
{
    gfx_wait(7);
    out64(GFX_DEST_PIXEL_X, x0);
    out64(GFX_DEST_PIXEL_Y, y0);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT0 | transformation_mode);
    out64(GFX_DEST_PIXEL_X, x1);
    out64(GFX_DEST_PIXEL_Y, y1);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT1 | transformation_mode);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_RECT);
}

pascal void gfx_line(int x0, int y0, int x1, int y1)
{
    gfx_line3d(x0, y0, 0, x1, y1, 0);
}

pascal void gfx_triangle(int x0, int y0,
                     int x1, int y1,
                     int x2, int y2)
{
    gfx_line(x0,y0,x1,y1);
    gfx_line(x1,y1,x2,y2);
    gfx_line(x2,y2,x0,y0);
}

void gfx_polyline(int sides, gfx_point2i *pts)
{
     int nn;
     int x0,y0,x1,y1;     

     x0 = pts[0].x;
     y0 = pts[0].y;
     for (nn = 1; nn < sides; nn++) {
         x1 = pts[nn].x;
         y1 = pts[nn].y;
         gfx_line(x0,y0,x1,y1);
         x0 = x1;
         y0 = y1;
     }
}

void gfx_polygon(int sides, gfx_point2i *pts)
{
     int nn;
     int *q;
     int x0, y0, x1, y1, ox0,oy0;     
     q = &y0 + 1;

     x0 = pts[0].x;
     y0 = pts[0].y;
     ox0 = x0; oy0 = y0;
     for (nn = 1; nn < sides; nn++) {
         x1 = pts[nn].x;
         y1 = pts[nn].y;
         gfx_line(x0,y0,x1,y1);
         x0 = x1;
         y0 = y1;
     }
     gfx_line(x0,y0,ox0,oy0);
}

void gfx_solid_triangle(int x0, int y0,
                     int x1, int y1,
                     int x2, int y2,
                     unsigned int interpolate)
{
    gfx_triangle3d(x0, y0, 0, x1, y1, 0, x2, y2, 0, interpolate);
}

void gfx_curve(int x0, int y0,
                  int x1, int y1,
                  int x2, int y2,
                  unsigned int inside)
{
    gfx_wait(11);
    out64(GFX_DEST_PIXEL_Z, 0); // Set all points depth value to zero

    out64(GFX_DEST_PIXEL_X, x0);
    out64(GFX_DEST_PIXEL_Y, y0);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT0 | transformation_mode);
    out64(GFX_DEST_PIXEL_X, x1);
    out64(GFX_DEST_PIXEL_Y, y1);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT1 | transformation_mode);
    out64(GFX_DEST_PIXEL_X, x2);
    out64(GFX_DEST_PIXEL_Y, y2);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT2 | transformation_mode);

    if(inside)
        gfx_control_reg_memory |= GFX_INSIDE;
    else
        gfx_control_reg_memory &= ~GFX_INSIDE;

    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_CURVE | GFX_TRI | GFX_INTERP;
}

void gfx_triangle3d(int x0, int y0, int z0,
                       int x1, int y1, int z1,
                       int x2, int y2, int z2,
                       unsigned int interpolate)
{
    gfx_wait(13);
    out64(GFX_DEST_PIXEL_X, x0);
    out64(GFX_DEST_PIXEL_Y, y0);
    out64(GFX_DEST_PIXEL_Z, z0);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT0 | transformation_mode);
    out64(GFX_DEST_PIXEL_X, x1);
    out64(GFX_DEST_PIXEL_Y, y1);
    out64(GFX_DEST_PIXEL_Z, z1);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT1 | transformation_mode);
    out64(GFX_DEST_PIXEL_X, x2);
    out64(GFX_DEST_PIXEL_Y, y2);
    out64(GFX_DEST_PIXEL_Z, z2);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT2 | transformation_mode);

    if(interpolate)
        out64(GFX_CONTROL, gfx_control_reg_memory | GFX_TRI | GFX_INTERP);
    else
        out64(GFX_CONTROL, gfx_control_reg_memory | GFX_TRI);
}

void gfx_line3d(int x0, int y0, int z0, int x1, int y1, int z1)
{
    gfx_wait(9);
    out64(GFX_DEST_PIXEL_X, x0);
    out64(GFX_DEST_PIXEL_Y, y0);
    out64(GFX_DEST_PIXEL_Z, z0);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT0 | transformation_mode);
    out64(GFX_DEST_PIXEL_X, x1);
    out64(GFX_DEST_PIXEL_Y, y1);
    out64(GFX_DEST_PIXEL_Z, z1);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_ACTIVE_POINT1 | transformation_mode);
    out64(GFX_CONTROL, gfx_control_reg_memory | GFX_LINE);
}

void gfx_uv(unsigned int u0, unsigned int v0,
               unsigned int u1, unsigned int v1,
               unsigned int u2, unsigned int v2)
{
    gfx_wait(6);
    out64(GFX_U0, u0);
    out64(GFX_V0, v0);
    out64(GFX_U1, u1);
    out64(GFX_V1, v1);
    out64(GFX_U2, u2);
    out64(GFX_V2, v2);
}

void gfx_enable_tex0(unsigned int enable)
{
    gfx_wait(1);
    if(enable)
    {
        gfx_control_reg_memory   |= GFX_TEXTURE_ENABLE;
        out64(GFX_CONTROL, gfx_control_reg_memory);
    }
    else
    {
        gfx_control_reg_memory &= ~GFX_TEXTURE_ENABLE;
        out64(GFX_CONTROL, gfx_control_reg_memory);
    }
    gfx_init_src();
}

void gfx_bind_tex0(struct gfx_surface* surface)
{
    gfx_wait(3);
    tex0_surface = surface;
    out64(GFX_TEX0_BASE, surface->addr);
    out64(GFX_TEX0_SIZE_X, surface->w);
    out64(GFX_TEX0_SIZE_Y, surface->h);
    gfx_init_src();
}

void gfx_enable_alpha(unsigned int enable)
{
    gfx_wait(1);
    if(enable)
        gfx_control_reg_memory |= GFX_BLEND_ENABLE;
    else
        gfx_control_reg_memory &= ~GFX_BLEND_ENABLE;

    out64(GFX_CONTROL, gfx_control_reg_memory);
}

void gfx_set_alpha(unsigned int alpha)
{
    gfx_wait(1);
    out64(GFX_ALPHA, alpha);
}

void gfx_enable_colorkey(unsigned int enable)
{
    gfx_wait(1);
    if(enable)
        gfx_control_reg_memory |= GFX_COLORKEY_ENABLE;
    else
        gfx_control_reg_memory &= ~GFX_COLORKEY_ENABLE;

    out64(GFX_CONTROL, gfx_control_reg_memory);
}

void gfx_set_colorkey(unsigned int colorkey)
{
    gfx_wait(1);
    out64(GFX_COLORKEY, colorkey);
}

void gfx_enable_transform(unsigned int enable)
{
    if(enable)
        transformation_mode = GFX_TRANSFORM_POINT;
    else
        transformation_mode = GFX_FORWARD_POINT;
}

void gfx_set_transformation_matrix(int aa, int ab, int ac, int tx,
                                      int ba, int bb, int bc, int ty,
                                      int ca, int cb, int cc, int tz)
{
    gfx_wait(12);
    out64(GFX_AA, aa);
    out64(GFX_AB, ab);
    out64(GFX_AC, ac);
    out64(GFX_TX, tx);
    out64(GFX_BA, ba);
    out64(GFX_BB, bb);
    out64(GFX_BC, bc);
    out64(GFX_TY, ty);
    out64(GFX_CA, ca);
    out64(GFX_CB, cb);
    out64(GFX_CC, cc);
    out64(GFX_TZ, tz);
}
