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

input_file.seek(0x40)
algor = int(get_val(input_file.read(1)),16)
feedb = int(get_val(input_file.read(1)),16)
a = algor&0x7 | ((feedb&0x7)<<3)
output_file.write(chr(a))

# ------------------
# Deptune/Multiple
# ------------------
e=0x0
input_file.seek(e)
a = int(get_val(input_file.read(1)),16)
input_file.seek(e+0x20)
b = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x10)
c = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x30)
d = int(get_val(input_file.read(1)),16) 
output_file.write(chr(a))
output_file.write(chr(b))
output_file.write(chr(c))
output_file.write(chr(d))

# ------------------
# RateScaling/Attack
# ------------------
e=0x2
input_file.seek(e)
a = int(get_val(input_file.read(1)),16)
input_file.seek(e+0x20)
b = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x10)
c = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x30)
d = int(get_val(input_file.read(1)),16) 
output_file.write(chr(a))
output_file.write(chr(b))
output_file.write(chr(c))
output_file.write(chr(d))

# ------------------
# LFO/first decay
# ------------------
e=0x3
input_file.seek(e)
a = int(get_val(input_file.read(1)),16)
input_file.seek(e+0x20)
b = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x10)
c = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x30)
d = int(get_val(input_file.read(1)),16) 
output_file.write(chr(a))
output_file.write(chr(b))
output_file.write(chr(c))
output_file.write(chr(d))

# ------------------
# Second decay/Sustain
# ------------------
e=0x4
input_file.seek(e)
a = int(get_val(input_file.read(1)),16)
input_file.seek(e+0x20)
b = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x10)
c = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x30)
d = int(get_val(input_file.read(1)),16) 
output_file.write(chr(a))
output_file.write(chr(b))
output_file.write(chr(c))
output_file.write(chr(d))

# ------------------
# First decay
# ------------------
e=0x5
input_file.seek(e)
a = int(get_val(input_file.read(1)),16)
input_file.seek(e+0x20)
b = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x10)
c = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x30)
d = int(get_val(input_file.read(1)),16) 
output_file.write(chr(a))
output_file.write(chr(b))
output_file.write(chr(c))
output_file.write(chr(d))

# ------------------
# Total level
# ------------------
e=0x1
input_file.seek(e)
a = int(get_val(input_file.read(1)),16)
input_file.seek(e+0x20)
b = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x10)
c = int(get_val(input_file.read(1)),16) 
input_file.seek(e+0x30)
d = int(get_val(input_file.read(1)),16) 
output_file.write(chr(a))
output_file.write(chr(b))
output_file.write(chr(c))
output_file.write(chr(d))

#reading=True
#while working:
  #while reading:
    #eof = input_file.read(1)
    #input_file.seek(-1,1)
    #if eof == "":
      #reading=False
      #break
    
    #r = int(get_val(input_file.read(1)),16)
    #output_file.write(chr(r))
  
  #working=False
    
# ----------------------------
# End
# ----------------------------

print "Done."
input_file.close()
output_file.close()    