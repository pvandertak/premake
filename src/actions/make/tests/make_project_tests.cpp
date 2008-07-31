/**
 * \file   make_project_tests.cpp
 * \brief  Automated tests for GNU makefile project processing.
 * \author Copyright (c) 2008 Jason Perkins and the Premake project
 */

#include "premake.h"
#include "actions/tests/action_tests.h"
extern "C" {
#include "actions/make/make_project.h"
#include "platform/platform.h"
}

SUITE(action)
{
	/**********************************************************************
	 * Signature tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_SignatureIsCorrect_OnGmake)
	{
		session_set_action(sess, "gmake");
		make_project_signature(sess, prj, strm);
		CHECK_EQUAL(
			"# GNU Makefile autogenerated by Premake\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Config block conditional tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_Config_Conditional)
	{
		make_project_config_conditional(sess, prj, strm);
		CHECK_EQUAL(
			"ifeq ($(CONFIG),Debug DLL)\n",
			buffer);
	}

	TEST_FIXTURE(FxAction, MakeProject_Config_End)
	{
		make_project_config_end(sess, prj, strm);
		CHECK_EQUAL(
			"endif\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Object file list tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_Objects_ConvertsFileExtension)
	{
		char* files[] = { "Hello.cpp", "Good Bye.cpp", NULL };
		SetField(prj, ProjectFiles, files);
		make_project_objects(sess, prj, strm);
		CHECK_EQUAL(
			"OBJECTS := \\\n"
			"\t$(OBJDIR)/Hello.o \\\n"
			"\t$(OBJDIR)/Good\\ Bye.o \\\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Resource file list tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_Resources)
	{
		make_project_resources(sess, prj, strm);
		CHECK_EQUAL(
			"RESOURCES := \\\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * .PHONY rule tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_PhonyRule)
	{
		make_project_phony_rule(sess, prj, strm);
		CHECK_EQUAL(
			".PHONY: clean\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Output target tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_OutputTarget)
	{
		make_project_target(sess, prj, strm);
		CHECK_EQUAL(
			"$(OUTFILE): $(OUTDIR) $(OBJDIR) $(OBJECTS) $(LDDEPS) $(RESOURCES)\n"
			"\t@echo Linking My Project\n"
			"\t@$(CXX) -o $@ $(LDFLAGS) $(ARCHFLAGS) $(OBJECTS) $(RESOURCES)\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Directory creation rules
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_MkdirRules)
	{
		make_project_mkdir_rules(sess, prj, strm);
		CHECK_EQUAL(
			"$(OUTDIR):\n"
			"\t@echo Creating $(OUTDIR)\n"
			"\t@$(MKDIR) $(SYS_OUTDIR)\n"
			"\n"
			"$(OBJDIR):\n"
			"\t@echo Creating $(OBJDIR)\n"
			"\t@$(MKDIR) $(SYS_OBJDIR)\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Clean rules
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_CleanRules)
	{
		make_project_clean_rules(sess, prj, strm);
		CHECK_EQUAL(
			"clean:\n"
			"\t@echo Cleaning My Project\n"
			"ifeq (posix, $(SHELLTYPE))\n"
			"\t@rm -f  $(SYS_OUTFILE)\n"
			"\t@rm -rf $(SYS_OBJDIR)\n"
			"else\n"
			"\t@if exist $(SYS_OUTFILE) del $(SYS_OUTFILE)\n"
			"\t@if exist $(SYS_OBJDIR) rmdir /s /q $(SYS_OBJDIR)\n"
			"endif\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Source rule tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_SourceRules)
	{
		char* files[] = { "Good Bye.cpp", NULL };
		SetField(prj, ProjectFiles, files);
		make_project_source_rules(sess, prj, strm);
		CHECK_EQUAL(
			"$(OBJDIR)/Good\\ Bye.o: Good\\ Bye.cpp\n"
			"\t@echo $(notdir $<)\n"
			"\t@$(CXX) $(CXXFLAGS) -o $@ -c $<\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * File dependency generation tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeProject_IncludeDependencies)
	{
		make_project_include_dependencies(sess, prj, strm);
		CHECK_EQUAL(
			"-include $(OBJECTS:%.o=%.d)\n",
			buffer);
	}
}
