#======================================================================
# Tiled+TGA to MD
#======================================================================

import sys
import xml.etree.ElementTree as ET

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
      byte = int(get_val(input_file.read(1)),16)
      if byte != 0:
        d3 = byte + d4 + d5 + d7
        d7 += d3
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
# Convert blocks
# -------------------------------------------------

DUPL_CHECK  = True
BLANK_CELL  = True
DOUBLE_MODE = False
RLE_PRIZES  = True
NUM_LAYERS  = 3

# ------------------------------------

cells_used = 0
cells_list = list()
przrle	= [0,0] 

# ------------------------------------

d0 = "map16.tga"
#d0 = sys.argv[2]
input_file = open(d0,"rb")
out_art    = open("lvl_art.bin","wb")
out_pal    = open("lvl_pal.bin","wb")
out_map    = open("lvl_blk.bin","wb")

input_file.seek(0x5)					#$05, palsize
size_pal = int(get_val(input_file.read(1)),16)

input_file.seek(0xC)					#$0C, xsize,ysize (little endian)
x_r = int(get_val(input_file.read(1)),16)
x_l = (int(get_val(input_file.read(1)),16)<<8)
x_size = x_l+x_r
y_r = int(get_val(input_file.read(1)),16)
y_l = (int(get_val(input_file.read(1)),16)<<8)
y_size = (y_l+y_r)

a = x_size&7
b = y_size&7
c = "X SIZE IS MISALIGNED"
d = "Y SIZE IS MISALIGNED"
e = " "
f = " "
g = False
if a != 0:
  print hex(a)
  e = c
  g = True
if b !=0:
  f = d
  g = True
  
if g == True:
  print "WARNING:",e,f
  
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

# ----------------------
# Make NULL block
# ----------------------

if DOUBLE_MODE == True:
  map_vram = 2
  out_art.write(chr(0)*0x40)
  d0 = 0x0000
  d1 = 0x0001
  out_map.write(
    chr(int((d0&0xFF00)>>8)&0xFF)
    +
    chr(int(d0)&0xFF)
    +
    chr(int((d0&0xFF00)>>8)&0xFF)
    +
    chr(int(d0)&0xFF)
    +
    chr(int((d1&0xFF00)>>8)&0xFF)
    +
    chr(int(d1)&0xFF)
    +
    chr(int((d1&0xFF00)>>8)&0xFF)
    +
    chr(int(d1)&0xFF)
    )
else:
  map_vram = 1
  out_art.write(chr(0)*0x20)
  d0 = 0x0000
  d1 = 0x0000
  out_map.write(
    chr(int((d0&0xFF00)>>8)&0xFF)
    +
    chr(int(d0)&0xFF)
    +
    chr(int((d0&0xFF00)>>8)&0xFF)
    +
    chr(int(d0)&0xFF)
    +
    chr(int((d1&0xFF00)>>8)&0xFF)
    +
    chr(int(d1)&0xFF)
    +
    chr(int((d1&0xFF00)>>8)&0xFF)
    +
    chr(int(d1)&0xFF)
    )
  
#======================================================================
# -------------------------------------------------
# Convert tga
# -------------------------------------------------

cells_used = 0
x_pos = 0
y_pos = 0
d1 = map_vram
image_addr=input_file.tell()

