--
-- vs2005_csproj.lua
-- Generate a Visual Studio 2005/2008 C# project.
-- Copyright (c) 2009-2012 Jason Perkins and the Premake project
--

	premake.vstudio.cs2005 = { }
	local vstudio = premake.vstudio
	local cs2005  = premake.vstudio.cs2005
	local project = premake5.project
	local config = premake5.config
	local dotnet = premake.dotnet


--
-- Generate a Visual Studio 200x C# project, with support for the new platforms API.
--

	function cs2005.generate_ng(prj)
		io.eol = "\r\n"
		io.indent = "  "
		
		cs2005.projectelement(prj)
		cs2005.projectsettings(prj)

		for cfg in project.eachconfig(prj) do
			cs2005.propertygroup(cfg)
			cs2005.debugProps(cfg)
			cs2005.outputProps(cfg)
			cs2005.compilerProps(cfg)		
			_p(1,'</PropertyGroup>')			
		end

		cs2005.projectReferences(prj)

		_p(1,'<ItemGroup>')
		cs2005.files(prj)
		_p(1,'</ItemGroup>')

		_p('  <Import Project="$(MSBuildBinPath)\\Microsoft.CSharp.targets" />')
		_p('  <!-- To modify your build process, add your task inside one of the targets below and uncomment it.')
		_p('       Other similar extension points exist, see Microsoft.Common.targets.')
		_p('  <Target Name="BeforeBuild">')
		_p('  </Target>')
		_p('  <Target Name="AfterBuild">')
		_p('  </Target>')
		_p('  -->')

		_p('</Project>')
	end


--
-- Write the opening <Project> element.
--

	function cs2005.projectelement(prj)
		local toolversion = {
			vs2005 = '',
			vs2008 = ' ToolsVersion="3.5"',
			vs2010 = ' ToolsVersion="4.0"',
			vs2012 = ' ToolsVersion="4.0"',
		}

		if _ACTION > "vs2008" then
			_p('<?xml version="1.0" encoding="utf-8"?>')
		end
		_p('<Project%s DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">', toolversion[_ACTION])
	end


