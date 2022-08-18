import argparse
import subprocess
import os

from os.path import abspath

# parse arguments
parser = argparse.ArgumentParser(description='Make a PDF map of a survey.')

parser.add_argument(
	"survey_file",
	help= 'The survey file to work from, e.g.: dat/F1.th')
parser.add_argument(
	"--cadastral_number", type = str, metavar ='YYY',nargs =1,
	help = 'Cadastral number, e.g.: 11')

args = parser.parse_args()

SURVEY_FILE = args.survey_file
CAD_NUM = args.cadastral_number[0]

# read the gamswandkar file to find the coordinates of the cave of interest.
with open("data/gamswandkar.th", "r") as f:
    DATA = f.readlines()

f.close()

# find the fixes line:
for dataline in DATA:
	if ("fix" in dataline) and (SURVEY_FILE in dataline):
		FIX = dataline.split(" ")
		print(FIX[2:5])
#for dataline in DATA:
#    if ("fix" in dataline) and (SURVEY_FILE in dataline):
#		FIX = dataline.split(" ")
#		  print(FIX)
#	else:
#		print()

Y,X,Z =FIX[2:5]
# read and format the template config file
with open("config_template.txt", "r") as f:
    TEMPLATE = f.read()

f.close()

# write a new formatted config file
with open("temp.thconfig", 'w+') as f:
	f.write(TEMPLATE.format(basefile=SURVEY_FILE,
                            cadastral_number = CAD_NUM,
                            x = X,
                            y = Y,
                            z = "{:.0f}".format(float(Z))))
f.close()
# compile with therion
subprocess.check_output('''therion "temp.thconfig"''', shell = True)
subprocess.check_output('''rm temp.thconfig''', shell = True)
subprocess.check_output('''rm  therion.log''', shell = True)
