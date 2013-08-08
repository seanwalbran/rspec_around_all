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
    return around_all &block if scope == :all
    # let RSpec handle around(:each) hooks...
    return super(scope, &block) unless scope == :all_nested
    around_all do |group|
      group.children.each {|c| c.around(:all_nested, &block) }
      block[group]
    end
  end

  private

  FIBERS_STACK = []

  def around_all(&block)
    prepend_before(:all) do |group|
      fiber = Fiber.new(&block)
      FIBERS_STACK << fiber
      fiber.resume(FiberAwareGroup.new(group.class))
    end

    prepend_after(:all) do
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

