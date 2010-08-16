#  JavaScript adopted from Bernt Arne Odegaard's Financial Numerical Recipes
#  http://finance.bi.no/~bernt/gcc_prog/algoritms/algoritms/algoritms.html
#  by Steve Derezinski, CXWeb, Inc.  http://www.cxweb.com
#  Copyright (C) 1998  Steve Derezinski, Bernt Arne Odegaard
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  http://www.fsf.org/copyleft/gpl.html
 
class BlackScholes
  class << self
    def ndist(z)
      (1.0/(Math.sqrt(2*Math::PI)))*Math.exp(-0.5*z)
    end

    def n(z)
      b1 =  0.31938153
      b2 = -0.356563782
      b3 =  1.781477937
      b4 = -1.821255978
      b5 =  1.330274429
      p  =  0.2316419
      c2 =  0.3989423

      a = z.abs

      return 1.0 if a > 6.0

      t = 1.0/(1.0+a*p)
      b = c2*Math.exp((-z)*(z/2.0))
      n = ((((b5*t+b4)*t+b3)*t+b2)*t+b1)*t
      n = 1.0-b*n

      n = 1.0 - n if z < 0.0

      n
    end

    def black_scholes(call,s,x,r,v,t)
      # call = Boolean (to calc call, call=True, put: call=false)
      # s = stock prics, x = strike price, r = no-risk interest rate
      # v = volitility (1 std dev of s for (1 yr? 1 month?, you pick)
      # t = time to maturity

      sqt = Math.sqrt(t)

      d1 = (Math.log(s/x) + r*t)/(v*sqt) + 0.5*(v*sqt)
      d2 = d1 - (v*sqt)

      if call
        delta = n(d1)
        nd2 = n(d2)
      else # put
        delta = -n(-d1)
        nd2 = -n(-d2)
      end

      ert = Math.exp(-r*t)
      nd1 = ndist(d1)

      gamma = nd1/(s*v*sqt)
      vega = s*sqt*nd1
      theta = -(s*v*nd1)/(2*sqt) - r*x*ert*nd2
      rho = x*t*ert*nd2

      s*delta-x*ert*nd2
    end 

    def option_implied_volatility(call,s,x,r,t,o)
      # call = Boolean (to calc call, call=True, put: call=false)
      # s = stock prics, x = strike price, r = no-risk interest rate
      # t = time to maturity
      # o = option price

      sqt = Math.sqrt(t)
      accuracy = 0.0001

      sigma = (o/s)/(0.398*sqt)

      100.times do
        price = black_scholes(call,s,x,r,sigma,t)
        diff = o-price

        return sigma if diff.abs < accuracy

        d1 = (Math.log(s/x) + r*t)/(sigma*sqt) + 0.5*sigma*sqt
        vega = s*sqt*ndist(d1)
        sigma = sigma+diff/vega
      end

      raise "Failed to converge"
    end

    def call_iv(s,x,r,t,o)
      option_implied_volatility(true,s,x,r/100.0,t/365.0,o)
    end
  end
end

