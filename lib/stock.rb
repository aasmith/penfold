class Stock
  include ArgumentProcessor

  attr_accessor :symbol, :price

  def initialize(args = {})
    process_args(args)
    symbol.upcase! if symbol
  end

  def ==(other)
    symbol == other.symbol
  end
end

