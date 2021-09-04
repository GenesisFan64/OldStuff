#======================================================================
# TGA to MegaDrive
#======================================================================

import sys

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
  
  a = ord(input_file.read(1))
  b = ord(input_file.read(1))
  c = ord(input_file.read(1))
  d = ord(input_file.read(1))
  e = ord(input_file.read(1))
  f = ord(input_file.read(1))
  g = ord(input_file.read(1))
  h = ord(input_file.read(1))
      
  a = a << 4
  a = a+b
  c = c << 4
  c = c+d
  e = e << 4
  e = e+f
  g = g << 4
  g = g+h
      
  out_art.write(bytes([a]))
  out_art.write(bytes([c]))
  out_art.write(bytes([e]))
  out_art.write(bytes([g]))

def write_cell(cell_off):
  rept = 8
  while rept:
    write_line(cell_off)
    cell_off += x_size
    rept -= 1
    
def seek_cell(x,y):
  x = x<<3
  y = y*(x_size*8)
  
  out_offset=x+y
  return(out_offset)

def chks_make(lay):
  d7 = 0
  d5 = 0
  
  d4 = 0
  d1 = 8
  while d1:
    input_file.seek(lay)
    d2 = 8
    while d2:
      byte = ord(input_file.read(1))
      if byte != 0:
        d3 = byte + d4 + d5 + d7
        d7 += d3 + d4
      d4 += 1
      d2 -= 1
      
    d4 = 0
    d5 += 1
    lay += x_size
    d1 -= 1

  return(d7)
  
def chks_dupl(chksum):
  sizeof_filter=2				#number of list entries
  
  vram1=0
  vram2=0
  vram3=0
  vram4=0
  a0=cells_list
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
	      d0 = False
      d1 += sizeof_filter

  return(result,d2,d3,vram1,vram2,vram3,vram4)

#======================================================================
# -------------------------------------------------
# Settings
# -------------------------------------------------

DUPL_CHECK  = False
BLANK_CELL  = False

# -------------------------------------------------
# Init
# -------------------------------------------------

cells_used = 0
cells_list = list()

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

input_file = open(sys.argv[1],"rb")
out_art    = open(sys.argv[2],"wb")
out_pal    = open(sys.argv[3],"wb")
out_map    = open(sys.argv[4],"wb")

input_file.seek(0x5)					#$05, palsize
size_pal = ord(input_file.read(1))

input_file.seek(0xC)					#$0C, xsize,ysize (little endian)
x_r = ord(input_file.read(1))
x_l = (ord(input_file.read(1))<<8)
x_size = x_l+x_r
y_r = ord(input_file.read(1))
y_l = (ord(input_file.read(1))<<8)
y_size = (y_l+y_r)

a = x_size&7
b = y_size&7
c = "X SIZE IS MISALIGNED"
d = "Y SIZE IS MISALIGNED"
e = " "
f = " "
g = False
if a != 0:
  print( hex(a) )
  e = c
  g = True
if b !=0:
  f = d
  g = True
  
if g == True:
  print( "WARNING:",e,f )
  
# ----------------------
# Write palette
# ----------------------

input_file.seek(0x12)
d0 = size_pal
while d0:
  b = ord(input_file.read(1))
  g = ord(input_file.read(1))
  r = ord(input_file.read(1))
  r = r >> 5
  r = r << 1
  g = g >> 5
  g = g << 1
  b = b >> 5
  b = b << 1
  g = g << 4
  gr = g+r
  out_pal.write(bytes([b]))
  out_pal.write(bytes([gr]))
  d0 -= 1

if BLANK_CELL == True:
  vram=1
  out_art.write(bytes([0*0x20]))
else:
  vram=0
  
#======================================================================
# -------------------------------------------------
# The best part
# -------------------------------------------------

#input_file.seek(4,True)					#Image data

# ----------------------
# Filler
# ----------------------

image_addr=input_file.tell()
  
y_pos=0
cell_y_size=(y_size>>3)
while cell_y_size:
  x_pos=0
  cell_x_size=(x_size>>3)
  while cell_x_size:
    d1 = -1
    d2 = chks_make(image_addr+seek_cell(x_pos,y_pos))
    #if d2 != 0:
      #if DUPL_CHECK == True:
	#if chks_dupl(d2)[0] == True:
	  #d1=chks_dupl(d2)[1]
	#else:
	  #write_cell(image_addr+seek_cell(x_pos,y_pos))
	  #cells_used += 1
	  #d1=vram
	  #cells_list.append(d2)
	  #cells_list.append(d1)
	  #vram+=1
      #else:
    write_cell(image_addr+seek_cell(x_pos,y_pos))
    cells_used += 1
    d1=vram
    cells_list.append(d2)
    cells_list.append(d1)
    vram+=1
	  
    b = (d1 >> 8) & 0xFF
    a = d1 & 0xFF
    out_map.write( bytes([b,a]) )
    x_pos+=1
    cell_x_size -= 1
  y_pos+=1
  cell_y_size -= 1

#======================================================================

#print( "File:",sys.argv[1],"| Map size:",hex(x_size/8),hex(y_size/8),"| Cells used:",hex(cells_used) )
input_file.close()
out_art.close()
out_pal.close()
out_map.close()
