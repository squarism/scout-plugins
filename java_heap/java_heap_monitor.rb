class JavaHeapMonitor < Scout::Plugin

  OPTIONS=<<-EOS
    jmap_absolute_path:
      notes: "i.e. /usr/bin/jmap"
  EOS

  def build_report
    begin      
      pid = grep_java_process
      if pid.lines.count > 1
        error("too many processes", "more than one process was found grepping for java.") 
      elsif pid.lines.count < 1
        error("no java process", "no process was found grepping for java") 
      elsif !File.exist?(jmap) 
        error("jmap missing", "jmap executable #{jmap} not found")         
      elsif !File.executable?(jmap) 
        error("jmap not executable", "jmap #{jmap} not executable")         
      else
        histo_output = jmap_histo(pid)
        if histo_output.index('Total') == nil
          error("unexpected jmap output from #{jmap} -histo:live #{pid}", "This plugin expects the output of jmap from jdk 1.6.0_37 (and hopefully most others as well)  The \'jmap -histo:live\' includes the total heap used in the last line which starts with the string \'Total\'")         
        else
          totals = parse_jmap_total(histo_output)
          if totals.size != 2
            error("unexpected jmap output from #{jmap} -histo:live #{pid}", "This plugin expects the output of jmap from jdk 1.6.0_37 (and hopefully most others as well)  The \'jmap -histo:live\' includes a summary count of instances and heap used.\'\nInstead of two integers, found this: \'#{totals}\' ")         
          else
            heap_size = totals[1].chomp
            if !a_stringified_integer?(heap_size)
              error("expected integer. unexpected jmap output from #{jmap} -histo:live #{pid}", "This plugin expects the output of jmap from jdk 1.6.0_37 (and hopefully most others as well)  The \'jmap -histo:live\' includes the total, which should look like \'Total       5081856      493072400\'\nInstead, we parsed as the the total heap used is not an integer: \'#{heap_size}\' ")         
            else
             report(:heap => btye_to_mb(heap_size.to_i)) # return mb
            end
        end
      end
    end
    rescue StandardError => trouble
      error "#{trouble} #{trouble.backtrace}"
    end
  end
 
  def grep_java_process
    # pid of java process. assumes only 1 java process
    `ps -eaf | grep java | grep -v grep | grep -v java_heap | awk '{print $2}'`
  end

  def jmap_histo(pid)
    # histo output of jmap, which loses all the newlines.  not sure why
    histo = `#{jmap} -histo:live #{pid} `
  end
  
  def all_indexes_of(s, pattern)
  end

  def parse_jmap_total(histo)
     # parse out last line with total instance count and heap size in bytes
      pattern = 'Total'
      # parse out the last line, which should be  Total <count of instances>  <byes of heap used>
      totals_string = histo.split(pattern)[histo.split(pattern).size - 1]
      totals_string.split(' ')
  end

  def parse_heap_size(totals)
    # only return the heap size
    size = totals[1]
    return size.chomp.to_f / 1024 / 1024 # return mb
  end

  def a_stringified_integer?(i)
    Integer(i)
    return true
  rescue ArgumentError
    return false
  end
  
  def btye_to_mb(i)
    i.to_f / 1024 / 1024
  end

   def jmap
#     option(:jmap_absolute_path) || '/usr/bin/jmap'
     option(:jmap_absolute_path) || '/tmp/jmap'
   end

end
