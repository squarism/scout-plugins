class JavaHeapMonitor < Scout::Plugin

  OPTIONS=<<-EOS
    jmap_absolute_path:
      default: /data/dist/jdk1.6.0_37/bin/jmap
      notes: "i.e. /usr/bin/jmap"
  EOS

  def build_report
    begin
      report(:heap => heap_size)
    rescue StandardError => trouble
      error "#{trouble} #{trouble.backtrace}"
    end
  end

  def heap_size
     pid = `ps -eaf | grep java | grep -v grep | grep -v java_heap | awk '{print $2}'`
     #`#{option(:jmap_absolute_path)} -histo:live #{pid} > /tmp/heap.out` 
     `#{option(:jmap_absolute_path)} -heap #{pid} > /tmp/heap.out` 
     #`echo hi > /tmp/heap.out`
     #return o.chomp.to_f / 1024 / 1024 # return mb 
     o
   end
end
