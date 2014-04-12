class GearmanBacklog < Scout::Plugin
  needs 'net/telnet'
  OPTIONS=<<-EOS
    host:
      name: Host
      default: localhost
      notes: Hostname or IP address of the Gearman job server
    port:
      name Port
      default: 4730
  EOS
  def build_report
    telnet = Net::Telnet::new("Host" => option(:host), "Port" => option(:port))
    status = telnet.cmd("String" => "status", "Match" => /\n./)
    status.split("\n")[0...-1].map do |job|
      task, jobs, running, workers = job.split("\t")
      report(task => jobs)
    end
  end
end
