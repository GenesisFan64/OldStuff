#======================================================================
# Level converter for Genny
# GAME GEAR VERSION
#
# STABLE
#
# image order:
# filler
# collision
# lowprio
# hiprio
# 
# byte sizes:
# blocks:    WORD
# layout:    WORD
# collision: BYTE
#======================================================================

#======================================================================
# -------------------------------------------------
# Settings
# -------------------------------------------------

MAX_LAYERS  = 5
DOUBLE_MODE = False

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
  
#def write_line(in_offset):
  #input_file.seek(in_offset)
  
  #a = int(get_val(input_file.read(1)),16) & 0x0F
  #b = int(get_val(input_file.read(1)),16) & 0x0F
  #c = int(get_val(input_file.read(1)),16) & 0x0F
  #d = int(get_val(input_file.read(1)),16) & 0x0F
  #e = int(get_val(input_file.read(1)),16) & 0x0F
  #f = int(get_val(input_file.read(1)),16) & 0x0F
  #g = int(get_val(input_file.read(1)),16) & 0x0F
  #h = int(get_val(input_file.read(1)),16) & 0x0F
      
  #a = a << 4
  #a = a+b
  #c = c << 4
  #c = c+d
  #e = e << 4
  #e = e+f
  #g = g << 4
  #g = g+h
      
  #out_art.write(chr(a))
  #out_art.write(chr(c))
  #out_art.write(chr(e))
  #out_art.write(chr(g))

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

def seek_col_cell(x,y):
  x = x<<3
  y = y*(16*8)
  
  out_offset=x+y
  return(out_offset)

def chks_make(lay):
  d7 = 0
  
  d4 = 0
  d1 = 16
  while d1:
    input_file.seek(lay)
    d2 = 16
    while d2:
      byte = int(get_val(input_file.read(1)),16)
      if byte != 0:
	if byte < byte_trans:
	  d3 = byte + d4 + (d7 & 0xFFFFF)
	  d7 += d3
      d4 += 1
      d2 -= 1
    d4 = 0
    lay += x_size
    d1 -= 1

  return(d7)

def chks_make_colonly(lay):
  d7 = 0
  
  d4 = 0
  d1 = 16
  while d1:
    input_file.seek(lay)
    d2 = 16
    while d2:
      byte = int(get_val(input_file.read(1)),16)
      if byte == byte_trans:
	byte = 0
      if byte != 0:
	byte = 1
        d3 = byte + d4# + (d7 & 0xFFFF)
        d7 += d3
	
      d4 += 1
      d2 -= 1
    d4 = 0
    lay += x_size
    d1 -= 1

  return(d7)

def chks_col_make(lay):
  d7 = 0
  
  d4 = 0
  d1 = 16
  while d1:
    incol_file.seek(lay)
    d2 = 16
    while d2:
      byte = int(get_val(incol_file.read(1)),16)
      if byte == byte_trans:
	byte = 0
      if byte != 0:
	byte = 1
        d3 = byte + d4# + (d7 & 0xFFFF)
        d7 += d3
	
      d4 += 1
      d2 -= 1
    d4 = 0
    lay += 16
    d1 -= 1

  return(d7)

def chk_cell(lay):
  d5 = 0
  d7 = 0
  d6 = 0
  
  d4 = 0
  d1 = 8
  while d1:
    input_file.seek(lay)				#only check the first pixel of the cell
    a = int(get_val(input_file.read(1)),16)
    color = (a & 0xF0)
    if color == byte_trans:
      color = 0
    else:
      color = color >> 4 & 0x0F
    d6 = color << 0x0B
    
    input_file.seek(lay)
    d2 = 8
    while d2:
      a = int(get_val(input_file.read(1)),16)
      byte = a & 0x0F
      if byte != 0:
	d3 = byte + d4 + d5 + d7
	d7 += d3 + d4 + d5 + d7
      d4 += 1
      d2 -= 1
      
    d4 = 0
    d5 += 1
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

