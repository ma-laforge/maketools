#Simple C++ make system

#Validate environment
#-------------------------------------------------------------------------------
#PATH_BUILD: Path to root folder where object files are to be generated.
ifndef PATH_BUILD
#   tmpeval := $(error Missing PATH_BUILD: Problem with build system)
   PATH_BUILD = ./obj
endif

#PATH_BIN: Path to root folder where binaries are to be generated.
ifndef PATH_BIN
   PATH_BIN = ./bin
endif

#Useful flags:
#   -g: include debug
#   -Wall: Turn on all warnings
CPPFLAGS = $(addprefix -I ,$(LPATH_INCLUDE))

#Initialize variables
#-------------------------------------------------------------------------------
LPATH_INCLUDE := #List of include paths
LREL_CLEANUP := #List of files to clean up; relative to PATH_BUILD
LABS_CLEANUP := #List of files to clean up; absolute path
dependencies := #List of dependency files

#Tool aliases
#-------------------------------------------------------------------------------
MKDIR := mkdir -p
MV := mv -f
RM := rm -f
SED := sed
TEST := test

#Base macros
#-------------------------------------------------------------------------------
CreateFolder = $(shell $(TEST) -d $1 || $(MKDIR) $1)

StripIgnore = $(filter-out TGTIGNORE%,$1)

#Substitues the root folder with another for a list of files
#   -$1-cur-root: Root folder
#   -$2-new-root: New root
#   -$3-file-list: List of files
SubstRoot = $(patsubst $1/%,$2/%,$3)

#Adds a common path to a list of files (slightly more readable)
#   -$1-root-path: Path to append
#   -$2-file-list: List of files
AppendPath = $(addprefix $1/,$2) 

#Returns the path to the build sub folder
#   -$1-subfolder: Path to append to build path
GetBuildSubFolder = $(strip $(call AppendPath,$(PATH_BUILD),$1))

#Returns the path to an output program file
#   -$1-prog-name: Name of the output program file
GetProgPath = $(call AppendPath,$(PATH_BIN),$1)

#Returns list with >>extensions<< converted from source to object
#   -$1-src-list: List of source files
SrcToObjectExt = $(patsubst %.cpp,%.o,$(filter %.cpp,$1))

#Returns list of object files of given list of source files
#   -$1-subfolder: Build subfolder
#   -$2-src-list: List of source files
SrcToObject = $(call AppendPath,$(call GetBuildSubFolder,$1),$(call SrcToObjectExt,$(notdir $2)))

#Converts a list of dependencies to a list of targets.
#Similar to SrcToObject, but keeps non-object files (not recognized as soure) as-is
#   -$1-prog-name: Name of program to build
#   -$2-dep-list: List of dependencies (incl. .a & .cpp files)
define DepToTarget
   $(foreach curFile,$2,\
      $(if $(filter %.cpp,$(curFile)),$(call SrcToObject,$1,$(curFile)),$(curFile))\
   )
endef


#Object-file building macros
#-------------------------------------------------------------------------------
define MakeDepend
	@printf "Creating dep $3... "
	@$$(CC) $$(CFLAGS) $$(CPPFLAGS) $$(TARGET_ARCH) -M $1 | \
	$$(SED) 's,\($$(notdir $2)\) *:,$2: ,' > $3.tmp
	@$$(SED) -e 's/#.*//' \
	       -e 's/^[^:]*: *//' \
	       -e 's/ *\\$$$$//' \
	       -e '/^$$$$/ d' \
	       -e 's/$$$$/ :/' $3.tmp >> $3.tmp
	@$$(MV) $3.tmp $3
	@echo Done.
endef

#Adds object target from a C++ source
#   -$1-target-o: Target path (.o file)
#   -$2-src-cpp: Source path (.cpp file)
define AddObj_Cpp
   $1: $2
	   $(call MakeDepend,$$<,$$@,$(patsubst %.o,%.d,$1))
	   $$(COMPILE.cpp) $$(OUTPUT_OPTION) $$<
endef

#Adds object targets from list of C++ sources
#   -$1-subfolder: Build subfolder
#   -$2-src-list: List of source files
define AddObj_CppList
   $(foreach srcFile,$2,\
      $(eval $(call AddObj_Cpp,$(call SrcToObject,$1,$(srcFile)),$(srcFile)))\
   )
endef

#Library-related macros
#-------------------------------------------------------------------------------
#Creates reference to given software library
#   -$1-lib-name: path relative to lib-root
#   -$2-lib-root: relative/absolute
CreateLibRef = $1 $2

#Returns the library name from a given LibRef
#   -$1-lib-ref: Reference to a software library
GetLibName = $(word 1, $1)

#Returns the library root path from a given LibRef
#   -$1-lib-ref: Reference to a software library
GetLibRoot = $(word 2, $1)

#Returns target name of given library
#   -$1-lib-ref: Reference to a software library
GetLibTarget = $(addprefix $(PATH_BUILD)/,lib$(word 1, $1).a) 

