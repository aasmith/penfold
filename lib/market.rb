require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'date'

class Market
  class Quote
    include ArgumentProcessor

    attr_accessor :symbol, :last, :bid, :ask

    def initialize(args = {})
      process_args(args)
    end

    def mid
      @mid ||= [bid, ask].reduce(:+) / 2.0
    end

    def inspect
      "<%s: L:%s B:%s A:%s>" % [
        symbol, last.to_money_s, bid.to_money_s, ask.to_money_s
      ]
    end
  end

  class << self
    def fetch(ticker, try_rt = true)
      url = "http://finance.yahoo.com/q?s=%s" % ticker
      print "Fetching #{url}..." if $VERBOSE

      doc = with_retry do
        Nokogiri::HTML.parse(open(url).read)
      end

      # Realtime last is at yfs_l90_sym, use if exists
      if try_rt
        last = (doc.at_css("#yfs_l90_#{ticker.downcase}").text.to_f * 100) rescue nil
      end

      last ||= (doc.at_css("#yfs_l10_#{ticker.downcase}").text.to_f * 100)
      bid  = (doc.at_css("#yfs_b00_#{ticker.downcase}").text.to_f * 100) rescue 0
      ask  = (doc.at_css("#yfs_a00_#{ticker.downcase}").text.to_f * 100) rescue 0

      quote = Quote.new(
        :symbol => ticker, :last => last, :bid => bid, :ask => ask)

      puts quote.inspect if $VERBOSE

      quote
    end

    # Handle weeklys; there will be other options expiring on the same month page
    # but with a different date - select expiry based on symbol
    def chain(ticker, expiry)
      url = "http://finance.yahoo.com/q/op?s=%s&m=%s" % [ticker, expiry.strftime("%Y-%m")]
      print "Fetching #{url}..." if $VERBOSE

      doc = with_retry do
        Nokogiri::HTML.parse(open(url).read)
      end

      itm_call_data = doc.
        search("//table[@class='yfnc_datamodoutline1'][1]//td[@class='yfnc_h']").
        map   { |e| e.text }

      #raise IOError, "Data is not in multiples of 8" unless itm_call_data.size % 8 == 0

      rows = itm_call_data.in_groups_of(8)
        #inject([[]]) { |a,e| (a.last.size == 8) ? (a << [e]) : (a.last << e);  a }

      rows.map do |row|
        strike = row[0].to_f * 100
        symbol = row[1]
        last   = row[2].to_f * 100
        bid    = row[4].to_f * 100
        ask    = row[5].to_f * 100

        raise "Expected symbol, got #{symbol.inspect}" unless symbol =~ /^\w+\d+[CP]\d+$/

        quote =  Quote.new(
          :symbol => symbol, :last => last, :bid => bid, :ask => ask)

        [strike, quote]
      end
    end

    def event?(ticker, on_or_before_date)
      url = "http://finance.yahoo.com/q/ce?s=%s" % ticker
      print "Fetching #{url}..." if $VERBOSE

      doc = with_retry do
        Nokogiri::HTML.parse(open(url).read)
      end

      return false if doc.text =~ /There is no Company Events data/

      fragment = doc.
        search("//table[@class='yfnc_datamodoutline1'][1]//td[@class='yfnc_tabledata1']")

      return false if fragment.text =~ /No Upcoming Events/i

      events = fragment.map{|e|e.text}.in_groups_of(3)

      events.any? do |date, event, _|
        event_date = Date.strptime date, "%d-%b-%y"

        event_date <= on_or_before_date
      end
    end

    def with_retry(&block)
      retries = 5

      begin
        block.call
      rescue
        retries -= 1
        unless retries.zero?
          puts "Got error, retrying"
          puts $!
          retry
        end
        raise
      end
    end
  end
end

