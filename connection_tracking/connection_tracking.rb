class ConnectionTracking < Scout::Plugin
  def build_report
    conntrack_max_output = `cat /proc/sys/net/netfilter/nf_conntrack_max`
    max = conntrack_max_output.split("\n")[0].to_i

    conntrack_count_output = `cat /proc/sys/net/netfilter/nf_conntrack_count`
    count = conntrack_count_output.split("\n")[0].to_i

    percent = (count.to_f / max.to_f) * 100

    report(:conntrack_count => count, :conntrack_max => max, :conntrack_percent_used => percent)
  end
end