y_pos=0
cell_y_size=y_size/16
while cell_y_size:
  x_pos=0
  cell_x_size=x_size/16
  while cell_x_size:
    
    d2 = chks_make(image_addr+seek_cell(x_pos,y_pos))
    d1 = 0
    if d2 != 0:
      if chks_dupl(d2)[0] == True:
        d1=chks_dupl(d2)[1]
      else:
        write_cell(image_addr+seek_cell(x_pos,y_pos))
        cells_used += 1
        d1=map_vram
        cells_list.append(d2)
        cells_list.append(d1)
        map_vram+=1
    out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
    
    d2 = chks_make(image_addr+seek_cell(x_pos,y_pos+1))
    d1 = 0
    if d2 != 0:
      if chks_dupl(d2)[0] == True:
        d1=chks_dupl(d2)[1]
      else:
        write_cell(image_addr+seek_cell(x_pos,y_pos+1))
        cells_used += 1
        d1=map_vram
        cells_list.append(d2)
        cells_list.append(d1)
        map_vram+=1
    out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
    
    d2 = chks_make(image_addr+seek_cell(x_pos+1,y_pos))
    d1 = 0
    if d2 != 0:
      if chks_dupl(d2)[0] == True:
        d1=chks_dupl(d2)[1]
      else:
        write_cell(image_addr+seek_cell(x_pos+1,y_pos))
        cells_used += 1
        d1=map_vram
        cells_list.append(d2)
        cells_list.append(d1)
        map_vram+=1
    out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
      
    d2 = chks_make(image_addr+seek_cell(x_pos+1,y_pos+1))
    d1 = 0
    if d2 != 0:
      if chks_dupl(d2)[0] == True:
        d1=chks_dupl(d2)[1]
      else:
        write_cell(image_addr+seek_cell(x_pos+1,y_pos+1))
        cells_used += 1
        d1=map_vram
        cells_list.append(d2)
        cells_list.append(d1)
        map_vram+=1
    out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
      
    x_pos += 2
    cell_x_size -= 1
    
  y_pos += 2
  cell_y_size -= 1
#d1 = 1

#y_pos=0
#cell_y_size=1#(y_size/16)
#while cell_y_size:
  #x_pos=0
  #cell_x_size=(x_size/16)
  #while cell_x_size:
    #d1 = 0
    #d2 = chks_make(image_addr+seek_cell(x_pos,y_pos))
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
	#write_cell(image_addr+seek_cell(x_pos,y_pos))
	#cells_used += 1
	#d1=vram
	#cells_list.append(d2)
	#cells_list.append(d1)
	#vram+=1
	  
    ##out_map.write(chr(int((d1&0xFF00)>>8)&0xFF)+chr(int(d1)&0xFF))
    ##x_pos+=1
    ##cell_x_size -= 1
  #y_pos+=1
  #cell_y_size -= 1
  
input_file.close()
out_art.close()
out_pal.close()
out_map.close()

#======================================================================
# -------------------------------------------------
# Convert layout
# -------------------------------------------------

d0 = "main.tmx"
#d0 = sys.argv[1]
input_file = open(d0,"rb")

tree = ET.parse(input_file)
root = tree.getroot()

layer_list = list()
data_list  = list()

a = True
for layer in root.iter('layer'):
	layer_list.append(layer.attrib.values()[1])
	if a == True:
		a = False
		lay_xsize = layer.attrib.values()[0]
		lay_ysize = layer.attrib.values()[2]
for data in root.iter('data'):
	data_list.append(data.text)

c = NUM_LAYERS
d = 0
while c:
	a = data_list[d].replace("\n","").split(",")
	b = layer_list[d]
	
	#print layer_list[d]
	this_file = open(layer_list[d]+".bin","wb")
	f = 0
	g = data_list[d].split(",")
	e = len(g)
	while e:
		this_file.write(chr(int(g[f])&0xFF))
		f += 1
		e -= 1
	this_file.close()
	d += 1
	c -= 1

print "LEVEL SIZE:",lay_xsize,lay_ysize
input_file.close()

#======================================================================
# TODO
# esto es temporal
# poner esto en el loop de arriba
#======================================================================

input_file = open("fg_prz"+".bin","rb")
out_prz = open("fg_prz_rle"+".bin","wb")

if RLE_PRIZES == True:
	c = True
	while c:
		a = input_file.read(1)
		input_file.seek(-1,1)
		if a == "":
			c = False
		else:
			a = int(get_val(input_file.read(1)),16) & 0xFF
			b = przrle[1]
			if b != a:
				przrle[0] = 0
				out_prz.seek(+2,1)
				
			przrle[1] = a
			przrle[0] +=1
			if przrle[0] > 0xFE:
				przrle[0] = 1
				out_prz.seek(+2,1)
			out_prz.write(chr(int(przrle[0]&0xFF)))
			out_prz.write(chr(int(przrle[1]&0xFF)))
			out_prz.seek(-2,1)
		
#======================================================================

out_prz.close()
input_file.close()
