require 'minitest'
require 'rubygems'
require 'mocha/test_unit'     # gem install mocha
require 'fakeweb'   # gem install fakeweb
require 'timecop'   # gem install timecop
require 'scout'
begin
  require 'pry'
rescue LoadError
  # not using pry
end

class MiniTest::Test
  # Reads the code and extracts default options. The argument should be the name of
  #  both the plugin directory and the file. This assumes the directory and filename are the same.
  def parse_defaults(name)
    code=File.read("#{File.dirname(__FILE__)}/#{name}/#{name}.rb")
    @options={}
    raw_options=Scout::PluginOptions.from_yaml(Scout::Plugin.extract_options_yaml_from_code(code))
    raw_options.select{|r|r.has_default?}.each{|o|@options[o.name]=o.default}
    return @options
  end
end
