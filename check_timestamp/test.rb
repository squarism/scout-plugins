require File.expand_path('../../test_helper.rb', __FILE__)
require File.expand_path('../check_timestamp.rb', __FILE__)

class CheckTimestampTest < Test::Unit::TestCase
  def test_difference
    current_time = Time.now
    file_time = current_time - 5.minutes
    Timecop.freeze(Time.now) do
      File.any_instance.stub(:mtime).returns(current_time)
      plugin = CheckTimestamp.new(nil, {}, @options.merge(path: 'check_timestamp/check_timestamp.rb'))
      res = plugin.run
      assert_equal @res[:difference], 5 * 60
    end
  end
end
