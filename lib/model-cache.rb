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
    if CACHE.class.name == 'Memcached'
      begin
        result = CACHE.get(ckey.hash.to_s)
        cache_hit = true
      rescue Memcached::NotFound => e
      end
    elsif CACHE.class.name == 'MemCache' or CACHE.class.name == 'Dalli::Client'
      result = CACHE.get(ckey.hash.to_s)
      if result
        cache_hit = true
      end
      if result == NIL_OBJECT
        result = nil
      end
    else
      raise "CACHE object not configured #{CACHE.inspect}!"
    end
    unless cache_hit
      result = block.call
      if CACHE.class.name == 'MemCache'
        if result
          CACHE.set(ckey.hash.to_s, result, time)
        else
          CACHE.set(ckey.hash.to_s, NIL_OBJECT, time)
        end
      elsif CACHE.class.name == 'Memcached'
        CACHE.set(ckey.hash.to_s, result, time)
      else
        raise "CACHE object not configured #{CACHE.inspect}!"
      end
      result
    end
    result
  end
	
	
	module ClassMethods
  	def cache_method(*args)
  	  opts = args.extract_options!
  		args.each do |sym|
  		  cache_method_for_time(sym, (opts[:time] || DEFAULT_TIME))
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
        if CACHE.class.name == 'Memcached'
          begin
            result = CACHE.get(ckey.hash.to_s)
            cache_hit = true
          rescue Memcached::NotFound => e
          end
        elsif CACHE.class.name == 'MemCache'
          result = CACHE.get(ckey.hash.to_s)
          if result
            cache_hit = true
          end
          if result == NIL_OBJECT
            result = nil
          end
        else
          raise "CACHE object not configured #{CACHE.inspect}!"
        end
        cache_hit
  		end
  		define_method :"__flush_#{sym}" do |*args|
  			ckey = [self.cache_key, sym, *args]
  			CACHE.delete(ckey)
  		end
  	end
	end
	
end

# include the library
ActiveRecord::Base.send(:include, ModelCache)
