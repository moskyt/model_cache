module ModelCache  
	
	DEFAULT_TIME = 12.hours unless const_defined?(:DEFAULT_TIME)
	NIL_OBJECT = :__i_have_no_idea_how_to_do_this_without_an_ugly_symbol unless const_defined?(:NIL_OBJECT)
	
	def self.included(klass)
	  klass.extend ClassMethods
  end
	
	def cache(key, time = DEFAULT_TIME, &block)
	  ModelCache::cache([self.cache_key, key], time, &block)
  end
	
	def self.cache(ckey, time = DEFAULT_TIME, &block)
	  cache_hit = false
    if Rails.configuration.action_controller.perform_caching 
      result = CACHE.get(ckey) rescue nil
      if result
        cache_hit = true
      end
      if result == NIL_OBJECT
        nil
      else
        result
      end
    end
    unless cache_hit
      result = block.call
      if Rails.configuration.action_controller.perform_caching
        begin
          if result
            CACHE.set(ckey, result, time)
          else
            CACHE.set(ckey, NIL_OBJECT, time)
          end
        end rescue nil
      end
      result
    end
    result
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
  			!!( Rails.configuration.action_controller.perform_caching && CACHE.get(ckey) )
  		end
  		define_method :"__uncache_#{sym}" do |*args|
  			ckey = [self.cache_key, sym, *args]
  			CACHE.delete(ckey)
  		end
  	end
	end
	
end