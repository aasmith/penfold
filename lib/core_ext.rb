require 'date'

class Date
  undef inspect
  def inspect
    "#<Date: #{strftime("%c")}>"
  end
end

class String
  def commify
    reverse.gsub(/(\d\d\d)(?=\d)(?!\d*\.)/, '\1,').reverse
  end
end

class Numeric
  def to_money_s
    ("$%g" % (self / 100.0)).commify.sub(/\.(\d)\Z/, '.\10')
  end

  def to_percent_s(p = nil)
    (p ? "%.#{p}f%%" : "%g%%") % (self * 100)
  end
end

class Array
  def in_groups_of(n)
    raise ArgumentError, "Data is not in multiples of #{n}" unless size % n == 0
    
    inject([[]]) { |a,e| (a.last.size == n) ? (a << [e]) : (a.last << e);  a }
  end
end
