module Sentinel
  def self.log(*args)
    puts *args if $VERBOSE
  end
  
  GuardianStages = [ :before, :on_failure, :after ]
    
  module InstanceMethods
    
    # Intercepts a method call using some proc that can validate a condition
    # and prevent the method from being called if it fails.
    #
    # @param [Symbol, Array<Symbol>] targets the methods to guard
    # @param [Hash] o the guarding options
    # @option o [Proc] :with (lambda { true }) the guarding method which would receive at least 2 arguments:
    #    1. [Object] the instance on which the guarded method is being invoked
    #    2. [Symbol] the method identifier
    #    3. [Array] the arguments the guarded method was called with
    # @option o [Symbol] :stage (:before) when to call the guardian method
    # @see Sentinel::GuardianStages
    #
    # @example
    #  class Monkey
    #    attr_accessor :hungry
    #
    #    def feed(food)
    #      food.eat
    #    end
    #     
    #    def hungry? @hungry end
    #     
    #    guard :feed_monkey do |monkey, _, food|
    #      monkey.hungry?
    #    end
    #  end
    #
    #  happy_monkey = Monkey.new
    #  happy_monkey.hungry = true
    #  happy_monkey.feed(banana) # => food.eat()
    #
    #  sad_monkey = Monkey.new
    #  sad_monkey.hungry = false
    #  sad_monkey.feed(banana) # => false
    #
    def guard(targets, o = {}, &block)
      targets = [ targets ] if !targets.is_a?(Array)
      
      o = {
        with: block || lambda { true },
        stage: :before
      }.merge(o)
      
      if o[:with].is_a?(Symbol)
        m = o[:with]
        unless instance_methods.include?(m)
          raise ArgumentError, "No such guardian method: #{name}##{m}"
        end

        o[:with] = instance_method(m)
      end
      
      @guard_map ||= {}
      
      targets.collect { |t| t.to_sym }.each { |t|

        unless instance_methods.include?(t)
          raise ArgumentError, "No such instance method #{t.class}##{t} to guard!"
        end
        
        add_guard(t, o)
        
        return if shadowed?(t)
        
        shadow = "__shadowed__#{t}".to_sym
        Sentinel.log "shadowing #{self.name}##{t}"
        
        alias_method :"#{shadow}", :"#{t}"
        
        define_method(t) do |*args|
          sentinel = self.class

          if sentinel.guards_for(t, :before).select { |g| !g.call(self, t, *args) }.any?
            sentinel.guards_for(t, :on_failure).each { |g| g.call(self, t, *args) }
            return false
          end
          
          r = send(shadow, *args)
          
          sentinel.guards_for(t, :after).each { |g| g.call(self, *args) }
          
          r
        end
      }
    end
    
    # @internal
    def guard_map
      @guard_map ||= {}
    end
    
    # @internal
    # @see #guard
    def add_guard(target, o)
      stage = o[:stage]
      
      unless GuardianStages.include?(stage)
        raise ArgumentError, 
          "Guard method stage must be either :before or :after, got #{stage}"
      end
      
      __init_guard_target(target)
      
      # prepare the method if necessary
      guard = o[:with]
      if guard.is_a?(UnboundMethod)
        unbound = o[:with]
        guard = lambda { |s, m, *args| unbound.bind(s).call(*args) }
      elsif !guard.respond_to?(:call)
        raise ArgumentError,
          "Guard must be a callable object (:call), got #{guard.class}" <<
          "#{guard.respond_to?(:name) ? '#' + guard.name : ''}"
      end
      
      Sentinel.log "Adding guard for #{target} -> #{guard.inspect}"
      @guard_map[target][stage] << guard
    end
    
    # @internal
    def guards_for(t, stage = :before)
      __init_guard_target(t)
      
      guards = @guard_map[t][stage]
      if superclass && superclass.respond_to?(:guards_for)
        guards += superclass.guards_for(t, stage)
        guards.flatten!
      end
      guards
    end
    
    # @internal
    def guarding?(target)
      @guard_map.has_key?(target.to_sym)
    end
    
    # @internal
    def shadowed?(t)
      instance_methods.include?(:"__shadowed__#{t}")
    end
    
    private
    
    def __init_guard_target(t)
      unless guard_map[t]
        guard_map[t] = { }
        GuardianStages.each { |s| guard_map[t][s] = [] }
      end      
    end
  end
  
  def self.included(base)
    base.extend(InstanceMethods)
  end
end
