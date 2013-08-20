require File.expand_path('../../test_helper.rb', __FILE__)
require File.expand_path('../solr_replication.rb', __FILE__)

require 'open-uri'
class SolrReplicationTest < Test::Unit::TestCase

  def teardown
    FakeWeb.clean_registry
  end

  def test_should_report
    master='http://192.168.0.1:8983'
    slave='http://localhost:8765'
    rep_path='/solr/admin/replication/index.html'
    FakeWeb.register_uri(:get, master+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_master.html'))
    FakeWeb.register_uri(:get, slave+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_slave.html'))
    
    @plugin=SolrReplication.new(nil,{},{:master => master, :slave => slave, :replication_path => rep_path})
    res = @plugin.run()
    assert res[:errors].empty?
    assert_equal 3, res[:reports].first["delay"]
  end

  def test_should_report_with_xml
    master='http://192.168.0.1:8983'
    slave='http://localhost:8765'
    rep_path='/solr/replication?command=details'
    FakeWeb.register_uri(:get, master+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_master.xml'))
    FakeWeb.register_uri(:get, slave+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_slave.xml'))
    
    @plugin=SolrReplication.new(nil,{},{:master => master, :slave => slave, :replication_path => rep_path})
    res = @plugin.run()
    assert res[:errors].empty?
    assert_equal 3, res[:reports].first["delay"]
  end
  
  def test_should_error_with_invalid_master
    slave='http://localhost:8765'
    rep_path='/solr/admin/replication/index.html'
    FakeWeb.register_uri(:get, slave+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_slave.html'))
    @plugin=SolrReplication.new(nil,{},{:master => 'http://fake', :slave => slave, :replication_path => rep_path})
    res = @plugin.run()
    assert_equal 1, res[:errors].size
    assert_equal "Error connecting to http://fake/solr/admin/replication/index.html", res[:errors].first[:subject]
  end

  def test_errors_if_html_field_does_not_exist
    slave='http://localhost:8765'
    rep_path='/solr/admin/replication/index.html'
    FakeWeb.register_uri(:get, slave+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_missing_data.html'))
    @plugin=SolrReplication.new(nil,{},{:master => 'http://fake', :slave => slave, :replication_path => rep_path})
    res = @plugin.run()
    assert_equal 2, res[:errors].size
    assert_equal "Error connecting to http://fake/solr/admin/replication/index.html", res[:errors].first[:subject]
  end

  def test_does_not_report_if_xml_field_does_not_exist
    master='http://192.168.0.1:8983'
    slave='http://localhost:8765'
    rep_path='/solr/replication?command=details'
    FakeWeb.register_uri(:get, master+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_missing_data.xml'))
    FakeWeb.register_uri(:get, slave+rep_path, :body => File.read(File.dirname(__FILE__)+'/fixtures/sample_slave.xml'))
    
    @plugin=SolrReplication.new(nil,{},{:master => master, :slave => slave, :replication_path => rep_path})
    res = @plugin.run()
    assert_empty res[:errors]
    assert_empty res[:reports]
  end
end
