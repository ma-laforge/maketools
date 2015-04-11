
ifdef SCRATCH_ROOT
   PATH_BUILD := $(addprefix $(SCRATCH_ROOT)/,cppbuild/maketools)
   PATH_BIN := $(addprefix $(SCRATCH_ROOT)/,cppbuild/maketools/bin)
endif

#-------------------------------------------------------------------------------
LTARGET := pgm_testpgm
#-------------------------------------------------------------------------------
.PHONY: default all
default: msg_targets
all: $(LTARGET)

.PHONY: msg_targets
msg_targets:
	@printf "Makefile targets:\n"
	@printf "   -clean: Clean-up build directories.\n"
	@printf "   -pgm_testpgm: Test program.\n"
	@printf "   -all: Build all.\n"

include ../../lib/MakeCppTools.mk

#Libraries
#-------------------------------------------------------------------------------
LIBREF_BaseTools := $(call CreateLibRef,basetools,./src/lib)
LIBREF_BaseWrappers := $(call CreateLibRef,basewrappers,./src/lib)

#Add libraries:
$(call AddCppLibraryList,LIBREF_BaseTools LIBREF_BaseWrappers)

#Programs
#-------------------------------------------------------------------------------

#-----Test program-----
progDep := $(call AppendPath,./src/testpgm,\
   testpgm_main.cpp)
progDep += $(call GetLibTargetList,LIBREF_BaseWrappers LIBREF_BaseTools)
$(call AddCppProgram,testpgm,$(progDep))

#-----Program 2-----
#progDep := ...

#Convenient target aliases
#-------------------------------------------------------------------------------
$(call AddLibAlias,libbasetools,$(LIBREF_BaseTools))
$(call AddLibAlias,libbasewrappers,$(LIBREF_BaseWrappers))
$(call AddProgAlias,pgm_testpgm,testpgm)

#Include dependencies of registered files
#-------------------------------------------------------------------------------
$(call IncludeDependencies)

