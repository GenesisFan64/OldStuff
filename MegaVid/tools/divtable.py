divdata = open("divtable.bin","wb")
one = 0x80000000
i = 2.0

int_out = 0x7FFFFFFF
a = '%x' % int(int_out>>24&0xFF)
b = '%x' % int(int_out>>16&0xFF)
c = '%x' % int(int_out>>8&0xFF)
d = '%x' % int(int_out&0xFF)
divdata.write(chr(int(a,16)))
divdata.write(chr(int(b,16)))
divdata.write(chr(int(c,16)))
divdata.write(chr(int(d,16)))

while i<= 640.0:
  value = int( ((1.0 / i)*one) )
  if (value == 0x80000000):
    value = 0x7fffffff
    
  a = '%x' % int(value>>24&0xFF)
  b = '%x' % int(value>>16&0xFF)
  c = '%x' % int(value>>8&0xFF)
  d = '%x' % int(value&0xFF)
  divdata.write(chr(int(a,16)))
  divdata.write(chr(int(b,16)))
  divdata.write(chr(int(c,16)))
  divdata.write(chr(int(d,16)))
  i += 1.0

divdata.close()

#void main(void)

#{
	#int value, count;
	#double i, one;

	#one  = 0x80000000;

	#printf("\tdc.l $%08x", one);
	#count = 1;

	#i = 2.0;

	#while (i <= 320.0) {

		#value = (int) ((1.0 / i) * one);

		#if (value == 0x80000000)
			#value = 0x7fffffff;

		#if (!count)
			#printf("\tdc.l $%08x", value);
		#else
			#printf(",$%08x", value);

		#if (count++ == 4) {
			#count = 0;
			#printf("\n");
		#}

		#i += 1.0;
	#}
#}