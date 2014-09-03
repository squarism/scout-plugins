class NginxReport < Scout::Plugin
  needs 'open-uri'

  # will retry fetching stats on these exceptions
  RETRY_EXCEPTIONS = [Errno::ECONNREFUSED, Errno::ECONNRESET]
  
  OPTIONS=<<-EOS
  url:
    name: Status URL
    default: "http://127.0.0.1/nginx_status"
  EOS

  def build_report  
    url = option(:url) || 'http://127.0.0.1/nginx_status'

    total, requests, reading, writing, waiting = nil
    response = get_stats_response(url)
    return if response.nil? # error fetching status, like a 404
    response.read.each_line do |line|
      total = $1 if line =~ /^Active connections:\s+(\d+)/
      if line =~ /^Reading:\s+(\d+).*Writing:\s+(\d+).*Waiting:\s+(\d+)/
        reading = $1
        writing = $2
        waiting = $3
      end
      requests = $3 if line =~ /^\s+(\d+)\s+(\d+)\s+(\d+)/  
    end

    report({:total => total, :reading => reading, :writing => writing, :waiting => waiting, :requests => requests})

    counter(:requests_per_sec, requests.to_i, :per => :second)
  rescue => e
    # ignore these exceptions. remember the counter value.
    # nginx restarts are causing issues connecting to the stats page.
    if RETRY_EXCEPTIONS.include?(e.class)
      counter(:requests_per_sec, requests.to_i, :per => :second)
      report(:connection_error => 1)
    else
      raise
    end
  end

  # fetches the stats page. on exception, will retry once more, sleeping two seconds before retrying.
  def get_stats_response(url)
    retried = false
    response = nil
    begin
      response = open(url)
    rescue => e
      if RETRY_EXCEPTIONS.include?(e.class) and !retried
        retried = true
        sleep(2)
        retry
      elsif e.message.include?("404") # provide a friendly error on 404s
        error("Status Page not found","The status page was not found at #{url}. Please ensure the url is correct.")
      else
        raise
      end
    end
    response
  end

end
