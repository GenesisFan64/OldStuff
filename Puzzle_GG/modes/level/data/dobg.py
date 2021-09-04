#======================================================================
# BG Converter
# 
# STABLE
#======================================================================

#======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------

def get_val(string_in):
  got_this_str=""
  for do_loop_for in string_in:
    got_this_str = got_this_str + ("0"+((hex(ord(do_loop_for)))[2:]))[-2:]
  return(got_this_str)

def write_line(in_offset):
  input_file.seek(in_offset)
  
  h = int(get_val(input_file.read(1)),16) & 0x0F
  g = int(get_val(input_file.read(1)),16) & 0x0F
  f = int(get_val(input_file.read(1)),16) & 0x0F
  e = int(get_val(input_file.read(1)),16) & 0x0F
  d = int(get_val(input_file.read(1)),16) & 0x0F
  c = int(get_val(input_file.read(1)),16) & 0x0F
  b = int(get_val(input_file.read(1)),16) & 0x0F
  a = int(get_val(input_file.read(1)),16) & 0x0F
      
  byte1 = ((h & 0b0001)<<7)+((g & 0b0001)<<6)+((f & 0b0001)<<5)+((e & 0b0001)<<4)+((d & 0b0001)<<3)+((c & 0b0001)<<2)+((b & 0b0001)<<1)+(a & 0b0001)
  byte2 = (((h & 0b0010)<<7)+((g & 0b0010)<<6)+((f & 0b0010)<<5)+((e & 0b0010)<<4)+((d & 0b0010)<<3)+((c & 0b0010)<<2)+((b & 0b0010)<<1)+(a & 0b0010) >> 1)
  byte3 = (((h & 0b0100)<<7)+((g & 0b0100)<<6)+((f & 0b0100)<<5)+((e & 0b0100)<<4)+((d & 0b0100)<<3)+((c & 0b0100)<<2)+((b & 0b0100)<<1)+(a & 0b0100) >> 2)
  byte4 = (((h & 0b1000)<<7)+((g & 0b1000)<<6)+((f & 0b1000)<<5)+((e & 0b1000)<<4)+((d & 0b1000)<<3)+((c & 0b1000)<<2)+((b & 0b1000)<<1)+(a & 0b1000) >> 3)
      
  out_art.write(chr(byte1))
  out_art.write(chr(byte2))
  out_art.write(chr(byte3))
  out_art.write(chr(byte4))

def write_cell(cell_off):
  global cells_used
  
  rept = 8
  while rept:
    write_line(cell_off)
    cell_off += x_size
    rept -= 1
  cells_used += 1
    
def seek_cell(x,y):
  x = x<<3
  y = y*(x_size*8)
  
  out_offset=x+y
  return(out_offset)

def chks_make(lay):
  d7 = 0
  
  d4 = 0
  d1 = 8
  while d1:
    input_file.seek(lay)
    d2 = 8
    while d2:
      byte = int(get_val(input_file.read(1)),16)
      if byte != 0:
	if byte < 0x30:
	  d3 = byte + d4 + (d7 & 0xFFF)
	  d7 += d3
      d4 += 1
      d2 -= 1
    lay += x_size
    d1 -= 1

  return(d7)

def chk_cell(lay):
  d7 = 0
  d6 = 0
  
  d4 = 0
  d1 = 8
  while d1:
    input_file.seek(lay)				#only check the first pixel of the cell
    a = int(get_val(input_file.read(1)),16)
    color = (a & 0xF0)
    color = color >> 4 & 0x0F
    d6 = color << 0x0D
    
    input_file.seek(lay)
    d2 = 8
    while d2:
      a = int(get_val(input_file.read(1)),16)
      byte = a & 0x0F
      if a != 0:
	d3 = byte + d4 + d7
	d7 += d3
      d4 += 1
      d2 -= 1
    lay += x_size
    d1 -= 1

  return(d7,d6)

def chkcell_dupl(chksum):
  sizeof_filter=2				#number of list entries
  
  a0=list_usedcells
  d2=0
  result=False
  if len(a0) != 0:
    d0 = len(a0)
    d1 = 0
    while d0:
      d0 -= sizeof_filter
      if a0[d1] == chksum:
	result=True
	d2 = a0[d1+1]
	d0 = False
      d1 += sizeof_filter

  return(result,d2)

def chks_dupl(thislist,size,chksum):
  sizeof_filter=size				#number of list entries
  
  vram1=0
  vram2=0
  vram3=0
  vram4=0
  a0=thislist
  d3=0  #page
  d2=0	#lay
  result=False
  if len(a0) != 0:
    d0 = len(a0)
    d1 = 0
    while d0:
      d0 -= sizeof_filter
      if a0[d1] == chksum:
	result=True
	d2 = a0[d1+1]
	d3 = a0[d1+2]
	vram1 = a0[d1+3]
	vram2 = a0[d1+4]
	vram3 = a0[d1+5]
	vram4 = a0[d1+6]
	d0 = False
      d1 += sizeof_filter

  return(result,d2,d3,vram1,vram2,vram3,vram4)
  
#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

cells_used	 = 0
list_usedcells	 = list()
DUPL_CHECK = True

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

print "* Converting *"
input_file = open("bg.tga","rb")
out_art    = open("bg_art.bin","wb")
out_pal    = open("bg_pal.bin","wb")
#out_map    = open("map.bin","wb")

input_file.seek(0x5)					#$05, palsize
size_pal = int(get_val(input_file.read(1)),16)

input_file.seek(0xC)					#$0C, xsize,ysize (little endian)
x_r = int(get_val(input_file.read(1)),16)
x_l = (int(get_val(input_file.read(1)),16)<<8)
x_size = x_l+x_r
y_r = int(get_val(input_file.read(1)),16)
y_l = (int(get_val(input_file.read(1)),16)<<8)
y_size = (y_l+y_r)

# ----------------------
# Write palette
# ----------------------

input_file.seek(0x12)
d0 = size_pal
while d0:
  b = int(get_val(input_file.read(1)),16)
  g = int(get_val(input_file.read(1)),16)
  r = int(get_val(input_file.read(1)),16)
  r = r >> 4
  g = g >> 4
  b = b >> 4
  g = g << 4
  gr = g+r
  out_pal.write(chr(gr))
  out_pal.write(chr(b))
  d0 -= 1

#out_art.write(chr(0)*0x20)

#======================================================================
# -------------------------------------------------
# The best part
# -------------------------------------------------

vram=1
#vram=0x8A5
image_addr=input_file.tell()
  
y_pos=0
cell_y_size=(y_size>>3)
while cell_y_size:
  x_pos=0
  cell_x_size=(x_size>>3)
  while cell_x_size:
    a0 = (image_addr+seek_cell(x_pos,y_pos))
    d0 = chks_make(image_addr+seek_cell(x_pos,y_pos))
    d1 = chk_cell(a0)[0]
    d4 = 0  
    
    #if d0 != 0:
      #if chkcell_dupl(d1)[0] == True:
	#d4 = chkcell_dupl(d1)[1]
      #else:
    write_cell(a0)
    d4=vram
    list_usedcells.append(chk_cell(a0)[0])
    list_usedcells.append(d4)
    vram+=1
        
    #out_map.write(chr(int(d4)&0xFF)+chr(int((d4&0xFF00)>>8)&0xFF))
    x_pos+=1
    cell_x_size -= 1
  y_pos+=1
  cell_y_size -= 1

#======================================================================

print "cells used:",hex(cells_used)
print "Done."
input_file.close()
out_art.close()
out_pal.close()
#out_map.close()
