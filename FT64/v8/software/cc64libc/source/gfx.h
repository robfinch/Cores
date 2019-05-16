/*
Bare metal OpenCores GFX IP driver for Wishbone bus.

Anton Fosselius, Per Lenander 2012
  */

#ifndef GFX_H
#define GFX_H

// Pixel definitions, use these when setting colors
//
// Pixels are defined by R,G,B where R,G,B are the most significant Red, Green and Blue bits
// All color channels are in the range 0-255
// (Greyscale is kind of subobtimal)
#define GFX_PIXEL_8(R,G,B)  (R*0.3 + G*0.59 + B*0.11)
#define GFX_PIXEL_12(R,G,B) (((R >> 4) << 8) | ((G >> 4) << 4) | (B>>4))
#define GFX_PIXEL_16(R,G,B) (((R >> 3) << 11) | ((G >> 2) << 5) | (B>>3))
#define GFX_PIXEL_24(R,G,B) ((R << 16) | (G << 8) | B)
#define GFX_PIXEL_32(A,R,G,B) ((A << 24) | (R << 16) | (G << 8) | B)

#define SUBPIXEL_WIDTH 16
#define FIXEDW (1<<SUBPIXEL_WIDTH)

// Can be used as "memoryArea" in init
#define GFX_VMEM 0x00400000
//                   800000

struct gfx_surface
{
    unsigned int addr;
    unsigned int w;
    unsigned int h;
};

typedef struct gfx_point2
{
    double x, y;
} gfx_point2;

typedef struct gfx_point3
{
    double x, y, z;
} gfx_point3;

typedef struct _tagPoint2
{
    __int32 x;
    __int32 y;
} gfx_point2i;

typedef struct _tagPoint3
{
    __int32 x;
    __int32 y;
    __int32 z;
} gfx_point3i;

// Must be called before any other orgfx functions.
pascal void gfx_init(unsigned int memoryArea);

// Set video mode
void gfx_vga_set_videomode(unsigned int width, unsigned int height, unsigned char bpp);

// Vga stuff for double buffering (bank switching)
inline void gfx_vga_set_vbara(unsigned int addr);
inline void gfx_vga_set_vbarb(unsigned int addr);
inline void gfx_vga_bank_switch();
inline unsigned int gfx_vga_AVMP(); // Get the active memory page

struct gfx_surface gfx_init_surface(unsigned int width, unsigned int height);
void gfx_bind_rendertarget(struct gfx_surface *surface);

// Set the clip rect. Nothing outside this area will be rendered. This is reset every time you change render target
void gfx_enable_cliprect(unsigned int enable);
void gfx_cliprect(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1);

// Set source rect (applied to texturing). This is reset every time you bind a new texture or enable/disable texturing
inline void gfx_srcrect(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1);

// Copies a buffer into the current render target
void gfx_memcpy(unsigned int mem[], unsigned int size);

// Primitives
inline void gfx_set_color(unsigned int color);
inline void gfx_set_colors(unsigned int color0, unsigned int color1, unsigned int color2);
pascal void gfx_set_pixel(int,int,int);
pascal void gfx_get_pixel(int,int,int*);
pascal void gfx_solid_rect(int x0, int y0, int x1, int y1);
pascal void gfx_line(int x0, int y0, int x1, int y1);
pascal void gfx_triangle(int x0, int y0, int x1, int y1, int x2, int y2);
inline void gfx_solid_triangle(int x0, int y0,
                            int x1, int y1,
                            int x2, int y2,
                            unsigned int interpolate);
inline void gfx_curve(int x0, int y0,
                         int x1, int y1,
                         int x2, int y2,
                         unsigned int inside);

inline void gfx_line3d(int x0, int y0, int z0, int x1, int y1, int z1);
inline void gfx_triangle3d(int x0, int y0, int z0,
                              int x1, int y1, int z1,
                              int x2, int y2, int z2,
                              unsigned int interpolate);

inline void gfx_uv(unsigned int u0, unsigned int v0,
                      unsigned int u1, unsigned int v1,
                      unsigned int u2, unsigned int v2);

void gfx_enable_tex0(unsigned int enable);
void gfx_bind_tex0(struct gfx_surface* surface);
void gfx_enable_zbuffer(unsigned int enable);
void gfx_bind_zbuffer(struct gfx_surface *surface);
void gfx_clear_zbuffer();

#define GFX_OPAQUE 0xffffffff

void gfx_enable_alpha(unsigned int enable);
void gfx_set_alpha(unsigned int alpha);

void gfx_enable_colorkey(unsigned int enable);
void gfx_set_colorkey(unsigned int colorkey);

void gfx_enable_transform(unsigned int enable);
void gfx_set_transformation_matrix(int aa, int ab, int ac, int tx,
                                      int ba, int bb, int bc, int ty,
                                      int ca, int cb, int cc, int tz);

#endif
