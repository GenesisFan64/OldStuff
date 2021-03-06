# ======================================================================
# OBJ TO MARS
# 
# STABLE
# ======================================================================

import sys

# ======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------

#test_list = 2,3,1,-3,-2,-2
#print sorted(test_list)

# ======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

SCALE_SIZE=40 #20 best
FROM_BLENDER=True #True
print "Scaling is at",SCALE_SIZE,"%"

# ======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

projectname   = sys.argv[1]

last_z        = 0
list_vertices = list()
list_faces    = list()
model_file    = open(projectname+".obj","r")
material_file = open(projectname+".mtl","r")
out_vertices  = open("../"+projectname+"_vrt.bin","wb")
out_faces     = open("../"+projectname+"_fce.bin","wb")

used_triangles= 0
used_quads    = 0
solidcolor    = 1
randomcolor   = 1
textureid     = 0x8000
last_texture  = False
mtl_texture   = False
nomtl_mode    = False
reading       = True
      
# ======================================================================
# -------------------------------------------------
# Getting data
# -------------------------------------------------

while reading:
  text=model_file.readline()
  if text=="":
    reading=False
    
  # ---------------------------
  # MATERIAL include
  # ---------------------------
  
  if text.find("usemtl") == False:
    mtlstr = text[7:].rstrip('\r\n')
    a = mtlstr.split("_")
    if a[0] == "pal":
      nomtl_mode  = False
      mtl_texture = False
      b = a[1].split(".")
      a = int(b[0])
      solidcolor = a
    elif a[0] == "material":
      nomtl_mode  = False
      mtl_texture = False
      a = int(a[1])
      if a == 0:
	a += 1
      solidcolor = a
    elif a[0] == "tex":
      nomtl_mode  = False
      mtl_texture = True
      b = a[1].split(".")
      a = int(b[0])
      if b[0] != last_texture:
	if last_texture != False:
	  textureid = 0x8000+int(b[0])-1
      last_texture = b[0] 
    else:
      nomtl_mode  = True
      mtl_texture = False
      
  # ---------------------------
  # vertices
  # ---------------------------
  
  if text.find("v") == False: 
    a = text[2:]
    point = a.split(" ")
    if point[0] != "":
      x=float(point[0])
      y=float(point[1])
      z=float(point[2])
      if z*SCALE_SIZE < last_z:
	last_z = int(z*SCALE_SIZE)*2
        
      # X pos
      mars_x=int(x*SCALE_SIZE)*-1
      
      # Y pos
      if FROM_BLENDER == True:
	mars_y=int((y*SCALE_SIZE)*-1)+(SCALE_SIZE/2)
      else:
        mars_y=int(y*SCALE_SIZE)*-1
        
      # Z pos
      mars_z=int(z*SCALE_SIZE)*-1
      
      #d3 = mars_x >> 24 & 0xFF
      #d2 = mars_x >> 16 & 0xFF
      #d1 = mars_x >> 8 & 0xFF
      #d0 = mars_x & 0xFF
      #out_vertices.write(chr(d3))
      #out_vertices.write(chr(d2))
      #out_vertices.write(chr(d1))
      #out_vertices.write(chr(d0))

      #d3 = mars_y >> 24 & 0xFF
      #d2 = mars_y >> 16 & 0xFF
      #d1 = mars_y >> 8 & 0xFF
      #d0 = mars_y & 0xFF
      #out_vertices.write(chr(d3))
      #out_vertices.write(chr(d2))
      #out_vertices.write(chr(d1))
      #out_vertices.write(chr(d0))
      
      #d3 = mars_z >> 24 & 0xFF
      #d2 = mars_z >> 16 & 0xFF
      #d1 = mars_z >> 8 & 0xFF
      #d0 = mars_z & 0xFF
      #out_vertices.write(chr(d3))
      #out_vertices.write(chr(d2))
      #out_vertices.write(chr(d1))
      #out_vertices.write(chr(d0))
      
      outx_l = mars_x >> 8 & 0xFF
      outx_r = mars_x & 0xFF
      outy_l = mars_y >> 8 & 0xFF
      outy_r = mars_y & 0xFF
      outz_l = mars_z >> 8 & 0xFF
      outz_r = mars_z & 0xFF
      out_vertices.write(chr(outx_l))
      out_vertices.write(chr(outx_r))
      out_vertices.write(chr(outy_l))
      out_vertices.write(chr(outy_r))
      out_vertices.write(chr(outz_l))
      out_vertices.write(chr(outz_r))
    
  # ---------------------------
  # Faces
  # ---------------------------
  
  if text.find("f") == False:
    a = text[2:]
    point = a.split(" ")
    if len(point) == 3:
      x_chk=point[0].split("/")
      y_chk=point[1].split("/")
      z_chk=point[2].split("/")
      x=int(x_chk[0])-1
      y=int(y_chk[0])-1
      z=int(z_chk[0])-1
    
      out_faces.write(chr(0))
      out_faces.write(chr(3))
      if mtl_texture == True:
        #out_l = textureid >> 8 & 0xFF
        #out_r = textureid & 0xFF
        this_texture = last_texture.split(".")
	print "POLY Texture:",hex(int(this_texture[0]))
        out_l = (0x8000+int(this_texture[0])) >> 8 & 0xFF
        out_r = (0x8000+int(this_texture[0])) & 0xFF    
        out_faces.write(chr(out_l))
        out_faces.write(chr(out_r))
      else:
	if nomtl_mode == True:
	  solidcolor=randomcolor
	  randomcolor+=1
	  if randomcolor >= 255:
	    randomcolor=1
        out_l = solidcolor >> 8 & 0xFF
        out_r = solidcolor & 0xFF
        out_faces.write(chr(out_l))
        out_faces.write(chr(out_r))
      
      #solidcolor+=1
      #if solidcolor == 255:
	#solidcolor=1
	
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      out_faces.write(chr(outx_l))
      out_faces.write(chr(outx_r))
      out_faces.write(chr(outy_l))
      out_faces.write(chr(outy_r))
      out_faces.write(chr(outz_l))
      out_faces.write(chr(outz_r))
      used_triangles += 1
      
    if len(point) == 4:
      x_chk=point[0].split("/")
      y_chk=point[1].split("/")
      z_chk=point[2].split("/")
      q_chk=point[3].split("/")
      
      x=int(x_chk[0])-1
      y=int(y_chk[0])-1
      z=int(z_chk[0])-1
      q=int(q_chk[0])-1
      
      out_faces.write(chr(0))
      out_faces.write(chr(4))
      if mtl_texture == True:
        #out_l = textureid >> 8 & 0xFF
        #out_r = textureid & 0xFF
        this_texture = last_texture.split(".")
	print "QUAD Texture:",hex(int(this_texture[0]))
        out_l = (0x8000+int(this_texture[0])) >> 8 & 0xFF
        out_r = (0x8000+int(this_texture[0])) & 0xFF  
        out_faces.write(chr(out_l))
        out_faces.write(chr(out_r))
      else:
	if nomtl_mode == True:
	  solidcolor=randomcolor
	  randomcolor+=1
	  if randomcolor >= 255:
	    randomcolor=1
        out_l = solidcolor >> 8 & 0xFF
        out_r = solidcolor & 0xFF
        out_faces.write(chr(out_l))
        out_faces.write(chr(out_r))
	
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      outq_l = q >> 8 & 0xFF
      outq_r = q & 0xFF
      out_faces.write(chr(outq_l))
      out_faces.write(chr(outq_r))
      out_faces.write(chr(outx_l))
      out_faces.write(chr(outx_r))
      out_faces.write(chr(outy_l))
      out_faces.write(chr(outy_r))
      out_faces.write(chr(outz_l))
      out_faces.write(chr(outz_r))
      used_quads += 1

#======================================================================
# ----------------------------
# End
# ----------------------------

print "Used triangles:",used_triangles
print "    Used quads:",used_quads
print "     All faces:",used_triangles+used_quads
print "Start Z (aprx):",last_z
print "Done."
model_file.close()
material_file.close()
out_vertices.close()
out_faces.close()
