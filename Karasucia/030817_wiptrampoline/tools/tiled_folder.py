#======================================================================
# Tiled+TGA to MD
#======================================================================

import sys
import xml.etree.ElementTree as ET

#======================================================================
# -------------------------------------------------
# Settings
# -------------------------------------------------

#DUPL_CHECK  = True
#BLANK_CELL  = True
DOUBLE_MODE = False
RLE_PRIZES  = True
NUM_LAYERS  = 4

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

  return(result,d2,d3)

#======================================================================
# -------------------------------------------------
# Convert blocks
# -------------------------------------------------

# ------------------------------------

cells_used = 0
cells_list = list()
przrle	= [0,0] 

# ------------------------------------

layfile   = sys.argv[1]
layfolder = sys.argv[2]
artfile   = sys.argv[3]
artfolder = sys.argv[4]

# ------------------------------------
#======================================================================
# -------------------------------------------------
# Convert layout
# -------------------------------------------------

d0 = layfile#"main.tmx"
#d0 = sys.argv[1]
input_file = open(d0,"rb")

tree = ET.parse(input_file)
root = tree.getroot()

layer_list = list()
data_list  = list()
obj_list   = list()

a = True
for layer in root.iter('layer'):
	layer_list.append(layer.attrib.values()[1])
	if a == True:
		a = False
		lay_xsize = layer.attrib.values()[0]
		lay_ysize = layer.attrib.values()[2]
for data in root.iter('data'):
	data_list.append(data.text)
for objectgroup in root.iter("object"):
	obj_list.append(objectgroup.attrib.values()[4])
	obj_list.append(objectgroup.attrib.values()[2])
	obj_list.append(objectgroup.attrib.values()[1])	
	obj_list.append(objectgroup.attrib.values()[0])

#print obj_list
layer_data  = list()
#layer_names = list()
	
c = NUM_LAYERS
d = 0
while c:
	a = data_list[d].replace("\n","").split(",")
	b = layer_list[d]
	
	dictOfStuff = {}
	i = layer_list[d]
	dictOfStuff[i] = list()
	
	#layer_names.append(layer_list[d])
	
	#this_file = open(layfolder+layer_list[d]+".bin","wb")
	f = 0
	g = data_list[d].split(",")
	e = len(g)
	while e:
		h = int(g[f])
		if h != 0:
			h -= 1
		dictOfStuff[i].append(h)
		f += 1
		e -= 1
	layer_data.append(dictOfStuff[i])
	#this_file.close()
	d += 1
	c -= 1

#print layer_data[0]
#print layer_data

#======================================================================
# Convert array to files
#======================================================================

# --------------
# Prizes (RLEd)
# --------------

#print layer_data[3]
this_file = open(layfolder+"fg_prz"+".bin","wb")
przdata = 0
i = 0
c = len(layer_data[0])
while c:
	a = int( layer_data[3][i] )
	#print hex(a)
	d = 0
	if RLE_PRIZES == True:
		d = a
		b = przrle[1]
		if b != a:
			przrle[0] = 0
			this_file.seek(+2,1)
			
		przrle[1] = a
		przdata += 1
		przrle[0] +=1
		if przrle[0] > 0xFE:
			przrle[0] = 1
			this_file.seek(+2,1)
		this_file.write(chr(int(przrle[0]&0xFF)))
		this_file.write(chr(int(przrle[1]&0xFF)))
		this_file.seek(-2,1)
	else:
		this_file.write(chr(d&0xFF))
	i += 1
	c -= 1
	
this_file.write(chr(0xFF))
this_file.close()

# --------------
# Collision
# --------------

this_file = open(layfolder+"fg_col"+".bin","wb")		#collision
i = 0
c = len(layer_data[0])
while c:
	a = int( layer_data[2][i] )
	this_file.write(chr(a&0xFF))
	i += 1
	c -= 1
this_file.close()

# --------------
# Layout
# --------------

this_file = open(layfolder+"fg_lay_low"+".bin","wb")
i = 0
d = len(layer_data[0])
while d:
	a = int( layer_data[0][i] )
	i += 1
	c = a
	this_file.write(chr(c&0xFF))
	d -= 1
this_file.close()

this_file = open(layfolder+"fg_lay_hi"+".bin","wb")
i = 0
d = len(layer_data[0])
while d:
	a = int( layer_data[1][i] )
	i += 1
	c = a
	this_file.write(chr(c&0xFF))
	d -= 1
this_file.close()

# -------------------------------------------------
# Convert objects
# -------------------------------------------------

