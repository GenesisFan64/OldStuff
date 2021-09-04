import pygame, sys, math
  
class Cam:
  def __init__(self,pos=(0,0,0),rot=(0,0)):
    self.pos=list(pos)
    self.rot=list(rot)
    
  def update(self,dt,key):
    s = dt*10
    
    if key(pygame.K_q): self.pos[1]-=s
    if key(pygame.K_e): self.pos[1]+=s
    
    if key(pygame.K_w): self.pos[2]+=s
    if key(pygame.K_a): self.pos[2]-=s
    if key(pygame.K_s): self.pos[0]-=s
    if key(pygame.K_d): self.pos[0]+=s
    
pygame.init()
w,h = 320,224; cx,cy = w/2,h/2
screen = pygame.display.set_mode((w,h))
#clock = pygame.time.clock()

verts = (-64,-64,-64),(64,-64,-64),(64,64,-64), (-64,64,-64), (-64,-64,64),(64,-64,64),(64,64,64),(-64,64,64)
edges = (0,1),(1,2),(2,3),(3,0),(4,5),(5,6),(6,7),(7,4),(0,4),(1,5),(2,6),(3,7)

cam = Cam((0,0,0))

lel = 0
while True:
  dt = 0#clock.tick()/1000
  
  for event in pygame.event.get():
    if event.type == pygame.QUIT: pygame.quit(); sys.exit()
  
  screen.fill((255,255,255))
  
  #for x,y,z in verts:
    #z += 5
    
    #f = 200/z
    #x,y = x*f,y*f
    
    #pygame.draw.circle(screen,(0,0,0),(cx+int(x),cy+int(y)),6)
    
  for edge in edges:
    c = 0
    points = []
    for x,y,z in ( verts[edge[0]], verts[edge[1]] ):
      x-=0
      y-=0
      z+=lel
      
      if z ==0:
        z = 1#0.0001
	
      f = 160/z
      print( z,f )
      x,y = x*f,y*f
      #print f
      #print cx+int(x),cx+int(y)
      #print cx+int(x),cy+int(y)   
      points += [ ( cx+int(x),cy+int(y) ) ]
    pygame.draw.line(screen,(0,0,0),points[0],points[1],1)
  
  #print lel
  lel+=0.1
  pygame.display.flip()
  key = pygame.key.get_pressed()
  #cam.update(dt,key)
  
  
