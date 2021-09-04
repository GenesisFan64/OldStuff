#======================================================================
# .raw to VDP
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

def writeline(in_offset):
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
      
  output_file.write(chr(a))
  output_file.write(chr(c))
  output_file.write(chr(e))
  output_file.write(chr(g))
      
#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

working=False
mode=0

input_file=raw_input("Input: ")
if input_file == "":
  quit()

output_file=raw_input("Output: ")
if output_file == "":
  quit()

width = float(raw_input("Width: "))
if width == "":
  quit()
  
height = float(raw_input("Height: "))
if height == "":
  quit()

ask_mode=raw_input("normal, sPrite, sTamp or Quit? ")
if ask_mode == "p":
  mode=1
if ask_mode == "t":
  mode=2
if ask_mode == "q":
  quit()

input_file = open(input_file,"rb")
output_file = open(output_file,"wb")
input_file.seek(0)
output_file.seek(0)
working=True

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

while working:

# ----------------------------
# Converting to Stamps
# ----------------------------

  if mode == 2:
    print("* Converting to stamp order *")
    print("(nothing)")
    working=False
    break

# ----------------------------
# Converting to Sprites
# ----------------------------

  if mode == 1:
    print("* Converting to sprite order *")
    print("(nothing)")
    working=False
    break
    
# ----------------------------
# Converting normally 
# ----------------------------

  else:
    print("* Converting normally *")
    reading=True
    while reading:
      d2 = height/8
      offset = 0
      while d2:
	offset_n = offset
        d1 = width/8
        while d1:
	  offset_cell = offset_n
	  d0 = 8
	  while d0:
	    writeline(offset_cell)
	    offset_cell += width
	    d0 -= 1
	  offset_n += 8
	  d1 -=1
	offset += width*8
	d2 -=1
      reading=False
    working=False
    
# ----------------------------
# End
# ----------------------------

print "Done."
input_file.close()
output_file.close()    