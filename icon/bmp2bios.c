/***************************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: bmp2bios.c                                                         *
*                                                                          *
* This code is freeware, not public domain.  Please use respectfully.      *
*                                                                          *
* You may:                                                                 *
*  - use this code for learning purposes only.                             *
*  - use this code in your own Operating System development.               *
*  - distribute any code that you produce pertaining to this code          *
*    as long as it is for learning purposes only, not for profit,          *
*    and you give credit where credit is due.                              *
*                                                                          *
* You may NOT:                                                             *
*  - distribute this code for any purpose other than listed above.         *
*  - distribute this code for profit.                                      *
*                                                                          *
* You MUST:                                                                *
*  - include this whole comment block at the top of this file.             *
*  - include contact information to where the original source is located.  *
*            https://github.com/fysnet/i440fx                              *
*                                                                          *
* DESCRIPTION:                                                             *
*   this is a quick-n-dirty app to convert a .BMP icon/bitmap file         *
*   to data characters ready to insert into a source file.                 *
*                                                                          *
* Last Updated: 19 Oct 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
*  -                                                                       *
*                                                                          *
***************************************************************************/

#include <stdio.h>
#include <stdlib.h>

// size of memory operands
typedef   signed  char      bool;
typedef   signed  char      bit8s;
typedef unsigned  char      bit8u;
typedef   signed short      bit16s;
typedef unsigned short      bit16u;
typedef   signed  long      bit32s;
typedef unsigned  long      bit32u;

#pragma pack(1)

struct BMP_HDR {
  bit16u bf_id;           // ascii 'BM'
  bit32u bf_size;         // size of file
  bit16u bf_resv0;
  bit16u bf_resv1;
  bit32u bf_offbits;      // offset in file where image begins
} bmp_hdr;

struct BMP_INFO {
  bit32u bi_size;               // icon: used
  bit32u bi_width;              // icon: used
  bit32u bi_height;             // icon: used
  bit16u bi_planes;             // icon: used
  bit16u bi_bitcount;           // icon: used
  bit32u bi_compression;        // icon: not used
  bit32u bi_sizeimage;          // icon: used
  bit32u bi_x_pelspermeter;     // icon: not used
  bit32u bi_y_pelspermeter;     // icon: not used
  bit32u bi_clrused;            // icon: not used
  bit32u bi_clrimportant;       // icon: not used
} bmp_info;

FILE *fp;

struct PIXELS {
  bit32u pixel;
  int count;
};

#define PIXEL_COUNT 1000
struct PIXELS *pixels = NULL;
int pix_count = 0;

// returns 1 if already in table
// returns 0 if not in table
// returns -1 if too many found
int add_to_table(bit32u pixel) {
  for (int i=0; i<pix_count; i++) {
    if (pixels[i].pixel == pixel) {
      pixels[i].count++;
      return 1;
    }
  }
  if (pix_count < PIXEL_COUNT) {
    pixels[pix_count].pixel = pixel;
    pixels[pix_count].count = 1;
    pix_count++;
    return 0;
  }
  return -1;
}

int get_table_index(bit32u pixel) {
  for (int i=0; i<pix_count; i++) {
    if (pixels[i].pixel == pixel)
      return i;
  }
  return -2;
}

// set to 0 to simple calculate and print the size of the binary returned
#define PRINTIT  1

