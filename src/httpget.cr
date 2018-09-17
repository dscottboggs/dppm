require "halite"

# Method for redirections using the cossack http client
module HTTPget
  extend self

  def string(url)
    response = Halite.follow.get url
    case response.status_code
    when 200, 301, 302 then response.body
    else
      raise "status code #{response.status_code}: " + response.body
    end
  rescue ex
    raise "failed to get #{url.colorize.underline}: #{ex}"
  end

  def file(url, path = File.basename(url))
    File.write path, HTTPget.string(url)
  end
end