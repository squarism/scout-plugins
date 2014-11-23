require File.expand_path('../../test_helper.rb', __FILE__)
require File.expand_path('../elasticsearch_index_stats.rb', __FILE__)

class ElasticsearchIndexStatsTest < Test::Unit::TestCase
  def setup
    @options = parse_defaults("elasticsearch_index_stats")
    @plugin = ElasticsearchIndexStats.new(nil, {}, @options)
  end
  
  def teardown
    FakeWeb.clean_registry
  end

  def test_initial_run
  	response = '{"cluster_name":"elasticsearch","nodes":{"2XjvHGgCShSoL8UECf49vw":{"timestamp":1416613038206,"name":"es-01","transport_address":"inet[/168.18.0.9:9300]","host":"es-01","ip":["inet[/168.18.0.9:9300]","NONE"],"indices":{"docs":{"count":55289673,"deleted":116672},"store":{"size_in_bytes":128040430484,"throttle_time_in_millis":947491},"indexing":{"index_total":1916178,"index_time_in_millis":4658503,"index_current":43,"delete_total":0,"delete_time_in_millis":0,"delete_current":0},"get":{"total":961672,"time_in_millis":224618,"exists_total":4803,"exists_time_in_millis":53157,"missing_total":956869,"missing_time_in_millis":171461,"current":0},"search":{"open_contexts":0,"query_total":319796,"query_time_in_millis":22074525,"query_current":0,"fetch_total":12014,"fetch_time_in_millis":698430,"fetch_current":0},"merges":{"current":0,"current_docs":0,"current_size_in_bytes":0,"total":72597,"total_time_in_millis":41670814,"total_docs":69788942,"total_size_in_bytes":179670794881},"refresh":{"total":768089,"total_time_in_millis":15177334},"flush":{"total":23597,"total_time_in_millis":8461780},"warmer":{"current":0,"total":1501431,"total_time_in_millis":480991},"filter_cache":{"memory_size_in_bytes":273718604,"evictions":0},"id_cache":{"memory_size_in_bytes":0},"fielddata":{"memory_size_in_bytes":71581168,"evictions":0},"percolate":{"total":0,"time_in_millis":0,"current":0,"memory_size_in_bytes":-1,"memory_size":"-1b","queries":0},"completion":{"size_in_bytes":0},"segments":{"count":15747,"memory_in_bytes":940808472,"index_writer_memory_in_bytes":0,"version_map_memory_in_bytes":0},"translog":{"operations":3084,"size_in_bytes":0},"suggest":{"total":0,"time_in_millis":0,"current":0}}}}}'
    FakeWeb.register_uri(:get, "http://127.0.0.1:9200/_nodes/_local/stats/indices", :body => response)
    res = @plugin.run
    assert res[:reports].empty? # need a 2nd run
  end

  def test_second_run
  	response = '{"cluster_name":"elasticsearch","nodes":{"2XjvHGgCShSoL8UECf49vw":{"timestamp":1416613038206,"name":"es-01","transport_address":"inet[/168.18.0.9:9300]","host":"es-01","ip":["inet[/168.18.0.9:9300]","NONE"],"indices":{"docs":{"count":55289673,"deleted":116672},"store":{"size_in_bytes":128040430484,"throttle_time_in_millis":947491},"indexing":{"index_total":1916178,"index_time_in_millis":4658503,"index_current":43,"delete_total":0,"delete_time_in_millis":0,"delete_current":0},"get":{"total":961672,"time_in_millis":224618,"exists_total":4803,"exists_time_in_millis":53157,"missing_total":956869,"missing_time_in_millis":171461,"current":0},"search":{"open_contexts":0,"query_total":100,"query_time_in_millis":200,"query_current":0,"fetch_total":12014,"fetch_time_in_millis":698430,"fetch_current":0},"merges":{"current":0,"current_docs":0,"current_size_in_bytes":0,"total":72597,"total_time_in_millis":41670814,"total_docs":69788942,"total_size_in_bytes":179670794881},"refresh":{"total":768089,"total_time_in_millis":15177334},"flush":{"total":23597,"total_time_in_millis":8461780},"warmer":{"current":0,"total":1501431,"total_time_in_millis":480991},"filter_cache":{"memory_size_in_bytes":273718604,"evictions":0},"id_cache":{"memory_size_in_bytes":0},"fielddata":{"memory_size_in_bytes":71581168,"evictions":0},"percolate":{"total":0,"time_in_millis":0,"current":0,"memory_size_in_bytes":-1,"memory_size":"-1b","queries":0},"completion":{"size_in_bytes":0},"segments":{"count":15747,"memory_in_bytes":940808472,"index_writer_memory_in_bytes":0,"version_map_memory_in_bytes":0},"translog":{"operations":3084,"size_in_bytes":0},"suggest":{"total":0,"time_in_millis":0,"current":0}}}}}'
    FakeWeb.register_uri(:get, "http://127.0.0.1:9200/_nodes/_local/stats/indices", :body => response)
    first_run_memory = @plugin.run[:memory]
    Timecop.travel(Time.now+5*60) do # 5 minute later
    	plugin=ElasticsearchIndexStats.new(nil,first_run_memory,@options)
    	# increased query total and query time by 100x
  		response = '{"cluster_name":"elasticsearch","nodes":{"2XjvHGgCShSoL8UECf49vw":{"timestamp":1416613038206,"name":"es-01","transport_address":"inet[/168.18.0.9:9300]","host":"es-01","ip":["inet[/168.18.0.9:9300]","NONE"],"indices":{"docs":{"count":55289673,"deleted":116672},"store":{"size_in_bytes":128040430484,"throttle_time_in_millis":947491},"indexing":{"index_total":1916178,"index_time_in_millis":4658503,"index_current":43,"delete_total":0,"delete_time_in_millis":0,"delete_current":0},"get":{"total":961672,"time_in_millis":224618,"exists_total":4803,"exists_time_in_millis":53157,"missing_total":956869,"missing_time_in_millis":171461,"current":0},"search":{"open_contexts":0,"query_total":10000,"query_time_in_millis":20000,"query_current":0,"fetch_total":12014,"fetch_time_in_millis":698430,"fetch_current":0},"merges":{"current":0,"current_docs":0,"current_size_in_bytes":0,"total":72597,"total_time_in_millis":41670814,"total_docs":69788942,"total_size_in_bytes":179670794881},"refresh":{"total":768089,"total_time_in_millis":15177334},"flush":{"total":23597,"total_time_in_millis":8461780},"warmer":{"current":0,"total":1501431,"total_time_in_millis":480991},"filter_cache":{"memory_size_in_bytes":273718604,"evictions":0},"id_cache":{"memory_size_in_bytes":0},"fielddata":{"memory_size_in_bytes":71581168,"evictions":0},"percolate":{"total":0,"time_in_millis":0,"current":0,"memory_size_in_bytes":-1,"memory_size":"-1b","queries":0},"completion":{"size_in_bytes":0},"segments":{"count":15747,"memory_in_bytes":940808472,"index_writer_memory_in_bytes":0,"version_map_memory_in_bytes":0},"translog":{"operations":3084,"size_in_bytes":0},"suggest":{"total":0,"time_in_millis":0,"current":0}}}}}'
    	FakeWeb.register_uri(:get, "http://127.0.0.1:9200/_nodes/_local/stats/indices", :body => response)
    	res = plugin.run
    	assert_equal 2, res[:reports].size
    	assert res[:errors].empty?
    end
  end
end