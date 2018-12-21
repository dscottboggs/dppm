struct Service::Systemd::Config
  getter section = Hash(String, Hash(String, String)).new

  def initialize
    @section = base
  end

  def self.parse(file : String)
    if File.exists? file
      new File.read file
    else
      new
    end
  end

  def base
    {"Unit" => {
      "After" => "network.target",
    },
     "Service" => {
       "Type"    => "simple",
       "Restart" => "always",
     },
     "Install" => {
       "WantedBy" => "multi-user.target",
     }}
  end

  def shim(name)
    case name
    when "directory"     then {"Service", "WorkingDirectory"}
    when "command"       then {"Service", "ExecStart"}
    when "user"          then {"Service", "User"}
    when "group"         then {"Service", "Group"}
    when "after"         then {"Unit", "After"}
    when "want"          then {"Unit", "Wants"}
    when "environment"   then {"Service", "Environment"}
    when "description"   then {"Unit", "Description"}
    when "restart_delay" then {"Service", "RestartSec"}
    when "network"       then {"network.target", ""}
    when "umask"         then {"Service", "UMask"}
    when "reload"        then {"Service", "ExecReload"}
    when "pidfile"       then {"Service", "PIDFile"}
    when "log_output"    then {"Service", "StandardOutput"}
    when "log_error"     then {"Service", "StandardError"}
    else                      raise "don't exist in systemd: " + name
    end
  end

  def get(name : String)
    keys = shim name
    case name
    when "log_output", "log_error" then @section[keys[0]][keys[1]].lstrip "file:"
    else                                @section[keys[0]][keys[1]]
    end
  end

  def set(name : String, value)
    keys = shim name
    case name
    when "log_output", "log_error"
      # systemd 236 and more supports file logging
      if Systemd.version >= 236
        @section[keys[0]][keys[1]] = "file:" + value
      else
        Log.warn "file logging not supported", "systemd version '#{Systemd.version}' too old (>=336 needed)"
      end
    when "reload"
      @section[keys[0]][keys[1]] = "/bin/kill -#{value} $MAINPID"
    else
      @section[keys[0]][keys[1]] = value
    end
  end

  def env_get(env)
    Service::Env.new(@section["Service"]["Environment"]).get env
  end

  def env_set(env, value)
    @section["Service"]["Environment"] = Service::Env.new(@section["Service"]["Environment"]?).set env, value
  end
end