#Returns a list of library target names
#   -$1-lib-ref: List of references to software libraries
GetLibTargetList = $(foreach libref,$1,$(call GetLibTarget,$($(libref))))

#Returns the path to the library source files
#   -$1-lib-ref: Reference to a software library
GetLibSrcPath = $(addprefix $(word 2, $1)/,$(word 1, $1))

#Returns a list of source files found in the library directory
#   -$1-lib-ref: Reference to a software library
GenList_LibSrc = $(wildcard $(addprefix $(call GetLibSrcPath,$1)/,*.cpp))

#Adds a library to the project
#   -$1-lib-ref: Reference to a software library
define _AddCppLibrary
   $(eval tmplibname := $(call GetLibName,$1))
   $(eval tmplibroot := $(call GetLibRoot,$1))
   $(eval tmpsource := $(call GenList_LibSrc,$1))
   $(eval tmplibtgt := $(call GetLibTarget,$1))
   $(eval tmpobjfiles := $(call SrcToObject,$(tmplibname),$(tmpsource)))
   $(call AddObj_CppList,$(tmplibname),$(tmpsource))
   tmpeval := $(call CreateFolder,$(call GetBuildSubFolder,$(tmplibname)))

   dependencies += $(patsubst %.o,%.d,$(tmpobjfiles))

   LPATH_INCLUDE += $(call GetLibSrcPath,$1)
   LREL_CLEANUP += $(call AppendPath,$(tmplibname),*.o *.d)
   LABS_CLEANUP += $(tmplibtgt)

   $(tmplibtgt): $(tmpobjfiles)
	   @echo "\nBuilding library archive $(tmplibname)..."
	   @echo "-------------------------------------------------------------------------------"
	   $(AR) $(ARFLAGS) $$@ $$?
	   @echo 
endef
AddCppLibrary = $(eval $(call _AddCppLibrary,$1))

#Adds libraries to the project using a list of references
#   -$1-lib-ref-list: List of references to a software libraries
define _AddCppLibraryList
$(foreach curLib,$1,\
   $(call AddCppLibrary,$($(curLib)))\
)
endef
AddCppLibraryList = $(eval $(call _AddCppLibraryList,$1))

#Adds an alias (phony target) to a library
#   -$1-alias-name: Name of alias
#   -$2-lib-ref: Reference to a software library
define _AddLibAlias
   .PHONY: $1
   $1: $$(call GetLibTarget,$2)
	   @echo "make $$@: Done."
	   @echo
endef
AddLibAlias = $(eval $(call _AddLibAlias,$1,$2))

#Program-related macros
#-------------------------------------------------------------------------------
#Adds a program to the project
#   -$1-prog-name: Name of program to build
#   -$2-dep-list: List of dependencies (incl. .a & .cpp files)
define _AddCppProgram
   $(eval tmpsource := $(filter %.cpp,$2))
   $(eval tmpobjfiles := $(call SrcToObject,$1,$(tmpsource)))
   $(eval tmppgmtgt := $(call GetProgPath,$1))
   $(call AddObj_CppList,$1,$(tmpsource))
   tmpeval := $(call CreateFolder,$(call GetBuildSubFolder,$1))
   $(eval tmpdeplist := $(call DepToTarget,$1,$2))

   dependencies += $(patsubst %.o,%.d,$(tmpobjfiles))

   LREL_CLEANUP += $(call AppendPath,$1,*.o *.d)
   LABS_CLEANUP += $(tmppgmtgt)

   $(tmppgmtgt): $(tmpdeplist)
	   @echo "\nLinking program $1..."
	   @echo "-------------------------------------------------------------------------------"
	   $(LINK.cpp) $$^ $(LOADLIBES) $(LDLIBS) -o $$@
	   @echo
endef
AddCppProgram = $(eval $(call _AddCppProgram,$1,$2))
#   $(tmppgmtgt): $(filter %.a,$(tmpdeplist))

#Adds an alias (phony target) to a program
#   -$1-alias-name: Name of alias
#   -$2-lib-ref: Reference to a software library
define _AddProgAlias
   .PHONY: $1
   $1: $$(call GetProgPath,$2)
	   @echo "make $$@: Done."
	   @echo
endef
AddProgAlias = $(eval $(call _AddProgAlias,$1,$2))

#OTHER
#-------------------------------------------------------------------------------
#Includes dependencies
#Must be run after libraries & programs have been added
define _IncludeDependencies
 ifneq "$(MAKECMDGOALS)" "clean"
   #Include only existing dependencies:
   include $(wildcard $(dependencies))
 endif
endef
IncludeDependencies = $(eval $(call _IncludeDependencies))

#Housekeeping
#-------------------------------------------------------------------------------
#Ensure root build folder exists:
tmpeval := $(call CreateFolder,$(PATH_BUILD))
tmpeval := $(call CreateFolder,$(PATH_BIN))

#Default targets
#-------------------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "Cleaning build..."
	@echo "-------------------------------------------------------------------------------"
	$(RM) $(addprefix $(PATH_BUILD)/,$(LREL_CLEANUP)) $(LABS_CLEANUP)
	@echo "$@: Done."

#Last line
