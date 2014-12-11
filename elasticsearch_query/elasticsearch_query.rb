# Runs the given query and reports on if the query succeeded.
class ElasticsearchQuery < Scout::Plugin

  OPTIONS = <<-EOS
    elasticsearch_host:
      default: http://127.0.0.1
      name: Host URL
      notes: "The URL to the host elasticsearch is running on. Include the protocal (http// or https://) in the URL."
    elasticsearch_port:
      default: 9200
      name: Port
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
      name: Index Name
      notes: "Name of the index you wish to monitor. If the index roles up by date (ex: index_name-2014.12.09), exclude the '-2014.12.09' portion."
  EOS

  needs 'net/http', 'net/https', 'json', 'open-uri'

  def build_report
    if option(:elasticsearch_host).nil? || option(:elasticsearch_port).nil? || option(:index_name).nil?
      return error("Please provide the host, port, and index name", "The elasticsearch host, port, and index to monitor are required.\n\nelasticsearch Host: #{option(:elasticsearch_host)}\n\nelasticsearch Port: #{option(:elasticsearch_port)}\n\nIndex Name: #{option(:index_name)}")
    end

    if option(:username).nil? != option(:password).nil?
      return error("Please provide both username and password", "Both the elasticsearch username and password to monitor the protected cluster are required.\n\nUsername: #{option(:username)}\n\nPassword: #{option(:password)}")
    end

    index_name = option(:index_name)
    index_name += "-#{Time.now.strftime("%Y.%m.%d")}"

    base_url = "#{option(:elasticsearch_host)}:#{option(:elasticsearch_port)}/#{index_name}/_search?pretty"

    resp = get_response(base_url)
    response = JSON.parse(resp.body)

    if response["error"]
      report(:error => 1)
    else
      report(:error => 0,:query_time => response["took"], :hits => response["hits"]["total"])
    end
    report(:status => response["status"])


  rescue OpenURI::HTTPError
    error("Stats URL not found", "Please ensure the base url for elasticsearch index stats is correct. Current URL: \n\n#{base_url}")
  rescue SocketError
    error("Hostname is invalid", "Please ensure the elasticsearch Host is correct - the host could not be found. Current URL: \n\n#{base_url}")
  rescue Errno::ECONNREFUSED
    error("Unable to connect", "Please ensure the host and port are correct. Current URL: \n\n#{base_url}")
  end

  def search_metrics(indices)
    index_name = option(:index_name)
    search_stats = indices[index_name]['primaries']['search']
    # sample
    # {"open_contexts"=>0, "query_total"=>319796, "query_time_in_millis"=>22074525, "query_current"=>0, "fetch_total"=>12014, "fetch_time_in_millis"=>698430, "fetch_current"=>0} 
    queries_before = memory("_counter_query_rate")
    query_total = search_stats['query_total']
    query_time = search_stats['query_time_in_millis']
    counter(:query_rate, query_total, :per => :second)
    last_query_time = memory("last_query_time")
    if queries_before and !last_query_time.nil?
      avg_query_time = (query_time - last_query_time)/(query_total-queries_before[:value]).to_f
      report(:query_time=>avg_query_time) if avg_query_time >= 0 # handle a reset
    end
    remember(:last_query_time,query_time)
  end

  # All of the elasticsearch methods use this same logic. If this needs an update, an update may be required in others as well.
  def get_response(base_url)
    uri = URI.parse(base_url)

    http = Net::HTTP.new(uri.host,uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.start { |h|
      req = Net::HTTP::Get.new(uri.path+"?"+uri.query.to_s)
      if !option(:username).nil? && !option(:password).nil?
        req.basic_auth option(:username), option(:password)
      end
      req.body=query_data
      response = h.request(req)
    }
  end

  # Generates the query data, querying against @timestamp 15 minutes ago till now.
  def query_data
    t = Time.now.to_i
    QUERY_STRING.sub("FROM",((t-15*60)*1000).to_s).sub("TO",(t*1000).to_s)
  end

  QUERY_STRING = <<-END_QUERY_STRING
    {
    "query": {
      "filtered": {
        "query": {
          "bool": {
            "should": [
              {
                "query_string": {
                  "query": "*"
                }
              }
            ]
          }
        },
        "filter": {
          "bool": {
            "must": [
              {
                "range": {
                  "@timestamp": {
                    "from": FROM,
                    "to": TO
                  }
                }
              }
            ]
          }
        }
      }
    },
    "highlight": {
      "fields": {},
      "fragment_size": 2147483647,
      "pre_tags": [
        "@start-highlight@"
      ],
      "post_tags": [
        "@end-highlight@"
      ]
    },
    "size": 500,
    "sort": [
      {
        "@timestamp": {
          "order": "desc"
        }
      },
      {
        "@timestamp": {
          "order": "desc"
        }
      }
    ]
    }
  END_QUERY_STRING

end
