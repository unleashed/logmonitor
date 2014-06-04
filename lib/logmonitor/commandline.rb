require 'optparse'
require 'pathname'

module LogMonitor
  module CommandLine

    def self.parse_options(*args)
      options = {
        logfile: STDIN,
        interval: 10,
        backlog: 120,
        threshold: 10
      }
      optparser = OptionParser.new("Usage: #{File.basename $0} [-l logfile] [-i interval] [-b backlog] [-t threshold]") do |opts|
        opts.version = '1.0'

        opts.accept Pathname do |pathname|
          pn = Pathname.new(pathname)
          raise ArgumentError, "cannot read #{pathname}" unless pn.readable?
          pn.open
        end

        opts.on '-l', '--logfile LOGFILE', Pathname, 'File containing log data to read from (default: stdin)' do |logfile|
          options[:logfile] = logfile
        end

        opts.on '-i', '--interval N', Integer, "Interval in seconds in which to display stats (default: #{options[:interval]})" do |interval|
          options[:interval] = interval
        end

        opts.on '-b', '--backlog N', Integer, "Produce traffic averages for this many trailing seconds (default: #{options[:backlog]})" do |backlog|
          options[:backlog] = backlog
        end

        opts.on '-t', '--threshold N', Float, "Set the average number of requests per second to produce a warning (default: #{options[:threshold]})" do |threshold|
          options[:threshold] = threshold
        end

        opts.on_tail '-h', '--help', 'Display this help screen' do
          puts opts
          exit 1
        end
      end
      optparser.parse!(*args)
      options
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      STDERR.puts "#{e}\n#{optparser}"
      exit 1
    end

  end # CommandLine
end # LogMonitor

