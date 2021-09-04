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
  
  a = int(get_val(input_file.read(1)),16) & 0x0F
  b = int(get_val(input_file.read(1)),16) & 0x0F
  c = int(get_val(input_file.read(1)),16) & 0x0F
  d = int(get_val(input_file.read(1)),16) & 0x0F
  e = int(get_val(input_file.read(1)),16) & 0x0F
  f = int(get_val(input_file.read(1)),16) & 0x0F
  g = int(get_val(input_file.read(1)),16) & 0x0F
  h = int(get_val(input_file.read(1)),16) & 0x0F
      
  a = a << 4
  a = a+b
  c = c << 4
  c = c+d
  e = e << 4
  e = e+f
  g = g << 4
  g = g+h
      
  out_art.write(chr(a))
  out_art.write(chr(c))
  out_art.write(chr(e))
  out_art.write(chr(g))

def write_cell(cell_off):
  #global cells_used
  
  rept = 8
  while rept:
    write_line(cell_off)
    cell_off += x_size
    rept -= 1
  #cells_used += 1
    
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
    
def check_frame(addr):
  global x_size
  global y_size
  d7 = 0
  
  input_file.seek(addr)
  d6 = x_size*(y_size/numof_frames)
  while d6:
    d5 = int(get_val(input_file.read(1)),16)
    d7 += d5
    d6 -= 1
    
  return(d7)

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

VERSION = 0
BLANK_CELL = 0x7FF

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

askversize   = int(raw_input("Vertical size? "))

print "* Converting *"
input_file = open("in.tga","rb")
out_keys   = open("frames.bin","wb")
out_art    = open("art.bin","wb")
out_pal    = open("pal.bin","wb")
out_map    = open("map.bin","wb")

input_file.seek(0x5)					#$05, palsize
size_pal = int(get_val(input_file.read(1)),16)

input_file.seek(0xC)					#$0C, xsize,ysize (little endian)
x_r = int(get_val(input_file.read(1)),16)
x_l = (int(get_val(input_file.read(1)),16)<<8)
x_size = x_l+x_r
y_r = int(get_val(input_file.read(1)),16)
y_l = (int(get_val(input_file.read(1)),16)<<8)
y_size = (y_l+y_r)

numof_frames = (y_size/askversize)

# ----------------------
# Write palette
# ----------------------

input_file.seek(0x12)
d0 = size_pal
while d0:
  b = int(get_val(input_file.read(1)),16)
  g = int(get_val(input_file.read(1)),16)
  r = int(get_val(input_file.read(1)),16)
  r = r >> 5
  r = r << 1
  g = g >> 5
  g = g << 1
  b = b >> 5
  b = b << 1
  g = g << 4
  gr = g+r
  out_pal.write(chr(b))
  out_pal.write(chr(gr))
  d0 -= 1

#======================================================================
# -------------------------------------------------
# The best part
# -------------------------------------------------

out_keys.write("MVID")
out_keys.write(chr(int((VERSION&0xFF00)>>8)&0xFF)+chr(int(VERSION)&0xFF))
d1 = (x_size>>3)-1
out_keys.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
d1 = ((y_size/numof_frames)>>3)-1
out_keys.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))

out_keys.seek(0x10)

#input_file = open("in.data","rb")

# ----------------------
# Magic.
# ----------------------

#out_map.seek(0)
#d1 = (x_size>>3)
#out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
#d1 = ((y_size/numof_frames)>>3)
#out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))

image_addr   = input_file.tell()
frames_vid   = numof_frames
addr_mapsize = out_map.tell()
addr_artsize = out_art.tell()
samefrmcntr = out_art.tell()
d1=0
next_art=0
d6 = 0
d7 = 0
same_frame = 0
lastchks = 0
addrsamefrm = out_keys.tell()

