#!/usr/bin/python
# cat output.graph | dot -Tsvg -o ./output.svg

import sys
import os

def GetFilesRecursively(execution_directory, relative_path=""):
	print "execution_directory " + execution_directory
	print "relative_path " + relative_path
	files = list()
	currenty_directory_full_path = os.path.join(execution_directory, relative_path)
	for entry in os.listdir(currenty_directory_full_path):
		entry_full_path = os.path.join(currenty_directory_full_path, entry)
		entry_relative_path = os.path.join(relative_path, entry)
		print "  entry " + entry
		print "  entry_full_path " + entry_full_path
		print "  entry_relative_path " + entry_relative_path
		if os.path.isdir(entry_full_path):
			print "    folder"
			files += GetFilesRecursively(execution_directory, entry_relative_path)
		else:
			print "    file"
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


def ParseFileAndExtractDependencies(execution_directory, filename):
	dependencies = []
	with open(os.path.join(execution_directory, filename)) as file_handler:
		for line in file_handler:
			line = line.rstrip()
			if not line.startswith('#include'):
				continue

			line = line [8:]
			line = line.translate(None, ' <>"')
			print line
			dependencies.append(line)

	return dependencies



def BuildGraph(execution_directory, all_files):
	dependency_graph = dict()
	for file in all_files:
		dependencies = ParseFileAndExtractDependencies(execution_directory, file)
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
			f.write("  \"")
			f.write(x)
			f.write("\" -> \"")
			f.write(y)
			f.write("\"\n")


def AddNodesToFile(dependency_graph, f):
	pass
	# for x in dependency_graph:
		# f.write();


def CreateDotGraphFile(dependency_graph):
	with open("./output.graph", "w") as f:
		f.write("digraph mygraph {\n")
		AddEdgesToFile(dependency_graph, f)
		AddNodesToFile(dependency_graph, f)
		f.write("}\n")


def main(argv):
	execution_directory = argv[0]
	all_files = GetFilesRecursively(execution_directory)
	print "all files:"
	print all_files
	all_files = FilterFileExtensions(all_files, {'cc', 'h'})
	print "filtered files:"
	print all_files

	dependency_graph = BuildGraph(execution_directory, all_files)
	print dependency_graph
	CreateDotGraphFile(dependency_graph)


if __name__ == "__main__":
	main(sys.argv[1:])