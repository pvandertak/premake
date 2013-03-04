--
-- tests/actions/vstudio/vc2010/test_assembly_refs.lua
-- Validate managed assembly references in Visual Studio 2010 C/C++ projects.
-- Copyright (c) 2013 Jason Perkins and the Premake project
--

	local suite = test.declare("vs2010_assembly_refs")
	local vc2010 = premake.vstudio.vc2010


--
-- Setup
--

	local sln, prj

	function suite.setup()
		sln = test.createsolution()
		flags { "Managed" }
	end

	local function prepare(platform)
		prj = premake.solution.getproject_ng(sln, 1)
		vc2010.assemblyReferences(prj)
	end


--
-- If there are no managed assemblies listed in links, output nothing.
--

	function suite.noOutput_onNoAssemblies()
		prepare()
		test.isemptycapture()
	end


--
-- To distinguish between managed and unmanaged libraries, the ".dll"
-- extension must be explicitly supplied.
--

	function suite.listsAssemblies()
		links { "System.dll", "System.Data.dll" }
		prepare()
		test.capture [[
	<ItemGroup>
		<Reference Include="System" />
		<Reference Include="System.Data" />
	</ItemGroup>
		]]
	end


--
-- Any unmanaged libraries included in the list should be ignored.
--

	function suite.ignoresUnmanagedLibraries()
		links { "m", "System.dll" }
		prepare()
		test.capture [[
	<ItemGroup>
		<Reference Include="System" />
	</ItemGroup>
		]]
	end
