class Commission
  include ArgumentProcessor
  
  attr_accessor :shares, :contracts

  def initialize(args = {})
    if instance_of? Commission
      raise ArgumentError, "Commission cannot be instantiated"
    end

    process_args(args)

    @shares ||= 0
    @contracts ||= 0
  end
end

class Commission::Free < Commission
  def option_entry;      0 end
  def stock_entry;       0 end
  def option_assignment; 0 end
end

class Commission::OptionsHouse < Commission
  def option_entry
    contracts.zero? ? 0 : 8_50 + (contracts * 15)
  end

  def stock_entry
    shares.zero? ? 0 : 2_95
  end

  def option_assignment
    contracts.zero? ? 0 : 5_00
  end
end

class Commission::OptionsHouseAlt < Commission::OptionsHouse
  def option_entry
    return 0 if contracts.zero?

    contracts <= 5 ? 5_00 : contracts * 1_00
  end
end
