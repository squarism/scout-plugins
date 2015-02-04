class FileStat < Scout::Plugin
  # Reports attributes from Ruby's File.stat(path)
  OPTIONS=<<-EOS
    path:
      label: Path
      notes: The full path to the file
    alert_status_change:
      label: Alert on status change
      notes: Generate an alert if the file does not exist or when the "status" metric changes
      default: 'true'
      attributes: advanced
  EOS

  def build_report
    path = option(:path).to_s.strip
    if path.empty?
      return error("File path not configured.")
    end

    default_status = {
      'status'      => -1,  # The file's status, -2 EACCES, -1 ENOENT, 1 OK
      'ctime'       => -1,  # Change time for stat in UTC (the time directory information about the file was changed, not the file itself)
      'ctime_diff'  => -1,  # The ctime difference from now, in seconds
      'mtime'       => -1,  # Modification time in UTC (seconds since epoch)
      'mtime_diff'  => -1,  # The mtime difference from now, in seconds
      'atime'       => -1,  # Last access time for this file in UTC (seconds since epoch)
      'atime_diff'  => -1,  # The atime difference from now, in seconds
      'blksize'     => -1,  # Returns the native file system's block size. Will return nil on platforms that don't support this information.
      'blocks'      => -1,  # Returns the number of native file system blocks allocated for this file, or nil if the operating system doesn't support this feature.
      'dev'         => -1,  # Returns an integer representing the device on which stat resides.
      'ftype'       => -1,  # Identifies the type of stat. "unknown" -1, "file" 0 , "directory" 1, "characterSpecial" 2, "blockSpecial" 3, "fifo" 4, "link" 5, "socket" 6
      'gid'         => -1,  # Returns the numeric group id of the owner of stat.
      'ino'         => -1,  # Returns the inode number for stat.
      'mode'        => -1,  # Returns an integer representing the permission bits of stat. The meaning of the bits is platform dependent; on Unix systems, see stat(2).
      'nlink'       => -1,  # Returns the number of hard links to stat.
      'setgid'      => -1,  # Returns true if stat has the set-group-id permission bit set, false if it doesn't or if the operating system doesn't support this feature.
      'setuid'      => -1,  # Returns true if stat has the set-user-id permission bit set, false if it doesn't or if the operating system doesn't support this feature.
      'size'        => -1,  # Returns the size of stat in bytes.
      'sticky'      => -1,  # Returns true if stat has its sticky bit set, false if it doesn't or if the operating system doesn't support this feature.
      'uid'         => -1,  # Returns the numeric user id of the owner of stat.
    }.freeze

    status_codes = {'Errno::EACCES'    => -2,
                    'Errno::ENOENT'    => -1,
                    'OK'               =>  1 }
    status_codes.default = -1

    ftype_codes = {'unknown'          => -1,
                   'file'             =>  0,
                   'directory'        =>  1,
                   'characterSpecial' =>  2,
                   'blockSpecial'     =>  3,
                   'fifo'             =>  4,
                   'link'             =>  5,
                   'socket'           =>  6 }
    ftype_codes.default = -1

    previous_status = memory(:file_status)

    file_status = default_status.dup

    fstat = nil
    begin
      fstat = File.stat(path)
    rescue Errno::EACCES, Errno::ENOENT => e
      file_status['status'] = status_codes[e.class.to_s]
      if option(:alert_status_change) == 'true'
        alert("Cannot access file: #{e.message}")
      end
      return report(file_status)
    end

    file_status['status'] = status_codes['OK']
    if !previous_status.nil? and file_status['status'] != previous_status['status']
      alert(subject => "File status changed for #{path}", body => "Current Status: #{file_status['status']} - Previous Status: #{previous_status['status']}") if option(:alert_status_change) == 'true'
    end
    
    # stat methods that return DateTime objects
    %w(atime mtime ctime).each do |meth|
      if ret = fstat.send(meth.to_sym)
        file_status[meth] = ret.utc.to_i
        file_status["#{meth}_diff"] = Time.now.utc.to_i - file_status[meth] # Files with timestamps in the future will be negative.
      end
    end

    # stat methods that return nil, integers or fixnums
    %w(blksize blocks dev gid ino mode nlink size uid).each do |meth|
      if ret = fstat.send(meth.to_sym)
        # if not nil, set the ret value on file_status[meth]
        file_status[meth] = ret.to_i
      end
    end

    # stat methods that return true or false
    %w(setgid? setuid? sticky?).each do |meth|
      ret = fstat.send(meth.to_sym)
      file_status["#{meth.delete('?')}"] = ret ? 1 : 0 # 1 for true, 0 for false
    end

    # Convert the ftype string into integer code
    file_status['ftype'] = ftype_codes["#{fstat.ftype}"]

    remember :file_status => file_status
    return report(file_status)
  end
end
