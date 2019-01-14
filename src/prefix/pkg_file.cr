require "con"

struct Prefix::PkgFile
  enum Type
    App
    Lib

    def self.new(type : String)
      case type
      when "app" then App
      when "lib" then Lib
      else            raise "unknow package type: " + type
      end
    end
  end
  getter package : String,
    name : String,
    type : Type,
    license : String,
    url : String,
    docs : String,
    description : String,
    info : String,
    provides : String?,
    deps : Hash(String, String)?,
    aliases : Hash(String, String)?,
    env : Hash(String, String)?,
    databases : Hash(String, String?)?,
    tasks : Hash(String, Array(CON::Any))?,
    shared : Bool?,
    ipv6_braces : Bool?,
    version : CON::Any,
    tags : CON::Any,
    any : CON::Any
  property exec : Hash(String, String)?

  getter path : String do
    self.class.path @root_dir
  end

  def self.path(root_dir) : String
    root_dir + "pkg.con"
  end

  protected def path=(@path : String?) : String?
  end

  protected property root_dir : String

  getter? config : Hash(String, String)?

  getter config : Hash(String, String) do
    if config = @config
      config
    else
      raise "no `config` key entry in " + path
    end
  end

  macro finished
  def initialize(@root_dir : String)
    raise "package directory doesn't exists: " + @root_dir if !Dir.exists? @root_dir

    # TODO: Replace CON::Any by CON::Serializable
    @any = CON.parse File.read(path)

    {% for string in %w(name package license url docs description info) %}\
    @{{string.id}} = @any[{{string}}].as_s
    {% end %}
    @type = Type.new @any["type"].as_s
    @version = @any["version"]
    @tags = @any["tags"]
    if provides = @any["provides"]?
      @provides = provides.as_s
    end
    @shared = if shared = @any["shared"]?
                shared.as_bool?
              end
    @ipv6_braces = if ipv6_braces = @any["ipv6_braces"]?
                     ipv6_braces.as_bool?
                   end
    {% for hash in %w(deps aliases env exec config) %}\
    if {{hash.id}}_any = @any[{{hash}}]?
      {{hash.id}} = Hash(String, String).new
      {{hash.id}}_any.as_h.each do |k, v|
        {{hash.id}}[k] = v.as_s
      end
      @{{hash.id}} = {{hash.id}}
    end
    {% end %}
    if tasks_any = @any["tasks"]?
      tasks = Hash(String, Array(CON::Any)).new
      tasks_any.as_h.each do |task, value|
        tasks[task] = value.as_a
      end
      @tasks = tasks
    end
    if databases_any = @any["databases"]?
      databases = Hash(String, String?).new
      databases_any.as_h.each do |database, value|
        databases[database] = value.as_s?
      end
      @databases = databases
    end
  end
  end

  def each_version(arch : String = Host.arch, kernel : String = Host.kernel, &block : String ->)
    # Set src and regex
    if hash = @version["self"]?
      src = hash["src"]?
      regex = hash["regex"]?
    end

    if version_kernel = @version[kernel]?
      if !regex
        raise "unsupported architecure: " + arch if !src
        regex = version_kernel[arch]
      end
    elsif !src && !regex
      raise "unsupported kernel: " + kernel
    end

    if src
      if (src_array = src.as_a?)
        src_array.each do |version|
          yield version.as_s
        end
      else
        HTTPget.string(src.to_s).each_line do |line|
          yield $0 if line =~ /#{regex}/
        end
      end
    else
      raise "no source url"
    end
  end

  def version_from_tag(tag : String) : String
    src = @tags[tag]["src"].as_s
    # Test if the src is an URL or a version number
    if Utils.is_http? src
      regex = if regex_tag = @tags[tag]["regex"]?
                regex_tag
              else
                @tags["self"]["regex"]
              end.as_s
      /(#{regex})/ =~ HTTPget.string(src)
      $1
    else
      src
    end
  end
end