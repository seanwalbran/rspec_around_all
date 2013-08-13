require 'delegate'
require 'fiber'

module RSpecAroundAll
  class FiberAwareGroup < SimpleDelegator
    def run_examples
      Fiber.yield
    end

    def to_proc
      proc { run_examples }
    end

    def class
      __getobj__.class
    end
  end

  def around(scope = :each, &block)
    # let RSpec handle around(:each) hooks...
    return super(scope, &block) unless scope == :all || scope == :all_nested
    _around(scope, &block)
  end

  private

  FIBERS_STACK = []

  def _around(scope, &block)
    (handle_config_around scope, &block; return) if self.instance_of? ::RSpec::Core::Configuration
    return around_all false, &block if scope == :all
    around_all(false) do |group|
      group.children.each {|c| c.send :_around, :all_nested, &block }
      block[group]
    end
  end

  CONFIG_AROUND_ALL_NESTED_BLOCKS = []
  CONFIG_AROUND_ALL_PROCESSED_BY_GROUP = {}
  def handle_config_around(scope, store = true, prepend = false, &block)
    blocks = CONFIG_AROUND_ALL_NESTED_BLOCKS
    blocks << block if scope == :all_nested && store
    around_all(prepend) do |group|
      if scope == :all_nested && !CONFIG_AROUND_ALL_PROCESSED_BY_GROUP[group.name]
        CONFIG_AROUND_ALL_PROCESSED_BY_GROUP[group.name] = true
        blocks.reverse_each do |b|
          group.children.each{|c| c.send :handle_config_around, :all_nested, false, true, &b }
        end
      end
      block[group]
    end
  end

  def around_all(prepend, &block)
    methods = {
      before: method(prepend ? :prepend_before : :before),
      after:  method(prepend ? :prepend_after  : :after),
    }
    methods[:before].call :all do |group|
      fiber = Fiber.new(&block)
      FIBERS_STACK << fiber
      fiber.resume(FiberAwareGroup.new(group.class))
    end

    methods[:after].call :all do
      fiber = FIBERS_STACK.pop
      fiber.resume
    end
  end
end

RSpec.configure do |c|
  c.extend RSpecAroundAll

  # Add config.around(:all):
  # c.extend overrides the original Object#extend method.
  # See discussion in https://github.com/rspec/rspec-core/issues/1031#issuecomment-22264638
  Object.instance_method(:extend).bind(c).call RSpecAroundAll
  # Ruby 2 alternative:
  # RSpec::Core::Configuration.send :prepend, RSpecAroundAll
end

