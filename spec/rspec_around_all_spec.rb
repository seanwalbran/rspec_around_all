require_relative '../lib/rspec_around_all'

RSpec.configure do |c|
  [:all, :all_nested].each do |all_type|
    c.around(all_type) do |group|
      (group.run_examples; next) unless order = group.metadata[:order]
      count = group.metadata[:count][all_type] += 1
      order << "config.before(:#{all_type}) #{count}"
      group.run_examples
      order << "config.after(:#{all_type}) #{count}"
    end
  end
end

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

      it 'allows around hooks with no scope argument to run as normal' do
        order = []

        group = ExampleGroup.describe "group" do
          around do |e|
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

    describe "config.around(:all) hook", order: [], count: {all_nested: 0, all: 0} do
      order = nil
      context "part 1" do
        around(:all) do |g|
          order = g.metadata[:order]
          order << 'inner.before(:all)'
          g.run_examples
          order << 'inner.after(:all)'
        end

        specify { order << 'first' }
        specify { order << 'second' }

        example "blocks are executed in the right order" do
          expect(order).to eq [
            'config.before(:all_nested) 1',
            'config.before(:all) 1',
            'config.before(:all_nested) 2',
            'inner.before(:all)',
            'first',
            'second',
          ]
        end
      end

      # this context won't pass if run alone (rspec -e "part 2") since it depends on part 1 to run before it
      context "part 2" do
        example "before and after hooks order is correct" do
          expect(order[-3..-1]).to eq [
            'inner.after(:all)', # part 1
            'config.after(:all_nested) 2', # inner config.around
            'config.before(:all_nested) 3', # config.before part 2
          ]
        end
      end

    end
  end
end

