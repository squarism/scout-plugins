# =================================================================================
# rabbitmq_overall
#
# Created by Erik Wickstrom on 2011-10-14.
# =================================================================================
class RabbitmqOverall < Scout::Plugin
  needs 'rubygems'
  needs 'json'
  needs 'net/http'

  OPTIONS=<<-EOS
    management_url:
        default: http://localhost:15672
        notes: The base URL of your RabbitMQ Management server. (Use port 55672 if you are using RabbitMQ older than 3.x)
    username:
        default: guest
    password:
        default: guest
        attributes: password
    monitor_user:
        default: true
        notes: Is username a monitor user?
  EOS

  def build_report
    overview = get('overview')

    results = {
      :bindings => get('bindings').length,
      :connections => get('connections').length,
      :queues => get('queues').length,
      :messages => (overview["queue_totals"].any? ? overview["queue_totals"]["messages"] : 0),
      :exchanges => get('exchanges').length
    }

    if option(:monitor_user)
      nodes = get('nodes')
      results[:queue_memory_used] = nodes[0]["mem_used"].to_f / (1024 * 1024)
    end

    report(results)
  rescue Errno::ECONNREFUSED
    error("Unable to connect to RabbitMQ Management server", "Please ensure the connection details are correct in the plugin settings.\n\nException: #{$!.message}\n\nBacktrace:\n#{$!.backtrace}")
  end
  
  private
  
  def get(name)
    url = "#{option('management_url').to_s.strip}/api/#{name}/"
    result = query_api(url)
  end

  def query_api(url)
     parsed = URI.parse(url)
     http = Net::HTTP.new(parsed.host, parsed.port)
     req = Net::HTTP::Get.new(parsed.path)
     req.basic_auth option(:username), option(:password)
     response = http.request(req)
     data = response.body
  
     # we convert the returned JSON data to native Ruby
     # data structure - a hash
     result = JSON.parse(data)
  
     return result
  end
end