int main(int argc, char *argv[]) {
  
#if (!PRINTIT)
  int t = 0, tt = 0;
#endif

  fp = fopen(argv[1], "rb");
  if (fp == NULL) {
    printf("Error opening: %s\n", argv[1]);
    return -1;
  }

  if (fread(&bmp_hdr, 1, sizeof(struct BMP_HDR), fp) != sizeof(struct BMP_HDR)) {
    puts("Error reading HDR from file");
    fclose(fp);
    return -1;
  }
  if (bmp_hdr.bf_id != 0x4D42) {
    printf("Header ID doesn't = 0x4D42 (0x%04X)\n", bmp_hdr.bf_id);
    fclose(fp);
    return -1;
  }
  //printf(" file size = %i, image start = %i\n", bmp_hdr.bf_size, bmp_hdr.bf_offbits);

  if (fread(&bmp_info, 1, sizeof(struct BMP_INFO), fp) != sizeof(struct BMP_INFO)) {
    puts("Error reading INFO from file");
    fclose(fp);
    return -1;
  }
  if (bmp_info.bi_size != 40) {
    printf("Header size doesn't = 40 (%i)\n", bmp_info.bi_size);
    fclose(fp);
    return -1;
  }
  //printf(" width = %i, height = %i bpp = %i  bi_sizeimage = %i\n", bmp_info.bi_width, bmp_info.bi_height, bmp_info.bi_bitcount, bmp_info.bi_sizeimage);

  if (bmp_info.bi_bitcount != 24) {
    printf("bpp doesn't = 24 (%i)\n", bmp_info.bi_bitcount);
    fclose(fp);
    return -1;
  }

  if ((bmp_info.bi_width * 3) & 0x02) {
    printf("width is not a multiple of 4 bytes");
    fclose(fp);
    return -1;
  }

  const int count = bmp_info.bi_width * bmp_info.bi_height;
  bit8u *buffer = (bit8u *) malloc((count * 3) + 4);
  //if (buffer == NULL) {
  //  printf("Error allocating %i-byte buffer\n", count * 3);
  //  fclose(fp);
  //  return -1;
  //}
  fseek(fp, bmp_hdr.bf_offbits, SEEK_SET);
  if (fread(buffer, 1, count * 3, fp) != (count * 3)) {
    puts("Error reading buffer from file");
    fclose(fp);
    free(buffer);
    return -1;
  }

  pixels = (struct PIXELS *) malloc(PIXEL_COUNT * sizeof(struct PIXELS));
  pix_count = 0;

  for (int i=0; i<count; i++) {
    bit32u *p = (bit32u *) &buffer[i*3];
    if (add_to_table(*p & 0x00FFFFFF) == -1)
      break;
  }

#if PRINTIT
  printf("  dw  %3i  ; width\n", bmp_info.bi_width);
  printf("  dw  %3i  ; height\n", bmp_info.bi_height);
  printf("  dw  %3i  ; palette size\n", pix_count);
  printf("  ; pallet (%i pixels)", pix_count);
  for (int i=0; i<pix_count; i++) {
    if ((i % 8) == 0)
      printf("\n  dd  0x%08X", pixels[i].pixel);
    else
      printf(", 0x%08X", pixels[i].pixel);
  }
  printf("\n  ; pixel table:");
#else
  tt = 6;
  tt += pix_count * 4;
#endif

  // https://rosettacode.org/wiki/Run-length_encoding#C
#if 1
  bit8u buf[256];
  int len = 0;
  bool repeat = 0, end = 0;

  for (int i=0; i<=count; i++) {
    end = (i == count);
    if (!end) {
      bit32u *p = (bit32u *) &buffer[i*3];
      buf[len++] = get_table_index(*p & 0x00FFFFFF);
      if (len <= 1) continue;
    }

    if (repeat) {
      if (buf[len - 1] != buf[len - 2])
        repeat = 0;
      if (!repeat || len == 129 || end) {
        /* write out repeating bytes */
#if PRINTIT
        printf("\n  ; run of %i 0x%02X's", end ? len : len - 1, buf[0]);
        printf("\n  db  %i, 0x%02X", end ? len : len - 1, buf[0]);
#else
        t += (end ? len : len - 1);
        tt += 2;
#endif
        buf[0] = buf[len - 1];
        len = 1;
      }
    } else {
      if (buf[len - 1] == buf[len - 2]) {
        repeat = 1;
        if (len > 2) {
          //output(out, buf, len - 2);
          {
#if PRINTIT
            printf("\n  ; count of %i bytes", len - 2);
            printf("\n  db  %3i", 128 + len - 2);
	          for (int j = 0; j < len - 2; j++) {
              if (j && ((j % 16) == 0))
                printf("\n  db       0x%02X", buf[j]);
              else
                printf(", 0x%02X", buf[j]);
            }
#else
            t += len - 2;
            tt += 1 + (len - 2);
#endif
          }
          buf[0] = buf[1] = buf[len - 1];
          len = 2;
        }
        continue;
      }
      if (len == 128 || end) {
        //output(out, buf, len);
        {
#if PRINTIT
          printf("\n  ; count of %i bytes", len - 2);
          printf("\n  db  %3i", 128 + len - 2);
	          for (int j = 0; j < len - 2; j++) {
              if (j && ((j % 16) == 0))
                printf("\n  db       0x%02X", buf[j]);
              else
                printf(", 0x%02X", buf[j]);
            }
#else
          t += len - 2;
          tt += 1 + (len - 2);
#endif
        }
        len = 0;
        repeat = 0;
      }
    }
  }
#if (!PRINTIT)
  printf("\n %i of %i   %i total bytes\n", t, count, tt);  // 6683
#else
  //printf("\n  ; end marker\n  db  255\n");
  printf("\n.end\n");
#endif

#endif  

  fclose(fp);
  free(buffer);
  free(pixels);

  return 0;
}
