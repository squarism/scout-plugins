class NsqMonitor < Scout::Plugin
  needs 'net/http'
  needs 'json'

  OPTIONS = <<-EOS
    host:
      default: localhost
      name: host
      notes: The host of nsqdadmin
    port:
      default: 4151
      name: port
      notes: The port of nsqdadmin
    topic:
      default: topic
      name: Topic
      notes: The topic to monitor
    channel:
      default: channel
      name: Channel
      notes: The channel to monitor
  EOS

  def build_report
    uri = URI("http://#{option(:host)}:#{option(:port)}/stats?format=json")
    stats = JSON.parse(Net::HTTP.get(uri))
    topic = stats['data']['topics'].select { |t| t['topic_name'] == option(:topic) }.first
    raise 'Topic not found' unless topic
    channel = topic['channels'].select { |c| c['channel_name'] == option(:channel) }.first
    raise 'Channel not found' unless channel
    report(depth: channel['depth'], in_flight: channel['in_flight_count'])
  end
end
