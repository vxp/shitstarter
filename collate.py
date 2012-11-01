#!/usr/bin/python

import os

# we're gonna make a list of paths to project data files made by the scrapers
projects = [ ]
for directory, subdirs, filenames in os.walk("projects/"):
	if subdirs != []:
		# there are subdirectories, this isn't a project directory
		continue
	for filename in filenames:
		projects += [os.path.join(directory, filename)]

# now open each individual file and add it to a master data file R can read

output = open("infos.txt", "wb")
output.write("id\ttimestamp\tt\tchumps\tgoal\tfunds\tf\n") # want to be able to name columns with better names than R's default "V2" shit

for i in xrange(len(projects)):
	project = projects[i]
	everything = open(project).readlines()
	summary = everything[0].split("\t")
	data = everything[1:]
	goal = float(summary[5])
	#print i, project, summary, goal
	for point in data:
		timestamp, normedtime, chumps, funds = point.strip().split("\t")
		funds = float(funds)
		output.write("%i\t%s\t%.6f\t%s\t%i\t%i\t%.6f\n" % (i+1, timestamp, float(normedtime), chumps, goal, funds, funds / goal))

output.close()
