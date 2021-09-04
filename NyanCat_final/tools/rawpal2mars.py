#======================================================================
# .raw.pal to VDP
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

input_file = open(input_file,"rb")
output_file = open(output_file,"wb")
input_file.seek(0)
output_file.seek(0)
working=True

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

print "* Converting *"
reading=True
while working:
  while reading:
    eof = input_file.read(1)
    input_file.seek(-1,1)
    if eof == "":
      reading=False
      break
    r = int(get_val(input_file.read(1)),16)
    g = int(get_val(input_file.read(1)),16)
    b = int(get_val(input_file.read(1)),16)
    r = r >> 3
    g = g >> 3
    b = b >> 3
  
    g = g << 5
    b = b << 10
    bgr = b+g+r&0x7FFF
    out_pal.write(chr(bgr>>8))
    out_pal.write(chr(bgr&0xFF))
  
  working=False
    
# ----------------------------
# End
# ----------------------------

print "Done."
input_file.close()
output_file.close()    