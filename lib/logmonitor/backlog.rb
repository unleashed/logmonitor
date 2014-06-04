# Data structure to hold the last N log lines comprising a maximum time interval,
# implemented as an array that drops old entries when adding new ones.
require 'logmonitor/logline'

module LogMonitor
  class Backlog
    attr_reader :expiry, :threshold, :stats, :alert, :lines
    alias_method :alert?, :alert

    def initialize(expiry, threshold)
      @expiry, @threshold = expiry, threshold
      @stats = Hash.new { |h, k| h[k] = 0 }
      @lines = []
      @alert = false
      @offset = 0
      @on_alert_blk = lambda {}
      @on_normal_blk = lambda {}
    end

    # add a new log line entry
    def <<(logline)
      compute_timestamp(logline).tap do |ts|
        # First reduce the array size if possible, then add the new
        # entry and perform threshold checks.
        trim ts
        push_line ts, logline
        check_threshold
      end
    end

    def on_alert(&block)
      @on_alert_blk = block
    end

    def on_normal(&block)
      @on_normal_blk = block
    end

    private

    attr_accessor :offset
    attr_writer :alert

    # Since we don't have unique timestamps in the log format, we use a simple
    # method to produce a continuous function from timestamps for the backlog
    def compute_timestamp(logline)
      timestamp = logline.hour * 3600 + logline.minute * 60 + logline.second
      # assume we just advanced to the next day in case we got a lower timestamp than last one
      timestamp += LogLine::Resolution * offset
      if timestamp < last_timestamp
        self.offset = offset + 1
        timestamp += LogLine::Resolution
      end
      timestamp
    end

    # get the latest log line entry timestamp
    def last_timestamp
      lines.last.first
    rescue
      0
    end

    # add a line, update stats
    def push_line(timestamp, logline)
      lines << [timestamp, logline]
      stats[logline.method] += 1
      stats[:requests] += 1
    end

    # delete lines older than expiry seconds, update stats
    def trim(timestamp)
      dropped = lines.take_while do |ts, _|
        timestamp - ts > expiry
      end
      dropped.length.tap do |numdropped|
        # actually drop the lines
        lines.slice!(0, numdropped)
        # keep running statistics of methods
        dropped.each do |_, logline|
          stats[logline.method] -= 1
        end
        stats[:requests] -= numdropped
      end
    end

    # check whether we've crossed the specified threshold
    def check_threshold
      rate = lines.length.to_f / expiry
      if rate > threshold
        alert_status
      elsif rate < threshold
        normal_status
      end
    end

    def alert_status
      unless alert?
        @on_alert_blk.call(threshold, lines.last.last.time)
        self.alert = true
      end
    end

    def normal_status
      if alert?
        @on_normal_blk.call(threshold, lines.last.last.time)
        self.alert = false
      end
    end

  end # Backlog
end # LogMonitor