def col_find(layr_addr):
  incol_file.seek(0xC)					#$0C, xsize,ysize (little endian)
  x_r = int(get_val(incol_file.read(1)),16)
  x_l = (int(get_val(incol_file.read(1)),16)<<8)
  x_size = x_l+x_r
  y_r = int(get_val(incol_file.read(1)),16)
  y_l = (int(get_val(incol_file.read(1)),16)<<8)
  y_size = (y_l+y_r)
  
  incol_file.seek(0x18)
  layr_col      = incol_file.tell()
  layr_start	= layr_addr

  a = chks_make_colonly(layr_start)
  
  colchk = 0
  colid = 0
  coly = (y_size>>4)
  while coly:
    e = chks_col_make(layr_col)
    
    if a == e:
      colid = colchk

    colchk += 1
    layr_col += 0x100
    coly -= 1
  
  return(colid)

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

list_usedblks    = list()
list_usedblks_hi = list()
list_usedcells	 = list()
cells_used = 0

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

print "* Converting *"
print "DOUBLE MODE is:",DOUBLE_MODE

input_file = open("layout.tga","rb")
incol_file = open("colmap.tga","rb")
out_art    = open("../lvl_art.bin","wb")
out_pal    = open("../lvl_pal.bin","wb")
out_blk    = open("../lvl_blk.bin","wb")
out_lay    = open("../lvl_lay.bin","wb")
out_col    = open("../lvl_col.bin","wb")

input_file.seek(0x5)					#$05, palsize
size_pal = int(get_val(input_file.read(1)),16)-1
byte_trans = size_pal

input_file.seek(0xC)					#$0C, xsize,ysize (little endian)
x_r = int(get_val(input_file.read(1)),16)
x_l = (int(get_val(input_file.read(1)),16)<<8)
x_size = x_l+x_r
y_r = int(get_val(input_file.read(1)),16)
y_l = (int(get_val(input_file.read(1)),16)<<8)
y_size = (y_l+y_r)/MAX_LAYERS

# ----------------------
# Write layout size
# dc.w xsize
# dc.w ysize
# ----------------------

lay_x = x_size>>4
lay_y = y_size>>4
out_lay.write(
  chr(int(lay_x)&0xFF)
  +
  chr(int((lay_x&0xFF00)>>8)&0xFF)
  +
  chr(int(lay_y)&0xFF)
  +
  chr(int((lay_y&0xFF00)>>8)&0xFF)
  )

# ----------------------
# Write palette
# ----------------------

input_file.seek(0x12)
d0 = size_pal
while d0:
  b = int(get_val(input_file.read(1)),16)
  g = int(get_val(input_file.read(1)),16)
  r = int(get_val(input_file.read(1)),16)
  x = int(get_val(input_file.read(1)),16)
  r = r >> 4
  g = g >> 4
  b = b >> 4
  g = g << 4
  gr = g+r
  out_pal.write(chr(gr))
  out_pal.write(chr(b))
  d0 -= 1

# ----------------------
# Make NULL block
# ----------------------

out_art.write(chr(0)*0x20)
d0 = 0x0000
d1 = 0x0000
out_blk.write(
  chr(int(d0)&0xFF)
  +
  chr(int((d0&0xFF00)>>8)&0xFF)
  +
  chr(int(d0)&0xFF)
  +
  chr(int((d0&0xFF00)>>8)&0xFF)
  +
  chr(int(d1)&0xFF)
  +
  chr(int((d1&0xFF00)>>8)&0xFF)
  +
  chr(int(d1)&0xFF)
  +
  chr(int((d1&0xFF00)>>8)&0xFF)
  )

#======================================================================
# -------------------------------------------------
# The best part
# -------------------------------------------------

input_file.seek(4,True)					#Image data

# ----------------------
# Filler
# ----------------------

input_file.seek(x_size*y_size,True)			#Skip first part

# ----------------------
# FG
# ----------------------

