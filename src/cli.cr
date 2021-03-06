require "clicr"
require "./prefix"
require "./cli/*"

module CLI
  extend self
  include Clicr

  macro run(**additional_commands)
  def CLI.internal_run
    __debug = false
    prefix = if (current_dir = Dir.current).ends_with? "/app/dppm"
               File.dirname(File.dirname(File.dirname(File.dirname current_dir)))
             elsif File.exists? "/usr/local/bin/dppm"
               File.dirname(File.dirname(File.dirname(File.dirname(File.dirname(File.real_path "/usr/local/bin/dppm")))))
             elsif Process.root? && Dir.exists? "/srv"
               "/srv/dppm"
             elsif xdg_data_home = ENV["XDG_DATA_HOME"]?
               xdg_data_home + "/dppm"
             else
               ENV["HOME"] + "/.dppm"
             end
    Clicr.create(
      name: "dppm",
      info: "The DPlatform Package Manager",
      variables: {
        prefix: {
          info:    "Base path for dppm packages, sources and apps",
          default: prefix,
        },
        config: {
          info: "Configuration file path",
        },
        source: {
          info: "Source path/url of the packages and configurations (default in the config file)",
        },
      },
      options: {
        debug: {
          short: 'd',
          info:  "Debug print with error backtraces",
        },
        no_confirm: {
          short: 'y',
          info:  "No confirmations",
        },
      },
      commands: {
        app: {
          alias:    'a',
          info:     "Manage applications",
          commands: {
            add: {
              alias:     'a',
              info:      "Add a new application (builds its missing dependencies)",
              arguments: \%w(application custom_vars...),
              action:    "App.add",
              options:   {
                contained: {
                  short: 'c',
                  info:  "No shared dependencies, copy instead of symlinks",
                },
                noservice: {
                  short: 'n',
                  info:  "Don't add a system service",
                },
                socket: {
                  short: 's',
                  info:  "Use of an UNIX socket instead of a port",
                },
              },
              variables: {
                database: {
                  info: "Application name of the database to use",
                },
                name: {
                  info: "Name of the application to install",
                },
                url: {
                  info: "URL address (like https://myapp.example.net or http://[::1]/myapp), usually used with a web server",
                },
                web_server: {
                  info: "Application name of the web server serving this application as a public website",
                },
              },
            },
            config: {
              alias:   'c',
              info:    "Manage application's configuration",
              options: {
                nopkg: {
                  short: 'n',
                  info:  "Don't use pkg file, directly use the application's configuration file",
                },
              },
              commands: {
                get: {
                  info:      "Get a value. Single dot path `.` for all keys",
                  arguments: \%w(application path),
                  action:    "App.config_get",
                },
                set: {
                  info:      "Set a value",
                  arguments: \%w(application path value),
                  action:    \%(App.config_set() && Log.output.puts "done"),
                },
                del: {
                  info:      "Delete a path",
                  arguments: \%w(application path),
                  action:    \%(App.config_del() && Log.output.puts "done"),
                },
              },
            },
            delete: {
              alias:     'd',
              info:      "Delete an added application",
              arguments: \%w(application custom_vars...),
              action:    "App.delete",
              options:   {
                keep_user_group: {
                  short: 'k',
                  info:  "Don't delete the system user and groupof the application",
                },
                preserve_database: {
                  short: 'p',
                  info:  "Preserve the database used by the application from deletion",
                },
              },
            },
            exec: {
              alias:     'e',
              info:      "Execute an application in the foreground",
              arguments: \%w(application),
              action:    "App.exec",
            },
            list: {
              alias:  'l',
              info:   "List applications",
              action: "List.app",
            },
            logs: {
              alias:     'L',
              info:      "Read logs of the application's service - list log names if empty",
              arguments: \%w(application log_names...),
              action:    "App.logs() { |log| Log.output << log }",
              options:   {
                follow: {
                  short: 'f',
                  info:  "Follow new lines, starting to the last 10 lines by default",
                },
              },
              variables: {
                lines: {
                  info: "Number of last lines to print. All lines when no set",
                },
              },
            },
            query: {
              alias:     'q',
              info:      "Query informations from an application - `.` for the whole document",
              arguments: \%w(application path),
              action:    "Log.output.puts App.query",
            },
            version: {
              alias:     'v',
              info:      "Returns application's version",
              arguments: \%w(application),
              action:    "Log.output.puts App.version",
            },
          },
        },
        install: {
          alias:  'i',
          info:   "Install DPPM to a new defined prefix",
          action: "install_dppm",
        },
        list: {
          alias:  'l',
          info:   "List all applications, packages and sources",
          action: "List.all",
        },
        package: {
          alias:     'p',
          info:      "Manage built packages",
          variables: {
            version: {
              info: "Package version",
            },
            tag: {
              info: "Package version's tag (e.g: latest)",
            },
          },
          commands: {
            build: {
              alias:     'b',
              info:      "Build a new a package",
              arguments: \%w(package custom_vars...),
              action:    "Pkg.build",
            },
            clean: {
              alias:  'C',
              info:   "Clean unused built packages by the applications",
              action: "Pkg.clean_unused_packages",
            },
            delete: {
              alias:     'd',
              info:      "Delete a built package",
              arguments: \%w(package custom_vars...),
              action:    "Pkg.delete",
            },
            list: {
              alias:  'l',
              info:   "List packages",
              action: "List.pkg",
            },
            query: {
              alias:     'q',
              info:      "Query informations from a package - `.` for the whole document.",
              arguments: \%w(package path),
              action:    "Log.output.puts Pkg.query",
            },
          },
        },
        service: {
          alias:    'S',
          info:     "Manage application services",
          commands: {
            boot: {
              info:      "Auto-start the service at boot",
              arguments: \%w(service state),
              action:    "Service.boot",
            },
            reload: {
              info:      "Reload the service",
              arguments: \%w(service),
              action:    "Service.new().reload || exit 1",
            },
            restart: {
              info:      "Restart the service",
              arguments: \%w(service),
              action:    "Service.new().restart || exit 1",
            },
            start: {
              info:      "Start the service",
              arguments: \%w(service),
              action:    "Service.new().start || exit 1",
            },
            status: {
              info:      "Status for specified services or all services if none set",
              arguments: \%w(services...),
              action:    "Service.status",
              options:   {
                all: {
                  short: 'a',
                  info:  "list all system services",
                },
                noboot: {
                  info: "don't include booting status",
                },
                norun: {
                  info: "don't include running status",
                },
              },
            },
            stop: {
              info:      "Stop the service",
              arguments: \%w(service),
              action:    "Service.new().stop || exit 1",
            },
          },
        },
        source: {
          alias:    's',
          info:     "Manage packages sources",
          commands: {
            list: {
              alias:  'l',
              info:   "List source packages",
              action: "List.src",
            },
            query: {
              alias:     'q',
              info:      "Query informations from a source package - `.` for the whole document",
              arguments: \%w(package path),
              action:    "Log.output.puts Src.query",
            },
            update: {
              alias:  'u',
              info:   "Check for packages source updates. `-y` to force update",
              action: "Src.update",
            },
          },
        },
        uninstall: {
          alias:  'u',
          info:   "Uninstall DPPM with all its applications",
          action: "uninstall_dppm",
        },
        version: {
          alias:  'v',
          info:   "Version with general system information",
          action: "version",
        },
        {{**additional_commands}}
      }
    )
  rescue ex : Help
    Log.output.puts ex
  rescue ex : ArgumentRequired | UnknownCommand | UnknownOption | UnknownVariable
    abort ex
  rescue ex
    if __debug
      ex.inspect_with_backtrace Log.error
    else
      Log.error ex.to_s
    end
    exit 1
  end
  CLI.internal_run
  end

  def version(**args)
    Log.output << "DPPM version: " << DPPM.version << '\n'
    Log.output << "DPPM build commit: " << DPPM.build_commit << '\n'
    Log.output << "DPPM build date: " << DPPM.build_date << '\n'
    Host.vars.each do |variable, value|
      Log.output << variable << ": " << value << '\n'
    end
  end

  def query(any : CON::Any, path : String) : CON::Any
    case path
    when "." then any
    else          any[Utils.to_array path]
    end
  end

  def install_dppm(no_confirm, config, source, prefix, debug = nil)
    root_prefix = Prefix.new prefix

    if root_prefix.dppm.exists?
      Log.info "DPPM already installed", root_prefix.path
      return root_prefix
    end
    root_prefix.create

    begin
      root_prefix.update source

      dppm_package = root_prefix.new_pkg "dppm", DPPM.version
      dppm_package.copy_src_to_path

      Dir.mkdir dppm_package.app_path
      Dir.mkdir dppm_package.app_path + "/bin"
      dppm_bin_path = dppm_package.app_path + "/bin/dppm"
      FileUtils.cp PROGRAM_NAME, dppm_bin_path
      app = dppm_package.new_app "dppm"

      app.add(
        vars: {"uid" => "0", "gid" => "0", "user" => "root", "group" => "root"},
        shared: true,
        confirmation: !no_confirm
      ) do
        no_confirm || CLI.confirm_prompt { raise "DPPM installation canceled." }
      end
    rescue ex
      root_prefix.delete_src
      FileUtils.rm_r root_prefix.path
      raise Exception.new "DPPM installation failed, #{root_prefix.path} deleted:\n#{ex}", ex
    end
    dppm_package.create_global_bin_symlinks(force: true) if Process.root?
    Log.info "DPPM installation complete", "you can now manage applications with the `#{Process.root? ? "dppm" : dppm_bin_path}` command"
    File.delete PROGRAM_NAME
  end

  def uninstall_dppm(no_confirm, config, source, prefix, debug = nil)
    root_prefix = Prefix.new prefix

    raise "DPPM not installed in " + root_prefix.path if !root_prefix.dppm.exists?
    raise "DPPM path not removable - root permission needed" + root_prefix.path if !File.writable? root_prefix.path

    # Delete each installed app
    root_prefix.each_app do |app|
      app.delete(confirmation: !no_confirm, preserve_database: false, keep_user_group: false) do
        no_confirm || CLI.confirm_prompt
      end
    end

    if (apps = Dir.children(root_prefix.app).join ", ").empty?
      root_prefix.delete_src
      FileUtils.rm_r root_prefix.path
      Log.info "DPPM uninstallation complete", root_prefix.path
    else
      Log.warn "DPPM uninstallation not complete, there are remaining applications", apps
    end
  end

  def confirm_prompt(&block)
    Log.output.puts "\nContinue? [N/y]"
    case gets
    when "Y", "y" then true
    else               yield
    end
  end

  def confirm_prompt
    confirm_prompt { abort "cancelled." }
  end
end
