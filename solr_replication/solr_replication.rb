class SolrReplication < Scout::Plugin
  needs 'open-uri'
  needs 'rexml/document'

  OPTIONS=<<-EOS
  master:
    default: http://192.168.0.1:8983
  slave:
    default: http://localhost:8765
  replication_path:
    default: /solr/admin/replication/index.jsp
    notes: The path to the replication index page in the Solr Admin web interface
  EOS

  def build_report
    master_position = position_for(master_host)
    slave_position = position_for(slave_host)
    return if errors.any?
    report 'delay' => master_position.to_i - slave_position.to_i if master_position and slave_position
  end

  private

  def position_for(host)
    open(host) do |c|
      content = c.read
      if content =~ /^s*<[^Hh>]*html/
        generation_regex = /Generation: (\d+)/
        content.match(generation_regex)[1]
      else
        doc = REXML::Document.new(content)
        node = REXML::XPath.first(doc, "/response/lst/lst/long[@name='replicatableGeneration']")
        node && node.text
      end
    end
  rescue => e
    error "Error connecting to #{host}","Unable to connect to Solr Admin interface at: #{host}. Error:\n#{e.message}\n\nEnsure the plugin options are configured correctly."
  end

  def master_host
    "#{option(:master)}#{option("replication_path")}"
  end

  def slave_host
    "#{option(:slave)}#{option("replication_path")}"
  end
end
