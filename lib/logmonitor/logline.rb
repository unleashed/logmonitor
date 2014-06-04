# LogLine applies a regexp to extract and store data from a raw log line

module LogMonitor
  class LogLine
    Format = /\A(?<hour>[0-2]\d):(?<minute>[0-5]\d):(?<second>[0-5]\d)\s(?<method>\S*)\s(?<path>\/\S*)\z/
    # the format given can only address up to one day, so that's our boundary for elapsed time checks
    Resolution = 86400

    # exceptions raised
    Error = Class.new(StandardError)
    FormatError = Class.new(Error)

    attr_reader :line, :time, :hour, :minute, :second, :method, :path

    def initialize(line)
      self.line = line
    end

    def line=(line)
      raise FormatError, "bad format" unless md = Format.match(line)
      @line = line
      @time = "#{md[:hour]}:#{md[:minute]}:#{md[:second]}"
      @hour = md[:hour].to_i
      @minute = md[:minute].to_i
      @second = md[:second].to_i
      @method = md[:method].upcase
      @path = md[:path]
    end

  end # LogLine
end # LogMonitor
