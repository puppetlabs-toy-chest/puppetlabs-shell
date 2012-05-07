require 'puppet/face'
require 'puppet/util/interactive_shell'

Puppet::Face.define(:shell, '0.0.1') do
  copyright "Puppet Labs", 2012
  license   "Apache 2 license; see COPYING"

  summary "Interactive Puppet shell."

  option "--context CONTEXT" do |arg|
    summary "A ruby-only option used by the interactive shell."
  end

  def apply_code(text)
    puts text
    Puppet[:code] = text
    node = Puppet::Node.new(Puppet[:certname])
    catalog = Puppet::Resource::Catalog.indirection.find(node.name, :use_node => node)

    catalog = catalog.to_ral
    catalog.finalize
    catalog.apply
  end

  def get_context(options)
      options[:context] || Puppet::Util::InteractiveShell::ShellContext.new
  end

  def ral_to_resource(ral)
    resource = Puppet::Resource.new(ral.type, ral.name)
    ral.parameters.each do |name, param|
      resource[name] = param.value
    end
    resource
  end

  # Return an instance of Puppet::Resource, reflecting actual system state.
  def retrieve_resource(type_name, name)
    type = Puppet::Type.type(type_name) or raise("Could not find type #{type_name}")
    unless resource = type.instances.find { |r| r.name == name }
      raise "Could not find resource #{name} of type #{type_name}"
    end
    values = resource.retrieve
    values.each do |param, value| resource[param.name] = value end
    resource.to_resource
  end

  def list_types
    types = []
    Puppet::Type.loadall
    Puppet::Type.eachtype do |type|
      types << type.name.to_s
    end
    types.sort
  end

  def list_type(name, tail = nil)
    type = Puppet::Type.type(name) or raise("Could not find type #{name.inspect}")

    type.instances.collect do |instance|
      instance.name.to_s
    end
  end

  action(:interact) do
    summary "Operate interactively."
    returns <<-'EOT'
      Nil.
    EOT
    examples <<-'EOT'
      $ puppet shell interact
      > ls
      file
      ...
      > cd user
      > ls
      luke
      root
      ...

    EOT
    default

    when_invoked do |*args|
      options = args.pop
      require 'puppet/util/interactive_shell'
      shell = Puppet::Util::InteractiveShell.new
      shell.interact
    end
  end

  action(:edit) do
    summary "Change at stuff."
    returns <<-'EOT'
      A string.
    EOT
    examples <<-'EOT'
      Edit a resource:

      $ puppet shell
      > cd user
      > edit luke
      user { luke: ... }
    EOT

    when_invoked do |*args|
      require 'tempfile'

      options = args.pop
      context = get_context(options)
      # Yeah, this often won't work.  We should almost treat types specially...
      unless context.cwd.length > 0
        raise "Can only cat individual resources"
      end
      type_name = context.cwd[0]
      name = args.shift

      resource = retrieve_resource(type_name, name)

      file = Tempfile.new(resource.to_s)
      File.open(file.path, "w") { |f| f.puts resource.to_manifest }
      system(ENV['EDITOR'], file.path)
      text = File.read(file.path)

      apply_code(text)
      nil
    end
  end

  action(:cp) do
    summary "Copy stuff."
    returns <<-'EOT'
      nil
    EOT
    examples <<-'EOT'
      Copy a resource:

      $ puppet shell
      > cd user
      > cp luke foo uid=505
      > cat foo
      > rm foo
    EOT

    when_invoked do |*args|
      options = args.pop
      context = get_context(options)
      # Yeah, this often won't work.  We should almost treat types specially...
      unless context.cwd.length > 0
        raise "Can only cat individual resources"
      end
      type_name = context.cwd[0]
      old_name = args.shift
      new_name = args.shift
      resource = retrieve_resource(type_name, old_name)

      new_resource = Puppet::Resource.new(type_name, new_name)

      resource[:name] = new_name

      resource.each do |param, value|
        if value.to_s =~ /#{old_name}/i
          new_resource[param] = value.to_s.gsub(old_name, new_name).gsub(old_name.capitalize, new_name.capitalize)
        else
          new_resource[param] = value
        end
      end

      unless args.empty?
        args.each do |str|
          unless str.include?("=")
            Puppet.warning "Must specify new parameters as 'param=value'"
            next
          end
          param, value = str.split("=")
          new_resource[param] = value
        end
      end
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource(new_resource.to_ral)
      catalog.apply
      nil
    end
  end

  action(:rm) do
    summary "Destroy stuff."
    returns <<-'EOT'
      nil
    EOT
    examples <<-'EOT'
      Remove a resource:

      $ puppet shell
      > cd user
      > rm root
      > *boom* :)
    EOT

    when_invoked do |*args|
      options = args.pop
      context = get_context(options)
      # Yeah, this often won't work.  We should almost treat types specially...
      unless context.cwd.length > 0
        raise "Can only cat individual resources"
      end
      type_name = context.cwd[0]
      name = args.shift

      resource = Puppet::Resource.new(type_name, name)
      resource[:ensure] = :absent
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource(resource.to_ral)
      catalog.apply
      nil
    end
  end

  action(:cat) do
    summary "Look at stuff."
    returns <<-'EOT'
      A string.
    EOT
    examples <<-'EOT'
      List resource types:

      $ puppet shell
      > cd user
      > cat luke
      user { luke: ... }
    EOT

    when_invoked do |*args|
      options = args.pop
      context = get_context(options)
      # Yeah, this often won't work.  We should almost treat types specially...
      unless context.cwd.length > 0
        raise "Can only cat individual resources"
      end
      type_name = context.cwd[0]
      retrieve_resource(type_name, args.shift).to_manifest
    end
  end

  action(:cd) do
    summary "Change working directory."
    returns <<-'EOT'
      Nil.
    EOT
    examples <<-'EOT'
      List resource types:

      $ puppet shell
      > ls
      file
      ...
      > cd user
      > ls
      luke
      root
      ...

    EOT

    when_invoked do |*args|
      options = args.pop
      context = get_context(options)

      dir = args.shift
      if dir == "/"
        context.cwd.clear
      elsif dir == ".."
        context.cwd.pop
      else
        dirs = ls(options)
        unless dirs.include?(dir)
          raise "Cannot cd to '#{dir.inspect}' - no such dir"
        end
        context.cwd << dir
      end
      nil
    end
  end

  action(:pwd) do
    summary "Print working directory."
    returns <<-'EOT'
      Working directory as a string.
    EOT

    when_invoked do |*args|
      options = args.pop
      context = get_context(options)

      context.pwd
    end
  end

  action(:ls) do
    summary "List stuff."
    returns <<-'EOT'
      An array of things.
    EOT
    examples <<-'EOT'
      List resource types:

      $ puppet shell
      > ls
      file
      ...

    EOT

    when_invoked do |*args|
      options = args.pop
      context = get_context(options)

      if context.cwd.empty?
        list_types
      else
        list_type(*(context.cwd))
      end
    end

    when_rendering :console do |list|
      list.join("\n")
    end
  end

  action(:quit) do
    summary "Quit."
    returns <<-'EOT'
      Nil.
    EOT
    examples <<-'EOT'
      List resource types:

      $ puppet shell
      > quit
      $
    EOT

    when_invoked do |*args|
      options = args.pop
      exit(0)
    end
  end
end