--
-- Write the opening PropertyGroup, which contains the project-level settings.
--

	function cs2005.projectsettings(prj)
		local version = {
			vs2005 = '8.0.50727',
			vs2008 = '9.0.21022',
			vs2010 = '8.0.30703',
			vs2012 = '8.0.30703',
		}
		
		local frameworks = {
			vs2010 = "4.0",
			vs2012 = "4.5",
		}

		_p(1,'<PropertyGroup>')
		
		-- find the first configuration in the project, use as the default
		local cfg = project.getfirstconfig(prj)
		
		_p(2,'<Configuration Condition=" \'$(Configuration)\' == \'\' ">%s</Configuration>', premake.esc(cfg.buildcfg))
		_p(2,'<Platform Condition=" \'$(Platform)\' == \'\' ">%s</Platform>', cs2005.arch(prj))
		
		_p(2,'<ProductVersion>%s</ProductVersion>', version[_ACTION])
		_p(2,'<SchemaVersion>2.0</SchemaVersion>')
		_p(2,'<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
		
		_p(2,'<OutputType>%s</OutputType>', dotnet.getkind(cfg))
		_p(2,'<AppDesignerFolder>Properties</AppDesignerFolder>')

		local target = cfg.buildtarget
		_p(2,'<RootNamespace>%s</RootNamespace>', target.basename)
		_p(2,'<AssemblyName>%s</AssemblyName>', target.basename)

		local framework = prj.framework or frameworks[_ACTION]
		if framework then
			_p(2,'<TargetFrameworkVersion>v%s</TargetFrameworkVersion>', framework)
		end

		if _ACTION >= "vs2010" then
			_p(2,'<TargetFrameworkProfile></TargetFrameworkProfile>')
			_p(2,'<FileAlignment>512</FileAlignment>')
		end
		
		_p(1,'</PropertyGroup>')
	end


--
-- Write out the source files item group.
--

	function cs2005.files(prj)
		local tr = project.getsourcetree(prj)
		premake.tree.traverse(tr, {
			onleaf = function(node, depth)

				local action = premake.dotnet.getbuildaction(node)
				local fname = path.translate(node.relpath)
				local elements, dependency = cs2005.getrelated(prj, node.abspath, action)
				
				if elements == "None" then
					_p(2,'<%s Include="%s" />', action, fname)
				else
					_p(2,'<%s Include="%s">', action, fname)
					if elements == "AutoGen" then
						_p(3,'<AutoGen>True</AutoGen>')
					elseif elements == "AutoGenerated" then
						_p(3,'<SubType>Designer</SubType>')
						_p(3,'<Generator>ResXFileCodeGenerator</Generator>')
						_x(3,'<LastGenOutput>%s.Designer.cs</LastGenOutput>', path.getbasename(node.name))
					elseif elements == "SubTypeDesigner" then
						_p(3,'<SubType>Designer</SubType>')
					elseif elements == "SubTypeForm" then
						_p(3,'<SubType>Form</SubType>')
					elseif elements == "PreserveNewest" then
						_p(3,'<CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>')
					end
					if dependency then
						dependency = project.getrelative(prj, dependency)
						_x(3,'<DependentUpon>%s</DependentUpon>', path.translate(dependency))
					end
					_p(2,'</%s>', action)
				end

			end
		}, false)
	end


--
-- Write the compiler flags for a particular configuration.
--

	function cs2005.compilerProps(cfg)
		_x(2,'<DefineConstants>%s</DefineConstants>', table.concat(cfg.defines, ";"))

		_p(2,'<ErrorReport>prompt</ErrorReport>')
		_p(2,'<WarningLevel>4</WarningLevel>')

		if cfg.flags.Unsafe then
			_p(2,'<AllowUnsafeBlocks>true</AllowUnsafeBlocks>')
		end
		
		if cfg.flags.FatalWarnings then
			_p(2,'<TreatWarningsAsErrors>true</TreatWarningsAsErrors>')
		end
	end


--
-- Write out the debugging and optimization flags for a configuration.
--

	function cs2005.debugProps(cfg)
		if cfg.flags.Symbols then
			_p(2,'<DebugSymbols>true</DebugSymbols>')
			_p(2,'<DebugType>full</DebugType>')
		else
			_p(2,'<DebugType>pdbonly</DebugType>')
		end
		_p(2,'<Optimize>%s</Optimize>', iif(premake.config.isoptimizedbuild(cfg), "true", "false"))
	end


--
-- Write out the target and intermediates settings for a configuration.
--

	function cs2005.outputProps(cfg)
		local outdir = project.getrelative(cfg.project, cfg.buildtarget.directory)
		_x(2,'<OutputPath>%s\\</OutputPath>', path.translate(outdir))
		
		-- Want to set BaseIntermediateOutputPath because otherwise VS will create obj/
		-- anyway. But VS2008 throws up ominous warning if present.
		local objdir = path.translate(project.getrelative(cfg.project, cfg.objdir))
		if _ACTION > "vs2008" then
			_x(2,'<BaseIntermediateOutputPath>%s\\</BaseIntermediateOutputPath>', objdir)
			_p(2,'<IntermediateOutputPath>$(BaseIntermediateOutputPath)</IntermediateOutputPath>')
		else
			_x(2,'<IntermediateOutputPath>%s\\</IntermediateOutputPath>', objdir)
		end
	end


--
-- Given a source file name, look for related elements and files. Pairs up
-- designer and resource files with their corresponding source files, and
-- vice versa.
--
-- @param prj
--    The current project, which contains the source file lists.
-- @param fname
--    The absolute path of the file under consideration.
-- @param action
--    The build action for the file under consideration.
--

	function cs2005.getrelated(prj, fname, action)
		if action == "Compile" and fname:endswith(".cs") then
			if fname:endswith(".Designer.cs") then
				local basename = fname:sub(1, -13)

				-- is there a matching *.cs file?
				local testname = basename .. ".cs"
				if project.hasfile(prj, testname) then
					return "Dependency", testname
				end
				
				-- is there a matching *.resx file
				testname = basename .. ".resx"
				if project.hasfile(prj, testname) then
					return "AutoGen", testname
				end
			else
				local basename = fname:sub(1, -4)
				
				-- is there a matching *.Designer.cs?
				testname = basename .. ".Designer.cs"
				if project.hasfile(prj, testname) then
					return "AutoGenerated"
				end
			end
		end
		
		if action == "EmbeddedResource" and fname:endswith(".resx") then
			local basename = fname:sub(1, -6)

			-- is there a matching *.cs file?
			local testname = basename .. ".cs"
			if project.hasfile(prj, testname) then
				if project.hasfile(prj, basename .. ".Designer.cs") then
					return "DesignerType", testname
				else
					return "Dependency", testname
				end
			else
				-- is there a matching *.Designer.cs?
				testname = basename .. ".Designer.cs"
				if project.hasfile(prj, testname) then
					return "AutoGenerated"
				end
			end
		end
				
		if action == "Content" then
			return "CopyNewest"
		end
		
		return "None"		
	end

	
--
-- Write the list of project dependencies.
--
	function cs2005.projectReferences(prj)
		_p(1,'<ItemGroup>')

		local deps = project.getdependencies(prj)
		if #deps > 0 then
			local prjpath = project.getlocation(prj)			
			for _, dep in ipairs(deps) do
				local relpath = path.getrelative(prjpath, vstudio.projectfile(dep))
				_x(2,'<ProjectReference Include="%s">', path.translate(relpath))
				_p(3,'<Project>{%s}</Project>', dep.uuid)
				_x(3,'<Name>%s</Name>', dep.name)
				_p(2,'</ProjectReference>')
			end
		end

		-- C# doesn't support per-configuration links (does it?) so just use
		-- the settings from the first available config instead
		local links = config.getlinks(project.getfirstconfig(prj), "system", "fullpath")
		for _, link in ipairs(links) do
			if link:find("/", nil, true) then
				_x(2,'<Reference Include="%s">', path.getbasename(link))
				_x(3,'<HintPath>%s</HintPath>', path.translate(link))
				_p(2,'</Reference>')
			else
				_x(2,'<Reference Include="%s" />', path.getbasename(link))
			end
		end
	
		_p(1,'</ItemGroup>')
	end


--
-- Return the Visual Studio architecture identification string. The logic
-- to select this is getting more complicated in VS2010, but I haven't 
-- tackled all the permutations yet.
--

	function cs2005.arch(prj)
		return "AnyCPU"
	end


--
-- Write the PropertyGroup element for a specific configuration block.
--

	function cs2005.propertygroup(cfg)
		_p(1,'<PropertyGroup Condition=" \'$(Configuration)|$(Platform)\' == \'%s|%s\' ">', premake.esc(cfg.buildcfg), cs2005.arch(cfg))
		if _ACTION > "vs2008" then
			_p(2,'<PlatformTarget>%s</PlatformTarget>', cs2005.arch(cfg))
		end
	end



-----------------------------------------------------------------------------
-- Everything below this point is a candidate for deprecation
-----------------------------------------------------------------------------

--
-- Figure out what elements a particular source code file need in its item
-- block, based on its build action and any related files in the project.
-- 
	
	local function getelements(prj, action, fname)
	
		if action == "Compile" and fname:endswith(".cs") then
			if fname:endswith(".Designer.cs") then
				-- is there a matching *.cs file?
				local basename = fname:sub(1, -13)
				local testname = basename .. ".cs"
				if premake.findfile(prj, testname) then
					return "Dependency", testname
				end
				-- is there a matching *.resx file?
				testname = basename .. ".resx"
				if premake.findfile(prj, testname) then
					return "AutoGen", testname
				end
			else
				-- is there a *.Designer.cs file?
				local basename = fname:sub(1, -4)
				local testname = basename .. ".Designer.cs"
				if premake.findfile(prj, testname) then
					return "SubTypeForm"
				end
			end
		end

		if action == "EmbeddedResource" and fname:endswith(".resx") then
			-- is there a matching *.cs file?
			local basename = fname:sub(1, -6)
			local testname = path.getname(basename .. ".cs")
			if premake.findfile(prj, testname) then
				if premake.findfile(prj, basename .. ".Designer.cs") then
					return "DesignerType", testname
				else
					return "Dependency", testname
				end
			else
				-- is there a matching *.Designer.cs?
				testname = path.getname(basename .. ".Designer.cs")
				if premake.findfile(prj, testname) then
					return "AutoGenerated"
				end
			end
		end
				
		if action == "Content" then
			return "CopyNewest"
		end
		
		return "None"
	end


--
-- Write out the <Files> element.
--

	function cs2005.files_old(prj)
		local tr = premake.project.buildsourcetree(prj)
		premake.tree.traverse(tr, {
			onleaf = function(node)
				local action = premake.dotnet.getbuildaction(node.cfg)
				local fname  = path.translate(premake.esc(node.cfg.name), "\\")
				local elements, dependency = getelements(prj, action, node.path)

				if elements == "None" then
					_p('    <%s Include="%s" />', action, fname)
				else
					_p('    <%s Include="%s">', action, fname)
					if elements == "AutoGen" then
						_p('      <AutoGen>True</AutoGen>')
					elseif elements == "AutoGenerated" then
						_p('      <SubType>Designer</SubType>')
						_p('      <Generator>ResXFileCodeGenerator</Generator>')
						_p('      <LastGenOutput>%s.Designer.cs</LastGenOutput>', premake.esc(path.getbasename(node.name)))
					elseif elements == "SubTypeDesigner" then
						_p('      <SubType>Designer</SubType>')
					elseif elements == "SubTypeForm" then
						_p('      <SubType>Form</SubType>')
					elseif elements == "PreserveNewest" then
						_p('      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>')
					end
					if dependency then
						_p('      <DependentUpon>%s</DependentUpon>', path.translate(premake.esc(dependency), "\\"))
					end
					_p('    </%s>', action)
				end
			end
		}, false)
	end


--
-- Write the opening PropertyGroup, which contains the project-level settings.
--

	function cs2005.projectsettings_old(prj)
		local version = {
			vs2005 = '8.0.50727',
			vs2008 = '9.0.21022',
			vs2010 = '8.0.30703',
			vs2012 = '8.0.30703',
		}
		
		local frameworks = {
			vs2010 = "4.0",
			vs2012 = "4.5",
		}

		_p('  <PropertyGroup>')
		_p('    <Configuration Condition=" \'$(Configuration)\' == \'\' ">%s</Configuration>', premake.esc(prj.solution.configurations[1]))
		_p('    <Platform Condition=" \'$(Platform)\' == \'\' ">%s</Platform>', cs2005.arch(prj))
		_p('    <ProductVersion>%s</ProductVersion>', version[_ACTION])
		_p('    <SchemaVersion>2.0</SchemaVersion>')
		_p('    <ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
		_p('    <OutputType>%s</OutputType>', premake.dotnet.getkind(prj))
		_p('    <AppDesignerFolder>Properties</AppDesignerFolder>')
		_p('    <RootNamespace>%s</RootNamespace>', prj.buildtarget.basename)
		_p('    <AssemblyName>%s</AssemblyName>', prj.buildtarget.basename)

		local framework = prj.framework or frameworks[_ACTION]
		if framework then
			_p('    <TargetFrameworkVersion>v%s</TargetFrameworkVersion>', framework)
		end

		if _ACTION >= "vs2010" then
			_p('    <TargetFrameworkProfile>Client</TargetFrameworkProfile>')
			_p('    <FileAlignment>512</FileAlignment>')
		end
		
		_p('  </PropertyGroup>')
	end


--
-- The main function: write the project file.
--

	function cs2005.generate(prj)
		io.eol = "\r\n"
		io.indent = "  "

		cs2005.projectelement(prj)
		cs2005.projectsettings_old(prj)

		for cfg in premake.eachconfig(prj) do
			cs2005.propertygroup(cfg)

			if cfg.flags.Symbols then
				_p('    <DebugSymbols>true</DebugSymbols>')
				_p('    <DebugType>full</DebugType>')
			else
				_p('    <DebugType>pdbonly</DebugType>')
			end
			_p('    <Optimize>%s</Optimize>', iif(cfg.flags.Optimize or cfg.flags.OptimizeSize or cfg.flags.OptimizeSpeed, "true", "false"))
			_p('    <OutputPath>%s</OutputPath>', cfg.buildtarget.directory)
			_p('    <DefineConstants>%s</DefineConstants>', table.concat(premake.esc(cfg.defines), ";"))
			_p('    <ErrorReport>prompt</ErrorReport>')
			_p('    <WarningLevel>4</WarningLevel>')
			if cfg.flags.Unsafe then
				_p('    <AllowUnsafeBlocks>true</AllowUnsafeBlocks>')
			end
			if cfg.flags.FatalWarnings then
				_p('    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>')
			end
			_p('  </PropertyGroup>')
		end

		_p('  <ItemGroup>')
		for _, ref in ipairs(premake.getlinks(prj, "siblings", "object")) do
			_p('    <ProjectReference Include="%s">', path.translate(path.getrelative(prj.location, vstudio.projectfile_old(ref)), "\\"))
			_p('      <Project>{%s}</Project>', ref.uuid)
			_p('      <Name>%s</Name>', premake.esc(ref.name))
			_p('    </ProjectReference>')
		end
		for _, linkname in ipairs(premake.getlinks(prj, "system", "basename")) do
			_p('    <Reference Include="%s" />', premake.esc(linkname))
		end
		_p('  </ItemGroup>')

		_p('  <ItemGroup>')
		cs2005.files_old(prj)
		_p('  </ItemGroup>')

		_p('  <Import Project="$(MSBuildBinPath)\\Microsoft.CSharp.targets" />')
		_p('  <!-- To modify your build process, add your task inside one of the targets below and uncomment it.')
		_p('       Other similar extension points exist, see Microsoft.Common.targets.')
		_p('  <Target Name="BeforeBuild">')
		_p('  </Target>')
		_p('  <Target Name="AfterBuild">')
		_p('  </Target>')
		_p('  -->')
		_p('</Project>')
		
	end