while frames_vid:
  chksumfrm = check_frame(image_addr)
  #print hex(chksumfrm),hex(lastchks)
  
  if chksumfrm == lastchks:
    
    print "SAME"
    same_frame += 1
    
    if frames_vid == 1:
      pushpop_artaddr = out_keys.tell()
      out_keys.seek(addrnxtframe)
      d1 = -1
      out_keys.write( chr(int((d1&0xFF000000)>>0x18)&0xFF) + chr(int((d1&0xFF0000)>>0x10)&0xFF) + chr(int((d1&0xFF00)>>8)&0xFF) + chr(int(d1)&0xFF) )
      out_keys.seek(pushpop_artaddr)
      
    pushpop_artaddr = out_keys.tell()
    out_keys.seek(addrsamefrm)
    d1 = same_frame
    out_keys.write( chr(int((d1&0xFF000000)>>0x18)&0xFF) + chr(int((d1&0xFF0000)>>0x10)&0xFF) + chr(int((d1&0xFF00)>>8)&0xFF) + chr(int(d1)&0xFF) )
    out_keys.seek(pushpop_artaddr)
    
    #out_art.seek(+0xC,True)
    #out_map.seek(+4,True)
    
  else:
    lastchks = chksumfrm
    
    cells_used = 0
    same_frame = 0
    
    #lastartaddr = out_art.tell()
    #out_art.seek(+0x8,True)
    #samefrmcntr = out_art.tell()
    #out_art.seek(+0x4,True)
    
    #out_map.seek(+4,True)
    vram=0
    y_pos=0
    cell_y_size=((y_size/numof_frames)>>3)
    while cell_y_size:
      x_pos=0
      cell_x_size=(x_size>>3)
      while cell_x_size:
        d1 = BLANK_CELL
        if chks_make(image_addr+seek_cell(x_pos,y_pos)) != 0:
          write_cell(image_addr+seek_cell(x_pos,y_pos))
          cells_used += 1
          d1=vram
          vram+=1
	  
        out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
        x_pos+=1
        d6 += 1
        cell_x_size -= 1
      y_pos+=1
      d7 += 1
      cell_y_size -= 1
    
    a = out_art.tell() & 0x008000
    if a == 0x8000:
      out_art.write(chr(0xFF)*0x8000)

    pushpop_mapaddr = out_map.tell()
    addrnxtframe = out_keys.tell()
    a = pushpop_mapaddr
    if frames_vid == 1:
      a = -1
    d1 = a
    out_keys.write( chr(int((d1&0xFF000000)>>0x18)&0xFF) + chr(int((d1&0xFF0000)>>0x10)&0xFF) + chr(int((d1&0xFF00)>>8)&0xFF) + chr(int(d1)&0xFF) )
  
    pushpop_artaddr = out_art.tell()
    a = pushpop_artaddr
    if frames_vid == 1:
      a = -1
    d1 = a
    out_keys.write( chr(int((d1&0xFF000000)>>0x18)&0xFF) + chr(int((d1&0xFF0000)>>0x10)&0xFF) + chr(int((d1&0xFF00)>>8)&0xFF) + chr(int(d1)&0xFF) )
    
    d1 = cells_used
    out_keys.write( chr(int((d1&0xFF000000)>>0x18)&0xFF) + chr(int((d1&0xFF0000)>>0x10)&0xFF) + chr(int((d1&0xFF00)>>8)&0xFF) + chr(int(d1)&0xFF) )
    addrsamefrm = out_keys.tell()
    
    d1 = same_frame
    out_keys.write( chr(int((d1&0xFF000000)>>0x18)&0xFF) + chr(int((d1&0xFF0000)>>0x10)&0xFF) + chr(int((d1&0xFF00)>>8)&0xFF) + chr(int(d1)&0xFF) )
    
  image_addr += x_size*(y_size/numof_frames)
    
  print frames_vid
  frames_vid -= 1

#======================================================================

#print "cells used:",hex(cells_used)
print "Done."
input_file.close()
out_art.close()
out_pal.close()
out_map.close()
out_keys.close()

