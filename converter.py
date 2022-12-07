#!/usr/bin/env python

import sys, getopt
from PIL import Image

palette = {(13, 13, 13): 1,
           (40, 43, 36): 0}

def main(argv):
   inputfile = ''
   outputfile = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
   except getopt.GetoptError:
      print('USAGE:\n\tconverter.py -i <inputfile> -o <outputfile>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print('converter.py -i <inputfile> -o <outputfile>')
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg

   img_png = Image.open(inputfile) 
   pixels = img_png.load()
   width, height = img_png.size
   with open(outputfile, 'wb') as output:
        for h in range(height):
            for w in range(width):
                r, g, b = map(lambda n : n >> 2, pixels[w, h])
                byte = (palette[(r, g, b)]).to_bytes(1, 'big')
                output.write(byte)

if __name__ == "__main__":
   main(sys.argv[1:])
