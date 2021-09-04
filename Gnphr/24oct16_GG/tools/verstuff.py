vertical = 0
wordtical = 0
times = 10000

print "TEST1"

while times:
  vertical += 0x10
  if vertical >= 0xE0:
    vertical = 0
    print " "
    print "RESET:"
    print " "
  wordtical += 0x0010 & 0xFFFF

  print hex((vertical+0x38)&0xFF),"|",hex(wordtical)
  #print hex((vertical)&0xFF),"|",hex(wordtical)
  times -= 1
  
print "TEST2"
val = 0
times = 400
while times:
  val += 0x10
  
  print hex(val & 0x37F)
  times -= 1
  
  