# Reports stats on an elasticsearch index, including index size, number of documents, etc.
#
# Created by John Wood of Signal
class ElasticsearchIndexStatus < Scout::Plugin

  OPTIONS = <<-EOS
    elasticsearch_host:
      default: http://127.0.0.1
      name: elasticsearch host
      notes: The host elasticsearch is running on
    elasticsearch_port:
      default: 9200
      name: elasticsearch port
      notes: The port elasticsearch is running on
    username:
      deault: nil
      name: Username
      notes: Username used to log into elasticsearch host if authentication is enabled.
    password:
      deault: nil
      name: Password
      notes: Password used to log into elasticsearch host if authentication is enabled.
    index_name:
      name: Index name
      notes: Name of the index you wish to monitor
  EOS

  needs 'net/http', 'json', 'open-uri'

  def build_report
    if option(:elasticsearch_host).nil? || option(:elasticsearch_port).nil? || option(:index_name).nil?
      return error("Please provide the host, port, and index name", "The elasticsearch host, port, and index to monitor are required.\n\nelasticsearch Host: #{option(:elasticsearch_host)}\n\nelasticsearch Port: #{option(:elasticsearch_port)}\n\nIndex Name: #{option(:index_name)}")
    end

    if option(:username).nil? != option(:password).nil?
      return error("Please provide both username and password", "Both the elasticsearch username and password to monitor the protected cluster are required.\n\nUsername: #{option(:username)}\n\nPassword: #{option(:password)}")
    end

    index_name = option(:index_name)

    base_url = "#{option(:elasticsearch_host)}:#{option(:elasticsearch_port)}/#{index_name}/_stats"
    req = Net::HTTP::Get.new(base_url)

    if !option(:username).nil? && !option(:password).nil?
      req.basic_auth option(:username), option(:password)
    end

    uri = URI.parse(base_url)
    resp = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
      http.request(req)
    }
    response = JSON.parse(resp.body)

    if response['error'] && response['error'] =~ /IndexMissingException/
      return error("No index found with the specified name", "No index could be found with the specified name.\n\nIndex Name: #{option(:index_name)}")
    end

    # support elasticsearch before and after formatting change
    indices = (response['_all'] && response['_all']['indices']) || response['indices']
    report(:primary_size => b_to_mb(indices[index_name]['primaries']['store']['size_in_bytes']) || 0)
    report(:size => b_to_mb(indices[index_name]['total']['store']['size_in_bytes']) || 0)
    report(:num_docs => indices[index_name]['primaries']['docs']['count'] || 0)

  rescue OpenURI::HTTPError
    error("Stats URL not found", "Please ensure the base url for elasticsearch index stats is correct. Current URL: \n\n#{base_url}")
  rescue SocketError
    error("Hostname is invalid", "Please ensure the elasticsearch Host is correct - the host could not be found. Current URL: \n\n#{base_url}")
  rescue Errno::ECONNREFUSED
    error("Unable to connect", "Please ensure the host and port are correct. Current URL: \n\n#{base_url}")
  end

  def b_to_mb(bytes)
    bytes && bytes.to_f / 1024 / 1024
  end

end
