class JavaHeapMonitor < Scout::Plugin

  OPTIONS=<<-EOS
    jmap_absolute_path:
      notes: "i.e. /usr/bin/jmap"
  EOS

  def build_report
    begin
      report {:heap => heap_size}
    rescue StandardError => trouble
      error "#{trouble} #{trouble.backtrace}"
    end
  end

  def heap_size
     o = `#{jmap_absolute_path} -histo:live \`ps -eaf | grep java | grep -v grep | awk '{print $2}'\` | grep Total | awk '{print $3}'`
     o.chomp.to_f / 1024 / 1024 # return mb 
   end
end
