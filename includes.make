# The default rule is build for development.

all : build

# --------------------------------------------------------------

# Set up some default directory names.

bindir = bin
sourcedir = src
docsdir = docs/api

# Lists of source files.

# Use find to pull out all the java files
sources = $(shell find $(sourcedir) -name "*.java")

# Same again for all the html files for the docs
extradocs = $(shell find $(sourcedir) -name "package.html") $(sourcedir)/overview.html

# Pattern substring to convert java filenames to class names
classes = $(patsubst $(sourcedir)/%.java,$(bindir)/%.class,$(sources))

# Convoluted find on the package.html files, combined with a short perl
# script to convert directory names to package names
packages = $(shell cd $(sourcedir); find $(shell ls $(sourcedir)) -name package.html -printf "%h " | perl -e "print join(\".\",split(/\\//,<STDIN>));")

# Any extra flags to pass to the runtime environment
javaflags = -Xmx8m
subjavaflags = $(foreach flag,$(javaflags),-J$(flag))

# --------------------------------------------------------------

# How to build any class file under the output directory.

$(bindir)/%.class : $(sourcedir)/%.java
	@echo Compiling $(patsubst $(bindir)/%,%,$@)...
	@javac $(subjavaflags) -source 1.4 -sourcepath $(sourcedir) -d $(bindir) $<

# --------------------------------------------------------------

# Build is really just creating a new build.properties file.

build : $(bindir)/build.properties

# --------------------------------------------------------------

# Package is just making the Jar file.

package : $(projectname).jar

# --------------------------------------------------------------

# The index.html file gets updated with every doc build, so
# lets use that as the dependency.

docs : $(docsdir)/index.html

# --------------------------------------------------------------

# Cleans out the output directory and documentation directory.

clean :
	@echo Cleaning project tree...
	@rm -rf ${bindir}
	@rm -rf ${docsdir}
	@rm -f $(projectname).jar

# --------------------------------------------------------------

# A simple way of testing the project.

test : package
	@echo Starting Java VM
	@java $(javaflags) -jar $(projectname).jar

# --------------------------------------------------------------

# The build.properties get updated whenever a class is updated.

$(bindir)/build.properties : $(bindir) $(classes)
	@echo Writing build information...
	@echo -n "build.date=" >$(bindir)/build.properties
	@date +%Y%m%d >>$(bindir)/build.properties
	@echo -n "build.time=" >>$(bindir)/build.properties
	@date +%H%M >>$(bindir)/build.properties

# --------------------------------------------------------------

# Build the package from the output directory.
#
# If the build.properties or manifest file has updated then the package
# needs to be updated. (The build.properties file will get updated if
# any of the classes are updated).

$(projectname).jar : $(bindir)/build.properties $(sourcedir)/manifest
	@echo Building $(projectname).jar package...
	@jar cmf $(sourcedir)/manifest $(projectname).jar -C $(bindir) $(subjavaflags) .

# --------------------------------------------------------------

# Rebuild the documention if any of the sources have been updated.

$(docsdir)/index.html : $(docsdir) $(sources) $(extradocs)
	@echo Creating documentation...
	@javadoc $(subjavaflags) -d $(docsdir) -windowtitle $(projectname) -breakiterator -overview $(sourcedir)/overview.html -source 1.4 -private -sourcepath $(sourcedir) $(packages)

# --------------------------------------------------------------

# Creates the output directory if it doesnt exist.

$(bindir) :
	@echo Creating output directory...
	@mkdir -p $(bindir)

# --------------------------------------------------------------

# Creates the documentation directory if it doesnt exist.

$(docsdir) :
	@echo Creating documentation directory...
	@mkdir -p $(docsdir)
