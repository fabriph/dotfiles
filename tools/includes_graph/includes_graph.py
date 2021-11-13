#!/usr/bin/python3

"""
************************************************************************************************
Usage
python includes_graph.py path/you/want/to/investigate
cat output.graph | dot -Tsvg -o ./output.svg

Always execute from the root directory of your project (at least for now, until I have time to improve this).

************************************************************************************************
Whiteboard space I've been using for ideas:

If we find a file that has both the .h and .cc, it is easy to figure what is the actual root path of a project.

FILE: x/y/z/foo.h
CONTENT: --doesnt matter--

FILE: x/y/z/foo.cc
CONTENT: #include "z/foo.h"

[...] omiting detailed explanation.



However, if there is no such .h and .cc files that fulfill that relationship, then figuring out the root directory of a project is more complicated (or maybe theorically impossible??)


********Execute script from root of project

# PWD prints /hd1/home/dev/
$ python includes_graph.py aaa/bbb/ccc/ddd

FILE: /hd1/home/dev/aaa/bbb/ccc/ddd/person/tennis-player.cc
CONTENT:
items/sports/tennis-racquet.h

		the missing part is the path itself


********Execute script from a folder inside the project
# PWD prints /hd1/home/dev/aaa/bbb/

$ python includes_graph.py ccc/ddd

FILE: /hd1/home/dev/aaa/bbb/ccc/ddd/person/tennis-player.cc
CONTENT:
items/sports/tennis-racquet.h

Grab the directory to inspect (ccc/ddd), search it in any .h/.cc file you find (/hd1/home/dev/aaa/bbb/ccc/ddd/person/tennis-player.cc) and keep the left part (/hd1/home/dev/aaa/bbb).
??


********Execute script from a folder outside the project
# PWD prints /hd1

$ python includes_graph.py home/dev/aaa/bbb/ccc/ddd

FILE: /hd1/home/dev/aaa/bbb/ccc/ddd/person/tennis-player.cc
CONTENT:
items/sports/tennis-racquet.h


********Execute script from a folder outside but inside other sub directory
# PWD prints /hd1/home/somemagicdirectory/more

$ python includes_graph.py ../../dev/aaa/bbb/ccc/ddd

FILE: /hd1/home/dev/aaa/bbb/ccc/ddd/person/tennis-player.cc
CONTENT:
items/sports/tennis-racquet.h

??


"""

import sys
import os

INCLUDE_TAG = '#include'
FLAG_MERGE_CC_H_FILES = True
CHARACTERS_TO_IGNORE = ' <>"'

# don't do this at home (global variables):
global_found_first_current_directory_include = False
global_unknown_path_part = ""

def GetFilesRecursively(directory_to_inspect, relative_path=""):
	# print "GetFilesRecursively():"
	# print "directory_to_inspect " + directory_to_inspect
	# print "relative_path " + relative_path
	files = list()
	currenty_directory_full_path = os.path.join(directory_to_inspect, relative_path)
	for entry in os.listdir(currenty_directory_full_path):
		entry_full_path = os.path.join(currenty_directory_full_path, entry)
		entry_relative_path = os.path.join(relative_path, entry)
		# print "  entry " + entry
		# print "  entry_full_path " + entry_full_path
		# print "  entry_relative_path " + entry_relative_path
		if os.path.isdir(entry_full_path):
			# print "    folder"
			files += GetFilesRecursively(directory_to_inspect, entry_relative_path)
		else:
			# print "    file"
			files.append(entry_relative_path)
				
	return files


def FilterFileExtensions(all_files, set_of_allowed_extensions):
	accepted_files = []
	for file in all_files:
		extension = file.split('.')[-1]
		# print extension
		if extension in set_of_allowed_extensions:
			accepted_files.append(file)
			# print file + ' ok'
		# else:
		# 	print file + ' SKIPPED'
	return accepted_files


def PopulateUnkownPathPart(directory_to_inspect, line):
	line = line.translate({ord(c): None for c in CHARACTERS_TO_IGNORE})


def ParseFileAndExtractDependencies(directory_to_inspect, filename):
	# print "ParseFileAndExtractDependencies():"
	# print "  directory_to_inspect " + directory_to_inspect
	# print "  filename " + filename
	dependencies = set()
	with open(os.path.join(directory_to_inspect, filename)) as file_handler:
		for line in file_handler:
			line = line.rstrip()
			if not line.startswith(INCLUDE_TAG):
				continue

			line = line [len(INCLUDE_TAG):]
			# if (not global_found_first_current_directory_include and line.find("\"")):
			# 	global_found_first_current_directory_include = True
			# 	PopulateUnkownPathPart(directory_to_inspect, line)

			line = line.translate({ord(c): None for c in CHARACTERS_TO_IGNORE})
			# print line

			if FLAG_MERGE_CC_H_FILES:
				line = DropExtension(line)
			dependencies.add(line)

	return dependencies



def BuildGraph(directory_to_inspect, all_files):
	# print "BuildGraph()"
	dependency_graph = dict()
	for file in all_files:
		dependencies = ParseFileAndExtractDependencies(directory_to_inspect, file)

		if FLAG_MERGE_CC_H_FILES:
			file = DropExtension(file)

		if directory_to_inspect != ".":
			file = directory_to_inspect + file

		# Needed if file extensions are dropped.
		if file in dependency_graph:
			dependency_graph[file].union(dependencies)
		else:
			dependency_graph[file] = dependencies
	return dependency_graph


def DropExtension(filename):
	return filename.split('.')[0]


def AddEdgesToFile(dependency_graph, f):
	write_sep = False
	for x in dependency_graph:
		if write_sep:
			f.write("\n")
		write_sep = True
		for y in dependency_graph[x]:
			if x == y:
				continue

			f.write("  \"")
			f.write(x)
			f.write("\" -> \"")
			f.write(y)
			f.write("\"\n")


def AddNodesToFile(dependency_graph, f):
	pass
	# for x in dependency_graph:
		# f.write();

def AddClustersToFile(dependency_graph, f):
	pass


def CreateDotGraphFile(dependency_graph):
	with open("./output.graph", "w") as f:
		f.write("digraph mygraph {\n")
		AddEdgesToFile(dependency_graph, f)
		AddNodesToFile(dependency_graph, f)
		f.write("}\n")


def main(argv):
	directory_to_inspect = argv[0]
	all_files = GetFilesRecursively(directory_to_inspect)
	# print "all files:"
	# print all_files
	all_files = FilterFileExtensions(all_files, {'cc', 'h'})
	# print "filtered files:"
	# print all_files

	dependency_graph = BuildGraph(directory_to_inspect, all_files)
	# print dependency_graph
	CreateDotGraphFile(dependency_graph)


if __name__ == "__main__":
	main(sys.argv[1:])