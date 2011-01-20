require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'cgi'

class Market
  HEADERS = {
    "Accept" => "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
    "Accept-Charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
    "Accept-Language" => "en-US,en;q=0.8",
    "Cache-Control" => "max-age=0",
    "Connection" => "keep-alive",
    "Host" => "finance.yahoo.com",
    "Referer" => "http://finance.yahoo.com/",
    "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.215 Safari/534.10"
  }

  class Quote
    include ArgumentProcessor

    attr_accessor :symbol, :last, :bid, :ask, :extra

    def initialize(args = {})
      process_args(args)
      self.extra = {}
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
    def fetch(ticker, opts = {})
      url = "http://finance.yahoo.com/q?s=%s" % ticker
      puts "Fetching #{url}..." if $VERBOSE

      doc = with_retry do
        Nokogiri::HTML.parse(open(url, HEADERS).read)
      end

      # Realtime last is at yfs_l90_sym, use if exists
      if opts[:try_rt]
        last = (doc.at_css("#yfs_l90_#{ticker.downcase}").text.to_f * 100) rescue nil
      end

      last ||= (doc.at_css("#yfs_l10_#{ticker.downcase}").text.to_f * 100)
      bid  = (doc.at_css("#yfs_b00_#{ticker.downcase}").text.to_f * 100) rescue 0
      ask  = (doc.at_css("#yfs_a00_#{ticker.downcase}").text.to_f * 100) rescue 0

      quote = Quote.new(
        :symbol => ticker, :last => last, :bid => bid, :ask => ask)

      if opts[:extra]
        name   = doc.at('h1').text.scan(/(.*) \([\w-]+\)$/).to_s # strip trailing (SYMBOL)
        mktcap = doc.at_css("#yfs_j10_#{ticker.downcase}").text rescue nil

        divyield = doc.at("#table2 .end td").text.scan(/\((.*)\)/).to_s.to_f rescue nil

        begin
          pe_row = doc.at("#table2 tr:nth-child(6)")
          pe_label, pe_data = pe_row.search("th,td").map{|e|e.text}

          unless pe_label =~ %r(P/E)
            puts "P/E label mismatch" 
            pe_data = nil
          end
        rescue
          # nothing
        end

        sector, industry = doc.search("#company_details a").map{|e|e.text} rescue nil

        quote.extra = {
          :name => name,
          :mktcap => mktcap,
          :divyield => divyield,
          :pe => pe_data.to_f,
          :sector => sector,
          :industry => industry
        }
      end

      puts quote.inspect if $VERBOSE

      quote
    end

    require 'json'
    def gchain(ticker, expiry)
      url = "http://www.google.com/finance/option_chain?q=%s&expd=%s&expm=%s&expy=%s&output=json"
      url = url % [ticker.gsub(/-/, "."), expiry.day, expiry.month, expiry.year]

      puts "Fetching #{url}..." if $VERBOSE
      doc = with_retry do
        JSON.parse(
          open(url).read.
            gsub(/(\:"\w+):/, '\1').                # Remove extra colon that appears inside strings
            gsub('\\', "").                         # Remove slashes
            gsub(/(['"])?(\w+)(['"])?:/m, '"\2":'), # Quote each key
          :symbolize_names => true)
      end

      doc[:calls].map do |call|
        quote =  Quote.new(
          :symbol => call[:s],
          :last   => call[:p].to_f * 100,
          :bid    => call[:b].to_f * 100,
          :ask    => call[:a].to_f * 100
        )

        unless quote.symbol =~ /^\w+\d+[CP]\d+$/
          puts "Dropping bad option #{quote.symbol.inspect}"
          next
        end

        unless quote.bid > 0 and quote.ask > 0
          puts "Option #{quote.symbol.inspect} has no bid or ask"
          next
        end
        
        [call[:strike].to_f * 100, quote]
      end.compact
    end

    def chain(ticker, expiry)
      url = "http://finance.yahoo.com/q/op?s=%s&m=%s" % [ticker, expiry.strftime("%Y-%m")]
      puts "Fetching #{url}..." if $VERBOSE

      doc = with_retry do
        Nokogiri::HTML.parse(open(url, HEADERS).read)
      end

      itm_call_data = doc.
        search("//table[@class='yfnc_datamodoutline1'][1]//td[@class='yfnc_h']").
        map   { |e| e.text }

      rows = itm_call_data.in_groups_of(8)

      rows.map do |row|
        strike = row[0].to_f * 100
        symbol = row[1]
        last   = row[2].to_f * 100
        bid    = row[4].to_f * 100
        ask    = row[5].to_f * 100

        raise "Expected symbol, got #{symbol.inspect}" unless symbol =~ /^\w+\d+[CP]\d+$/

        # Only pick symbols that have the correct expiry
        # Occurs when multiple series appear for the same month (i.e. weeklys)
        next unless symbol =~ /#{expiry.strftime("%y%m%d")}/

        quote =  Quote.new(
          :symbol => symbol, :last => last, :bid => bid, :ask => ask)

        [strike, quote]
      end.compact
    end

    def event?(ticker, on_or_before_date)
      url = "http://finance.yahoo.com/q/ce?s=%s" % ticker
      puts "Fetching #{url}..." if $VERBOSE

      doc = with_retry do
        Nokogiri::HTML.parse(open(url, HEADERS).read)
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

    def historical_prices(ticker, from = Date.today - 365)
      to = Date.today

      url = "http://ichart.finance.yahoo.com/table.csv?s=%s&a=%s&b=%s&c=%s&d=%se=%s&f=%sg=d&ignore=.csv"
      url = url % [ticker, from.month - 1, from.day, from.year, to.month - 1, to.year, to.day]

      puts "Fetching #{url}..." if $VERBOSE

      csv = with_retry do
        open(url, HEADERS).read
      end

      # [newest, ..., oldest]
      csv.scan(/\d+\.\d+$/).map { |p| p.to_f }
    end

    def constituents(ticker, offset = 0, traverse = true)
      ticker = "^#{ticker}" unless ticker =~ /^\^/

      url = "http://finance.yahoo.com/q/cp?s=%s&c=%s" % [CGI.escape(ticker), offset]
      puts "Fetching #{url}..." if $VERBOSE

      doc = with_retry do
        Nokogiri::HTML.parse(open(url, HEADERS).read)
      end

      symbols = doc.at("#yfncsumtab").search("tr td:first-child.yfnc_tabledata1").map{ |td| td.text }
      next_link = doc.at("#yfncsumtab").at("//a[text()='Next']")

      if next_link && traverse
        return symbols + constituents(ticker, offset + 1)
      end

      return symbols
    end

    INDEXES = {}

    def member_of?(ticker, index_ticker)
      index_members = INDEXES[index_ticker] ||= constituents(index_ticker)

      index_members.include?(ticker)
    end

    def with_retry(&block)
      retries = 20

      begin
        timeout(5) do
          block.call
        end
      rescue Exception
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

