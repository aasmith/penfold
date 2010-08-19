class Market
  class Quote
    include ArgumentProcessor

    attr_accessor :last, :bid, :ask

    def initialize(args = {})
      process_args(args)
    end

    def mid
      @mid ||= [bid, ask].reduce(:+) / 2.0
    end

    def inspect
      "<L:%s B:%s A:%s>" % [last.to_money_s, bid.to_money_s, ask.to_money_s]
    end
  end

  class << self
    def fetch(ticker)
      require 'rubygems'
      require 'nokogiri'
      require 'open-uri'

      url = "http://finance.yahoo.com/q?s=%s" % ticker
      print "Fetching #{url}..." if $VERBOSE

      doc = Nokogiri::HTML.parse(open(url).read)

      # Realtime last is at yfs_l90_sym, use if exists
      last = (doc.at_css("#yfs_l90_#{ticker.downcase}").text.to_f * 100) rescue nil
      last ||= (doc.at_css("#yfs_l10_#{ticker.downcase}").text.to_f * 100)
      bid  = (doc.at_css("#yfs_b00_#{ticker.downcase}").text.to_f * 100)
      ask  = (doc.at_css("#yfs_a00_#{ticker.downcase}").text.to_f * 100)

      quote = Quote.new(:last => last, :bid => bid, :ask => ask)

      puts quote.inspect if $VERBOSE

      quote
    end
  end
end

