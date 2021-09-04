#======================================================================
# Level converter for Genny
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
  d1 = 16
  while d1:
    input_file.seek(lay)
    d2 = 16
    while d2:
      byte = int(get_val(input_file.read(1)),16)
      if byte != 0:
	if byte < 0x30:
	  d3 = byte + d4 + (d7 & 0xFFFF)
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
    if color == byte_trans:
      color = 0
    else:
      color = color >> 4 & 0x0F
    d6 = color << 0x0D
    
    input_file.seek(lay)
    d2 = 8
    while d2:
      a = int(get_val(input_file.read(1)),16)
      byte = a & 0x0F
      if byte != 0:
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

MAX_LAYERS = 4

list_usedblks    = list()
list_usedblks_hi = list()
list_usedcells	 = list()
cells_used = 0

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

print "* Converting *"
input_file = open("layout.tga","rb")
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
  chr(int((lay_x&0xFF00)>>8)&0xFF)
  +
  chr(int(lay_x)&0xFF)
  +
  chr(int((lay_y&0xFF00)>>8)&0xFF)
  +
  chr(int(lay_y)&0xFF)
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

out_art.write(chr(0)*0x40)
d0 = 0x0000
d1 = 0x0001
out_blk.write(
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

blk_vram  = 2
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
    if chks_make(layr_off) != 0:
      col_result = 1

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
          out_blk.write(chr(int((gotvram&0xFF00)>>8)&0xFF)+chr(int(gotvram)&0xFF))
	  gotvram = chks_dupl(list_usedblks_hi,7,result)[4]
          out_blk.write(chr(int((gotvram&0xFF00)>>8)&0xFF)+chr(int(gotvram)&0xFF))
	  gotvram = chks_dupl(list_usedblks_hi,7,result)[5]
          out_blk.write(chr(int((gotvram&0xFF00)>>8)&0xFF)+chr(int(gotvram)&0xFF))
	  gotvram = chks_dupl(list_usedblks_hi,7,result)[6]
          out_blk.write(chr(int((gotvram&0xFF00)>>8)&0xFF)+chr(int(gotvram)&0xFF))
            
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
          if chkcell_dupl(d1)[0] == True:
	    d0 = chkcell_dupl(d1)[1]
	  else:
	    write_cell(layr_off)
            list_usedcells.append(chk_cell(layr_off)[0])
            list_usedcells.append(d0)
            blk_vram += 1
          out_blk.write(chr(int((d0&0xFF00)>>8)&0xFF)+chr(int(d0)&0xFF))
	  list_usedblks.append(d0)							#vram (1)  
          layr_off = layfg_low + (seek_cell(1,0))
          d0 = blk_vram
          d1 = chk_cell(layr_off)[0]
          d2 = chk_cell(layr_off)[1]
          d0 += d2
          if chkcell_dupl(d1)[0] == True:
	    d0 = chkcell_dupl(d1)[1]
	  else:
	    write_cell(layr_off)
            list_usedcells.append(chk_cell(layr_off)[0])
            list_usedcells.append(d0)
            blk_vram += 1
          out_blk.write(chr(int((d0&0xFF00)>>8)&0xFF)+chr(int(d0)&0xFF))
	  list_usedblks.append(d0)							#vram (2)  
          layr_off = layfg_low + (seek_cell(0,1))
          d0 = blk_vram
          d1 = chk_cell(layr_off)[0]
          d2 = chk_cell(layr_off)[1]
          d0 += d2
          if chkcell_dupl(d1)[0] == True:
	    d0 = chkcell_dupl(d1)[1]
	  else:
	    write_cell(layr_off)
            list_usedcells.append(chk_cell(layr_off)[0])
            list_usedcells.append(d0)
            blk_vram += 1
          out_blk.write(chr(int((d0&0xFF00)>>8)&0xFF)+chr(int(d0)&0xFF))
	  list_usedblks.append(d0)						#vram (3)  
          layr_off = layfg_low + (seek_cell(1,1))
          d0 = blk_vram
          d1 = chk_cell(layr_off)[0]
          d2 = chk_cell(layr_off)[1]
          d0 += d2
          if chkcell_dupl(d1)[0] == True:
	    d0 = chkcell_dupl(d1)[1]
	  else:
	    write_cell(layr_off)
            list_usedcells.append(chk_cell(layr_off)[0])
            list_usedcells.append(d0)
            blk_vram += 1
          out_blk.write(chr(int((d0&0xFF00)>>8)&0xFF)+chr(int(d0)&0xFF))
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
            out_blk.write(chr(int((gotvram+0x8000&0xFF00)>>8)&0xFF)+chr(int(gotvram+0x8000)&0xFF))
	    gotvram = chks_dupl(list_usedblks,7,result)[4]
            out_blk.write(chr(int((gotvram+0x8000&0xFF00)>>8)&0xFF)+chr(int(gotvram+0x8000)&0xFF))
	    gotvram = chks_dupl(list_usedblks,7,result)[5]
            out_blk.write(chr(int((gotvram+0x8000&0xFF00)>>8)&0xFF)+chr(int(gotvram+0x8000)&0xFF))
	    gotvram = chks_dupl(list_usedblks,7,result)[6]
            out_blk.write(chr(int((gotvram+0x8000&0xFF00)>>8)&0xFF)+chr(int(gotvram+0x8000)&0xFF))
            
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
            if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            out_blk.write(chr(int((d0+0x8000&0xFF00)>>8)&0xFF)+chr(int(d0+0x8000)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (1)
            layr_off = layfg_hi + (seek_cell(1,0))
            d0 = blk_vram
            d1 = chk_cell(layr_off)[0]
            d2 = chk_cell(layr_off)[1]
            d0 += d2
            if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            out_blk.write(chr(int((d0+0x8000&0xFF00)>>8)&0xFF)+chr(int(d0+0x8000)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (2)
            layr_off = layfg_hi + (seek_cell(0,1))
            d0 = blk_vram
            d1 = chk_cell(layr_off)[0]
            d2 = chk_cell(layr_off)[1]
            d0 += d2
            if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            out_blk.write(chr(int((d0+0x8000&0xFF00)>>8)&0xFF)+chr(int(d0+0x8000)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (3)
            layr_off = layfg_hi + (seek_cell(1,1))
            d0 = blk_vram
            d1 = chk_cell(layr_off)[0]
            d2 = chk_cell(layr_off)[1]
            d0 += d2
            if chkcell_dupl(d1)[0] == True:
	      d0 = chkcell_dupl(d1)[1]
	    else:
	      write_cell(layr_off)
              list_usedcells.append(chk_cell(layr_off)[0])
              list_usedcells.append(d0)
              blk_vram += 1
            out_blk.write(chr(int((d0+0x8000&0xFF00)>>8)&0xFF)+chr(int(d0+0x8000)&0xFF))
	    list_usedblks_hi.append(d0)						#vram (4)
        
            layout_result = lay_start
            lay_start += 1
    
    # ----------------
    # Write layout
    # ----------------
 
    if col_result >= 255:
      col_result = 1
      
    out_lay.write(chr(int((layout_result&0xFF00)>>8)&0xFF)+chr(int(layout_result)&0xFF))
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
out_art.close()
out_pal.close()
out_blk.close()
out_lay.close()
out_col.close()
