module CLI::List
  extend self

  def all(prefix, **args)
    root_prefix = Prefix.new prefix
    Log.output.puts "applications:"
    root_prefix.each_app { |app| Log.output.puts app.name }
    Log.output.puts "\npackages:"
    root_prefix.each_pkg { |pkg| Log.output.puts pkg.name }
    Log.output.puts "\nsources:"
    root_prefix.each_src { |src| Log.output.puts src.name }
  end

  {% for dir in %w(app pkg src) %}
  def {{dir.id}}(prefix, **args)
    Prefix.new(prefix).each_{{dir.id}} { |el| Log.output.puts el.name }
  end
  {% end %}
end
