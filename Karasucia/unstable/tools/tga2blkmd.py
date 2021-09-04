#======================================================================
# Tiled+TGA to MD
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
	d7 += d3 + d4
      d4 += 1
      d2 -= 1
    d4 = 0
    d5 += 1
    lay += x_size
    d1 -= 1
    
  return(d7)
  
def grab_pal(here):
	d7 = 0
	input_file.seek(here)
	d5 = 8
	while d5:
		d6 = 8
		while d6:
			byte = int(get_val(input_file.read(1)),16)
			if byte != 0:
				break
			d6 -= 1
		here += x_size
		input_file.seek(here)
		d5 -= 1
		
	d7 = (byte&0x30) << 9
	return(d7)

def chks_dupl(chksum):
  sizeof_filter=3				#number of list entries
  
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

artfile = sys.argv[1]
artout  = sys.argv[2]
mapout  = sys.argv[3]
palout  = sys.argv[4]
in_vram = sys.argv[5]
#a       = sys.argv[6]

DOUBLE_MODE = False
ZEROBLKCHK  = False

# ------------------------------------

cells_used = 0
cells_list = list()
przrle	= [0,0] 

# ------------------------------------



d0 = artfile#"map16.tga"
input_file = open(artfile,"rb")
out_art    = open(artout,"wb")

if mapout != "False":
	out_map    = open(mapout,"wb")

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
if palout == "False":
	input_file.seek(size_pal*3,True)
else:
	out_pal    = open(palout,"wb")
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
	out_pal.close()
	
# ----------------------
# Make NULL block
# ----------------------

map_vram = int(in_vram,16)
if mapout != "False":
	if DOUBLE_MODE == True:
		
		#out_art.write(chr(0)*0x40)
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
		#out_art.write(chr(0)*0x20)
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
#map_vram += int(in_vram,16)
d1 = map_vram
image_addr=input_file.tell()
curr_block = 1

y_pos=0
cell_y_size=y_size/16
while cell_y_size:
	x_pos=0
	cell_x_size=x_size/16
	while cell_x_size:
		
		if curr_block != 0:
			
			#X-
			#--
			d4 = (image_addr+seek_cell(x_pos,y_pos))
			d2 = chks_make(d4)
			d1 = 0
			d3 = 0
			
			
			d3 = grab_pal(d4)
			write_cell(d4)
			cells_used += 1
			d1=map_vram
			cells_list.append(d2)
			cells_list.append(d1)
			cells_list.append(d3)
			map_vram+=1
			if mapout != "False":
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
			
			#--
			#X-
			d4 = (image_addr+seek_cell(x_pos,y_pos+1))
			d2 = chks_make(d4)
			d1 = 0
			d3 = 0

			d3 = grab_pal(d4)
			write_cell(d4)
			cells_used += 1
			d1=map_vram
			cells_list.append(d2)
			cells_list.append(d1)
			cells_list.append(d3)
			map_vram+=1
			if mapout != "False":
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
			
			#-X
			#--
			d4 = (image_addr+seek_cell(x_pos+1,y_pos))
			d2 = chks_make(d4)
			d1 = 0
			d3 = 0

			d3 = grab_pal(d4)
			write_cell(d4)
			cells_used += 1
			d1=map_vram
			cells_list.append(d2)
			cells_list.append(d1)
			cells_list.append(d3)
			map_vram+=1
			if mapout != "False":
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
			
			#--
			#-X
			d4 = (image_addr+seek_cell(x_pos+1,y_pos+1))
			d2 = chks_make(d4)
			d1 = 0
			d3 = 0

			d3 = grab_pal(d4)
			write_cell(d4)
			cells_used += 1
			d1=map_vram
			cells_list.append(d2)
			cells_list.append(d1)
			cells_list.append(d3)
			map_vram+=1
			if mapout != "False":
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
		
		curr_block += 1
		
		x_pos += 2
		cell_x_size -= 1
	
	y_pos += 2
	cell_y_size -= 1

print "File:",artfile

input_file.close()
out_art.close()
if mapout != "False":
	out_map.close()
