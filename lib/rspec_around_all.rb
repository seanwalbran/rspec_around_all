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
  end

  def around(scope = :each, &block)
    # let RSpec handle around(:each) hooks...
    return super(scope, &block) unless scope == :all

    group, fiber = self, nil
    before(:all) do
      fiber = Fiber.new(&block)
      fiber.resume(FiberAwareGroup.new(group))
    end

    after(:all) do
      fiber.resume
    end
  end
end

RSpec.configure do |c|
  c.extend RSpecAroundAll
end

