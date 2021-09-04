i=1
a=0
f=0

d7 = 512
while d7:
	d7 -= 1
	
	value=(112*32)*i
	i += 0.1
	print " dc.l",int(value)
	
	#a = i
	#if a == 0:
         #print "ZERO"
	 #a = 1
	 
	#value=(112)/a
	#if value == 0:
		#value = 1
	#i += 0.1
	#b = round(value, 1)
	#print " dc.l",int(b)