blk_vram  = 1
lay_start = 1
lay_x     = x_size>>4
lay_y     = y_size>>4

#LOW priority
layfg_low      = input_file.tell()
layfg_low_copy = layfg_low

#HIGH priority
input_file.seek(x_size*y_size,True)
layfg_hi      = input_file.tell()
layfg_hi_copy = layfg_hi

#Collision
input_file.seek(x_size*y_size,True)
layfg_col      = input_file.tell()
layfg_col_copy = layfg_col


while lay_y:
  
  while lay_x:
    layout_result = 0
    col_result    = 0
    
    # ----------------
    # Collision
    # ----------------
    
    layr_off = layfg_col + (seek_cell(0,0))
    a = chks_make(layr_off)
    if a != 0:
      col_result = col_find(layr_off)

    # ----------------
    # LOW Prio
    # ----------------
    
    layr_off = layfg_low + (seek_cell(0,0))
    if chks_make(layr_off) != 0:
      result = chks_make(layr_off)
      
      # SAME BLOCK
      if chks_dupl(list_usedblks,7,result)[0] == True:
	layout_result = chks_dupl(list_usedblks,7,result)[1]
	
      # NEW BLOCK
      else:
	if chks_dupl(list_usedblks_hi,7,result)[0] == True:
	  gotvram = chks_dupl(list_usedblks_hi,7,result)[3]
          out_blk.write(chr(int(gotvram)&0xFF)+chr(int((gotvram&0xFF00)>>8)&0xFF))
	  gotvram = chks_dupl(list_usedblks_hi,7,result)[4]
          out_blk.write(chr(int(gotvram)&0xFF)+chr(int((gotvram&0xFF00)>>8)&0xFF))
	  gotvram = chks_dupl(list_usedblks_hi,7,result)[5]
          out_blk.write(chr(int(gotvram)&0xFF)+chr(int((gotvram&0xFF00)>>8)&0xFF))
	  gotvram = chks_dupl(list_usedblks_hi,7,result)[6]
          out_blk.write(chr(int(gotvram)&0xFF)+chr(int((gotvram&0xFF00)>>8)&0xFF))
            
          layout_result = lay_start
          lay_start += 1
            
	else:
	  list_usedblks.append(result)							#chksum
  	  list_usedblks.append(lay_start)						#lay id
	  list_usedblks.append(2)							#page (2 - low prio)
          layr_off = layfg_low + (seek_cell(0,0))
          d0 = blk_vram
          d1 = chk_cell(layr_off)[0]
          d2 = chk_cell(layr_off)[1]
          d0 += d2
          
          #Double intrelaced
          if DOUBLE_MODE == True:
	    write_cell(layr_off)
	    list_usedcells.append(chk_cell(layr_off)[0])
	    list_usedcells.append(d0)
	    blk_vram += 1
	    
	  #Normal
	  else:
	    if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            
          out_blk.write(chr(int(d0)&0xFF)+chr(int((d0&0xFF00)>>8)&0xFF))
	  list_usedblks.append(d0)							#vram (1)  
          layr_off = layfg_low + (seek_cell(0,1))
          d0 = blk_vram
          d1 = chk_cell(layr_off)[0]
          d2 = chk_cell(layr_off)[1]
          d0 += d2
          
          #Double intrelaced
          if DOUBLE_MODE == True:
	    write_cell(layr_off)
	    list_usedcells.append(chk_cell(layr_off)[0])
	    list_usedcells.append(d0)
	    blk_vram += 1
	    
	  #Normal
	  else:
	    if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            
          out_blk.write(chr(int(d0)&0xFF)+chr(int((d0&0xFF00)>>8)&0xFF))
	  list_usedblks.append(d0)							#vram (2)  
          layr_off = layfg_low + (seek_cell(1,0))
          d0 = blk_vram
          d1 = chk_cell(layr_off)[0]
          d2 = chk_cell(layr_off)[1]
          d0 += d2
          
          #Double intrelaced
          if DOUBLE_MODE == True:
	    write_cell(layr_off)
	    list_usedcells.append(chk_cell(layr_off)[0])
	    list_usedcells.append(d0)
	    blk_vram += 1
	    
	  #Normal
	  else:
	    if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            
          out_blk.write(chr(int(d0)&0xFF)+chr(int((d0&0xFF00)>>8)&0xFF))
	  list_usedblks.append(d0)						#vram (3)  
          layr_off = layfg_low + (seek_cell(1,1))
          d0 = blk_vram
          d1 = chk_cell(layr_off)[0]
          d2 = chk_cell(layr_off)[1]
          d0 += d2
          
          #Double intrelaced
          if DOUBLE_MODE == True:
	    write_cell(layr_off)
	    list_usedcells.append(chk_cell(layr_off)[0])
	    list_usedcells.append(d0)
	    blk_vram += 1
	    
	  #Normal
	  else:
	    if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            
          out_blk.write(chr(int(d0)&0xFF)+chr(int((d0&0xFF00)>>8)&0xFF))
	  list_usedblks.append(d0)							#vram (4)  
        
          layout_result = lay_start
          lay_start += 1
    
    # ----------------
    # HI Prio
    # ----------------
    
    if layout_result == 0:
      layr_off = layfg_hi + (seek_cell(0,0))
      if chks_make(layr_off) != 0:
        result = chks_make(layr_off)
      
        # SAME BLOCK
        if chks_dupl(list_usedblks_hi,7,result)[0] == True:
	  layout_result = chks_dupl(list_usedblks_hi,7,result)[1]
	
        # NEW BLOCK
        else:
	  if chks_dupl(list_usedblks,7,result)[0] == True:
	    gotvram = chks_dupl(list_usedblks,7,result)[3]
            out_blk.write(chr(int(gotvram+0x1000)&0xFF)+chr(int((gotvram+0x1000&0xFF00)>>8)&0xFF))
	    gotvram = chks_dupl(list_usedblks,7,result)[4]
            out_blk.write(chr(int(gotvram+0x1000)&0xFF)+chr(int((gotvram+0x1000&0xFF00)>>8)&0xFF))
	    gotvram = chks_dupl(list_usedblks,7,result)[5]
            out_blk.write(chr(int(gotvram+0x1000)&0xFF)+chr(int((gotvram+0x1000&0xFF00)>>8)&0xFF))
	    gotvram = chks_dupl(list_usedblks,7,result)[6]
            out_blk.write(chr(int(gotvram+0x1000)&0xFF)+chr(int((gotvram+0x1000&0xFF00)>>8)&0xFF))
            
            layout_result = lay_start
            lay_start += 1
            
	  else:
	    list_usedblks_hi.append(result)						#chksum
  	    list_usedblks_hi.append(lay_start)						#lay id
	    list_usedblks_hi.append(3)							#page (3 - hi prio)
            layr_off = layfg_hi + (seek_cell(0,0))
            d0 = blk_vram
            d1 = chk_cell(layr_off)[0]
            d2 = chk_cell(layr_off)[1]
            d0 += d2

            #Double intrelaced
            if DOUBLE_MODE == True:
	      write_cell(layr_off)
	      list_usedcells.append(chk_cell(layr_off)[0])
	      list_usedcells.append(d0)
	      blk_vram += 1
	    #Normal
	    else:
	      if chkcell_dupl(d1)[0] == True:
	        d0 = chkcell_dupl(d1)[1]
	      else:
	        write_cell(layr_off)
                list_usedcells.append(chk_cell(layr_off)[0])
                list_usedcells.append(d0)
                blk_vram += 1
                
            out_blk.write(chr(int(d0+0x1000)&0xFF)+chr(int((d0+0x1000&0xFF00)>>8)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (1)
            layr_off = layfg_hi + (seek_cell(0,1))
            d0 = blk_vram
            d1 = chk_cell(layr_off)[0]
            d2 = chk_cell(layr_off)[1]
            d0 += d2

            #Double intrelaced
            if DOUBLE_MODE == True:
	      write_cell(layr_off)
	      list_usedcells.append(chk_cell(layr_off)[0])
	      list_usedcells.append(d0)
	      blk_vram += 1
	    #Normal
	    else:
	      if chkcell_dupl(d1)[0] == True:
	        d0 = chkcell_dupl(d1)[1]
	      else:
	        write_cell(layr_off)
                list_usedcells.append(chk_cell(layr_off)[0])
                list_usedcells.append(d0)
                blk_vram += 1
                
            out_blk.write(chr(int(d0+0x1000)&0xFF)+chr(int((d0+0x1000&0xFF00)>>8)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (2)
            layr_off = layfg_hi + (seek_cell(1,0))
            d0 = blk_vram
            d1 = chk_cell(layr_off)[0]
            d2 = chk_cell(layr_off)[1]
            d0 += d2

            #Double intrelaced
            if DOUBLE_MODE == True:
	      write_cell(layr_off)
	      list_usedcells.append(chk_cell(layr_off)[0])
	      list_usedcells.append(d0)
	      blk_vram += 1
	    #Normal
	    else:
	      if chkcell_dupl(d1)[0] == True:
	        d0 = chkcell_dupl(d1)[1]
	      else:
	        write_cell(layr_off)
                list_usedcells.append(chk_cell(layr_off)[0])
                list_usedcells.append(d0)
                blk_vram += 1
                
            out_blk.write(chr(int(d0+0x1000)&0xFF)+chr(int((d0+0x1000&0xFF00)>>8)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (3)
            layr_off = layfg_hi + (seek_cell(1,1))
            d0 = blk_vram
            d1 = chk_cell(layr_off)[0]
            d2 = chk_cell(layr_off)[1]
            d0 += d2

            #Double intrelaced
            if DOUBLE_MODE == True:
	      write_cell(layr_off)
	      list_usedcells.append(chk_cell(layr_off)[0])
	      list_usedcells.append(d0)
	      blk_vram += 1
	    #Normal
	    else:
	      if chkcell_dupl(d1)[0] == True:
	        d0 = chkcell_dupl(d1)[1]
	      else:
	        write_cell(layr_off)
                list_usedcells.append(chk_cell(layr_off)[0])
                list_usedcells.append(d0)
                blk_vram += 1
                
            out_blk.write(chr(int(d0+0x1000)&0xFF)+chr(int((d0+0x1000&0xFF00)>>8)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (4)
        
            layout_result = lay_start
            lay_start += 1
    
    # ----------------
    # Write layout
    # ----------------
 
    if col_result >= 255:
      col_result = 1
      
    if layout_result >= 255:
      print "WARNING: RAN OUT OF LAYOUT BLOCKS"
      
    #out_lay.write(chr(int((layout_result&0xFF00)>>8)&0xFF)+chr(int(layout_result)&0xFF))
    out_lay.write(chr(int(layout_result)&0xFF))
    out_col.write(chr(int(col_result)))
    
    # ----------------
    # Next block
    # ----------------
    
    layfg_low += seek_cell(2,0)
    layfg_hi  += seek_cell(2,0)
    layfg_col += seek_cell(2,0)
    
    lay_x -= 1
    
  layfg_low_copy += seek_cell(0,2)
  layfg_hi_copy  += seek_cell(0,2)
  layfg_col_copy += seek_cell(0,2)
  layfg_low       = layfg_low_copy
  layfg_hi        = layfg_hi_copy
  layfg_col       = layfg_col_copy
  lay_x           = x_size>>4
  
  lay_y -= 1
  
#======================================================================

print "layout blocks used:",hex(lay_start-1)
print "cells used:",hex(cells_used)
print "Done."
input_file.close()
incol_file.close()
out_art.close()
out_pal.close()
out_blk.close()
out_lay.close()
out_col.close()
