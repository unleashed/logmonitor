require 'logmonitor/logline'
require 'logmonitor/backlog'
require 'logmonitor/commandline'

module LogMonitor
  class App
    attr_accessor :logfile
    attr_reader :backlog, :timeout, :hits

    def initialize(*args)
      options = CommandLine.parse_options *args
      @logfile = options[:logfile]
      @timeout = @remaining = options[:interval]
      @backlog = Backlog.new options[:backlog], options[:threshold]
      @backlog.on_alert do |threshold, time|
        puts "* WARNING: Traffic limit over #{threshold}, alert triggered at #{Time.now} on log line timestamped at #{time}"
      end
      @backlog.on_normal do |threshold, time|
        puts "* WARNING: Traffic back to normal at #{Time.now} on log line timestamped at #{time}"
      end
      @hits = { :requests => 0, 'GET' => 0, 'POST' => 0 }
    end

    # The program uses a scheme that basically waits on streams (ie. pipes) and
    # busy-loops on files (with some sleeping done on purpose). This is due to
    # the need of a non-portable system API being needed to actually sleep on
    # events from other processes on files, such as inotify on Linux. If we were
    # writing Linux-specific code, using inotify would be much more efficient.
    def run
      starttime = Time.now
      data = ''
      readIOs = [logfile]
      readstride = stride_for logfile

      loop do
        begin
          # evaluate whether it is time to print some stats and update select's timeout
          self.remaining = compute_remaining_time(starttime) do |now|
            starttime = now
            print_stats
          end
          # data can contain the last chunk of a previous read that did not end on a line boundary
          data += logfile.read_nonblock(readstride)
        rescue EOFError
          # select will return immediately on EOF, so it is pointless to call it.
          # Here we could choose to sleep some time and check again or just
          # busy-loop either on read (as done above) or ie. on the file size via stat.
          # I've chosen to sleep min of 1 second or remaining time to release some
          # CPU time before looping again, since we don't much care about sub-second
          # accuracy on alerts.
          sleep [1, remaining].min
        rescue IO::WaitReadable
          # wait until something can be read or remaining time elapses
          IO.select(readIOs, nil, nil, remaining)
        else
          # got some data, process it, leave unprocessable data in a buffer
          data = log_lines(data)
        end
      end
    end

    private

    attr_accessor :remaining
    attr_writer :hits

    # add each complete log line to the backlog while removing newlines
    def log_lines(data)
      partialline = ''
      data.lines.each do |line|
        if line.end_with?("\n")
          add_line(line.chomp!)
        else
          # partial line read
          partialline = line
        end
      end
      partialline
    end

    # add a line to the backlog
    def add_line(line)
      logline = LogLine.new(line)
      backlog << logline
      self.hits[:requests] = hits[:requests] + 1
      self.hits[logline.method] = hits[logline.method] + 1 if logline.method == 'GET' or logline.method == 'POST'
      true
    rescue LogLine::Error => e
      STDERR.puts "*** Ignoring line - #{e}: #{line}"
      false
    end

    # print global traffic stats
    def print_stats
      header = "Total traffic stats / Last #{backlog.expiry} seconds"
      puts "#{header}\n" \
           "#{'=' * header.length}\n" \
           "GET requests: #{hits['GET']} / #{backlog.stats['GET']}\n" \
           "POST requests: #{hits['POST']} / #{backlog.stats['POST']}\n" \
           "Total requests: #{hits[:requests]} / #{backlog.stats[:requests]}\n\n"
    end

    # provide a sensible value for read system calls
    def stride_for(file)
      # Here we could determine the file system block size and use that
      # for the stride size, or we could take the system's page size since
      # it is a good heuristic for optimum performance - both pose some
      # portability issues, so I'll just leave it as an extra exercise and
      # hardcode a good enough value of 4K
      4096
    end

    # Since unfortunately Ruby does not expose a modifying timeout parameter
    # for select(2), we can hack our way around with a helper method to
    # compute the remaining time until a predefined timeout.
    # A more complex approach would include using timeouts or signal handlers
    # for little gains.
    # Returns the remaining time.
    def compute_remaining_time(starttime)
      now = Time.now
      diff = now - starttime
      if diff >= @timeout
        # on timeout, call an optional block to perform
        # whatever actions are needed
        yield now if block_given?
        @timeout
      else
        @timeout - diff
      end
    end

  end # App
end # LogMonitor
