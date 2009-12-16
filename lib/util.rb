Symbol.class_eval do
  def camelize
    to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end

class FogMachine
  module Util
    extend self
    def sdb_items(domain, token = nil)
      query =  sdb.select("SELECT * from #{domain}", token)
      token = query[:next_token]
      items = query[:items]
      return items unless token
      items + sdb_items(domain, token)
    end

    def sdb
      FogMachine.sdb
    end

  end
end
