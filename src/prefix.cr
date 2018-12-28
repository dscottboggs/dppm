require "./config"

struct Prefix
  getter path : String,
    app : String,
    pkg : String,
    src : String

  def initialize(@path : String, create : Bool = false)
    @app = @path + "/app/"
    @pkg = @path + "/pkg/"
    @src = @path + "/src/"
    FileUtils.mkdir_p({@app, @pkg}) if create
  end

  def each_app(&block : App ->)
    Dir.each_child(@app) do |dir|
      yield App.new self, dir
    end
  end

  def each_pkg(&block : Pkg ->)
    Dir.each_child(@pkg) do |dir|
      yield Pkg.new self, dir
    end
  end

  def each_src(&block : Src ->)
    Dir.each_child(@src) do |dir|
      yield Src.new(self, dir) if dir[0].ascii_lowercase?
    end
  end

  def new_app(name : String) : App
    App.new self, name
  end

  def new_pkg(name : String) : Pkg
    Pkg.new self, name
  end

  def new_src(name : String) : Src
    Src.new self, name
  end
end

require "./prefix/*"
