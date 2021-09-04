#======================================================================
# .raw.pal to VDP
# 
# STABLE
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
      
#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

#input_file=raw_input("Input: ")
#if input_file == "":
  #quit()

#output_file=raw_input("Output: ")
#if output_file == "":
  #quit()

#starts_at=raw_input("Start at (IN DECIMAL): ")
#if starts_at == "":
  #quit()
	  
input_file = open(sys.argv[1],"rb")
output_file = open(sys.argv[2],"wb")
option_mode = sys.argv[3]

if option_mode == "LUNAR2":
	print "FORMAT: LUNAR ETERNAL BLUE"
	print "Searching (poorly) for pcm data..."
	b = True
	input_file.seek(0)	# start from here
	while b:
		a = int(get_val(input_file.read(1)),16)
		if a == 0x80:
			input_file.seek(-2,1)
			print "Found data at:",hex(input_file.tell())
			b = False
	
else:
	input_file.seek(int(sys.argv[3]))
	output_file.seek(0)

# write the head
output_file.seek(0x0)
output_file.write("RIFF")
output_file.seek(0x8)
output_file.write("WAVEfmt ")
output_file.write(chr(16))	#size 16

output_file.seek(20)		#pcm=1
output_file.write(chr(1))
output_file.seek(22)		# MONO (1)
output_file.write(chr(1))
output_file.seek(24)		# 16000 in reverse
output_file.write(chr(0x80))
output_file.write(chr(0x3E))	
output_file.seek(28)		# same thing
output_file.write(chr(0x80))
output_file.write(chr(0x3E))

output_file.seek(0x20)
output_file.write(chr(0x01))
output_file.write(chr(0x00))
output_file.write(chr(0x08))
output_file.write(chr(0x00))
output_file.write("data")
output_file.seek(0x2C)

# lets go to work
working=True

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

print "Converting...."
while working:
	a = input_file.read(1)
	#input_file.seek(-1,1)
	if a == "":
		working = False
		break
	
	a = int(get_val(input_file.read(1)),16)
	
	#0x00 - 0x7F == [-128, -1]
	if a < 0x7F:
		a = 0x80 + a
		
	#0x80 - 0xFF == [0, 127]
	elif a >= 0x80:
		a = 0x80 - (a & ~0x80)
		
	output_file.write(chr(a&0xFF))

# ------------------
# Last steps
# ------------------

a = output_file.tell() - 0x2C
b = a + 36

output_file.seek(0x4)
output_file.write( chr(b&0xFF) )
output_file.write( chr(b>>8&0xFF) )
output_file.write( chr(b>>16&0xFF) )
output_file.write( chr(b>>24&0xFF) )

output_file.seek(0x28)
output_file.write( chr(a&0xFF) )
output_file.write( chr(a>>8&0xFF) )
output_file.write( chr(a>>16&0xFF) )
output_file.write( chr(a>>24&0xFF) )

# ----------------------------
# End
# ----------------------------

print "Done."
input_file.close()
output_file.close()    
