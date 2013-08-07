require_relative '../lib/rspec_around_all'

module RSpec
  module Core
    describe "around(:all) hook" do
      it "runs the hook around all examples" do
        order = []

        group = ExampleGroup.describe "group" do
          around(:all) do |g|
            order << :before
            g.run_examples
            order << :after
          end
          specify { order << :e1 }
          specify { order << :e2 }
        end

        group.run(double.as_null_object)
        order.should eq([:before, :e1, :e2, :after])
      end

      it 'allows the yielded arg to be treated as a proc' do
        group = ExampleGroup.describe "group" do
          def self.order
            @order ||= []
          end

          def self.transactionally
            order << :before
            yield
            order << :after
          end

          around(:all) { |g| transactionally(&g) }
          specify { self.class.order << :e1 }
          specify { self.class.order << :e2 }
        end

        group.run(double.as_null_object)
        group.order.should eq([:before, :e1, :e2, :after])
      end

      it 'can access metadata in the hook' do
        foo_value = nil
        group = ExampleGroup.describe "group", :foo => :bar do
          around(:all) do |group|
            foo_value = group.metadata[:foo]
            group.run_examples
          end
          specify { }
        end

        group.run(double.as_null_object)
        foo_value.should eq(:bar)
      end

      it 'allows around(:each) hooks to run as normal' do
        order = []

        group = ExampleGroup.describe "group" do
          around(:each) do |e|
            order << :before
            e.run
            order << :after
          end
          specify { order << :e1 }
          specify { order << :e2 }
        end

        group.run(double.as_null_object)
        order.should eq([:before, :e1, :after, :before, :e2, :after])
      end
    end
  end
end