d = 0
c = len(obj_list) / 4
this_file = open(layfolder+"objlist.asm","wb")
if c != 0:
	while c:
		this_file.write("\t\tdc.l "+obj_list[0+d]+"\n")
		this_file.write("\t\tdc.w "+obj_list[2+d]+","+obj_list[3+d]+"\n")
		this_file.write("\t\tdc.b "+obj_list[1+d]+"\n")
		this_file.write("\t\tdc.b 0"+"\n")			# Unused byte
		this_file.write("\n")
		d += 4
		c -= 1

this_file.write("\t\tdc.l 0")
this_file.close()
	
input_file.close()

# -------------------------------------------------
# Convert graphics and blocks
# -------------------------------------------------

d0 = artfile#"map16.tga"
if d0 != "False":
	#d0 = sys.argv[2]
	input_file = open(d0,"rb")
	out_art    = open(artfolder+"lvl_art.bin","wb")
	out_pal    = open(artfolder+"lvl_pal.bin","wb")
	out_map    = open(artfolder+"lvl_blk.bin","wb")

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
	curr_block = 0
	
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
				if DOUBLE_MODE == True:
					d3 = grab_pal(d4)
					write_cell(d4)
					cells_used += 1
					d1=map_vram
					cells_list.append(d2)
					cells_list.append(d1)
					cells_list.append(d3)
					map_vram+=1
				else:
					if d2 != 0:
						if chks_dupl(d2)[0] == True:
							d1=chks_dupl(d2)[1]
							d3=chks_dupl(d2)[2]
						else:
							d3 = grab_pal(d4)
							write_cell(d4)
							cells_used += 1
							d1=map_vram
							cells_list.append(d2)
							cells_list.append(d1)
							cells_list.append(d3)
							map_vram+=1
						
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
				
				#--
				#X-
				d4 = (image_addr+seek_cell(x_pos,y_pos+1))
				d2 = chks_make(d4)
				d1 = 0
				d3 = 0
				if DOUBLE_MODE == True:
					d3 = grab_pal(d4)
					write_cell(d4)
					cells_used += 1
					d1=map_vram
					cells_list.append(d2)
					cells_list.append(d1)
					cells_list.append(d3)
					map_vram+=1
				else:
					if d2 != 0:
						if chks_dupl(d2)[0] == True:
							d1=chks_dupl(d2)[1]
							d3=chks_dupl(d2)[2]
						else:
							d3 = grab_pal(d4)
							write_cell(d4)
							cells_used += 1
							d1=map_vram
							cells_list.append(d2)
							cells_list.append(d1)
							cells_list.append(d3)
							map_vram+=1
						
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
				
				#-X
				#--
				d4 = (image_addr+seek_cell(x_pos+1,y_pos))
				d2 = chks_make(d4)
				d1 = 0
				d3 = 0
				if DOUBLE_MODE == True:
					d3 = grab_pal(d4)
					write_cell(d4)
					cells_used += 1
					d1=map_vram
					cells_list.append(d2)
					cells_list.append(d1)
					cells_list.append(d3)
					map_vram+=1
				else:
					if d2 != 0:
						if chks_dupl(d2)[0] == True:
							d1=chks_dupl(d2)[1]
							d3=chks_dupl(d2)[2]
						else:
							d3 = grab_pal(d4)
							write_cell(d4)
							cells_used += 1
							d1=map_vram
							cells_list.append(d2)
							cells_list.append(d1)
							cells_list.append(d3)
							map_vram+=1
						
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
				
				#--
				#-X
				d4 = (image_addr+seek_cell(x_pos+1,y_pos+1))
				d2 = chks_make(d4)
				d1 = 0
				d3 = 0
				if DOUBLE_MODE == True:
					d3 = grab_pal(d4)
					write_cell(d4)
					cells_used += 1
					d1=map_vram
					cells_list.append(d2)
					cells_list.append(d1)
					cells_list.append(d3)
					map_vram+=1
				else:
					if d2 != 0:
						if chks_dupl(d2)[0] == True:
							d1=chks_dupl(d2)[1]
							d3=chks_dupl(d2)[2]
						else:
							d3 = grab_pal(d4)
							write_cell(d4)
							cells_used += 1
							d1=map_vram
							cells_list.append(d2)
							cells_list.append(d1)
							cells_list.append(d3)
							map_vram+=1
						
				out_map.write(chr(int((d1+d3&0xFF00)>>8)&0xFF)+chr(int(d1+d3)&0xFF))
			
			curr_block += 1
			
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

print "LEVEL",layfile,"| SIZE:",lay_xsize,lay_ysize,"| RLE Prz SIZE:",przdata
input_file.close()
