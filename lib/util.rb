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
