i=1
a=0

d7 = 512
while d7:
	d7 -= 1
	
	#value=(160*32)*i
	#i -= 0.1
	#print("\t\tdc.l",int(value))
	
	a = i
	if a == 0:
		print("ZERO")
		a = 1
	 
	value=((224/2)*32)/a
	if value == 0:
		value = 1
	i += 0.1 #0.048 stable
	b = round(value, 1)
	print("\t\tdc.l",int(b))
