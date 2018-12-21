require "exec"
require "./config"
require "./host"
require "./httpget"
require "./manager/*"
require "./prefix"
require "./service"

module Manager
  extend self
  PREFIX = Process.root? ? "/srv/dppm" : ENV["HOME"] + "/.dppm"

  def cli_confirm
    puts "\nContinue? [N/y]"
    case gets
    when "Y", "y" then true
    else               puts "cancelled."
    end
  end

  def exec(command : String, args : Array(String) | Tuple) : String
    Exec.new command, args, output: Log.output, error: Log.error do |process|
      raise "execution returned an error: #{command} #{args.join ' '}" if !process.wait.success?
    end
    "success"
  end
end
