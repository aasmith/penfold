class Option
  include ArgumentProcessor

  attr_accessor :stock, :strike, :expires, :price, :current_date

  def initialize(args = {})
    raise ArgumentError, "An option cannot be instantiated" if instance_of? Option

    @current_date = nil

    process_args(args)
  end

  def days_to_expiry
    [0, (expires - current_date).to_i].max
  end

  def expired?
    expires < current_date
  end

  undef current_date
  def current_date
    @current_date || Date.today
  end

  def call?
    false
  end

  def put?
    false
  end

  def in_the_money?
    raise NotImplementedError
  end

  def out_the_money?
    !in_the_money?
  end

  # A specific sub state of being out the money.
  def at_the_money?
    stock.price == strike
  end

  def to_s
    [stock.symbol, float_if_needed(strike), 
      expires.strftime("%b %y").upcase, self.class.name.upcase].join(" ")
  end

  def to_ticker_s
    call_or_put = call? ? "C" : "P"

    dollar  = (strike.to_i / 100).to_s.rjust(5, "0")
    decimal = (strike.to_i % 100).to_s.ljust(3, "0")

    [stock.symbol, expires.strftime("%y%m%d"), call_or_put, dollar, decimal].join.upcase
  end

  def ==(other)
    other.stock == stock &&
      other.strike == strike &&
      other.expires == expires
  end

  private
  
  def float_if_needed(num)
    num / 100.0 == num / 100 ? num / 100 : num / 100.0
  end
end

class Call < Option
  def call?
    true
  end

  def in_the_money?
    stock.price > strike
  end
end

class Put < Option
  def put?
    true
  end

  def in_the_money?
    stock.price < strike
  end
end

