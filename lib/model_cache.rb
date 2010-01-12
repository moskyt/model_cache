module ModelCache  
	
	DO_CACHE = Rails.configuration.action_controller.perform_caching
	NIL_OBJECT = Object.new
	DEFAULT_TIME = 12.hours
	
	def self.included(klass)
	  klass.extend ClassMethods
  end
	
	def cache(key, time = DEFAULT_TIME, &block)
	  ModelCache::cache([self.cache_key, key], time, &block)
  end
	
	def self.cache(ckey, time = DEFAULT_TIME, &block)
    if DO_CACHE && (result = CACHE.get(ckey))
      if result == NIL_OBJECT
        nil
      else
        result
      end
    else
      result = block.call
      if DO_CACHE
        if result
          CACHE.set(ckey, result, time)
        else
          CACHE.set(ckey, NIL_OBJECT, time)
        end
      end
      result
    end
  end
	
	
	module ClassMethods
  	def cache_method(*args)
  		args.each do |sym|
  		  cache_method_for_time(sym, DEFAULT_TIME)
  		end
  	end

  	def cache_method_for_time(sym, time)
  		alias_method :"__noncached_#{sym}", sym
  		define_method sym do |*args|
  			ckey = [self.cache_key, sym, *args]
  			ModelCache.cache(ckey, time) do
          self.send(:"__noncached_#{sym}", *args)
  			end
  		end    
  		define_method :"__is_cached_#{sym}?" do |*args|
  			ckey = [self.cache_key, sym, *args]
  			!!( DO_CACHE && CACHE.get(ckey) )
  		end
  		define_method :"__uncache_#{sym}" do |*args|
  			ckey = [self.cache_key, sym, *args]
  			CACHE.delete(ckey)
  		end
  	end
	end
	
end