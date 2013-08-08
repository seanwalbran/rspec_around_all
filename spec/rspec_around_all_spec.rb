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
        2.times do |i| # test append/prepend hook behavior when two around(:all) blocks are defined
          around(:all) do |g|
            order = g.metadata[:order]
            order << "inner.before(:all) #{i}"
            g.run_examples
            order << "inner.after(:all) #{i}"
          end
        end

        around(:all_nested) do |g|
          order = g.metadata[:order]
          order << "inner.before(:all_nested)"
          g.run_examples
          order << "inner.after(:all_nested)"
        end

        specify { order << 'first' }
        specify { order << 'second' }


        context "inner" do
          specify { order << 'inner example'}

          example "blocks are executed in the right order" do
            expect(order).to eq [
              'config.before(:all_nested) 1',
              'config.before(:all) 1',
              'config.before(:all_nested) 2',
              'inner.before(:all) 0',
              'inner.before(:all) 1',
              'inner.before(:all_nested)',
              'first',
              'second',
              'config.before(:all_nested) 3',
              'inner.before(:all_nested)',
              'inner example',
            ]
          end
        end
      end

      # this context won't pass if run alone (rspec -e "part 2") since it depends on part 1 to run before it
      context "part 2" do
        example "before and after hooks order is correct" do
          expect(order[-7..-1]).to eq [
            'inner.after(:all_nested)', # part 1, context
            'config.after(:all_nested) 3', # inner context
            'inner.after(:all_nested)', # part 1, inner context
            'inner.after(:all) 1', # part 1, first around(:all)
            'inner.after(:all) 0', # part 1, second around(:all)
            'config.after(:all_nested) 2', # context
            'config.before(:all_nested) 4', # config.before part 2
          ]
        end
      end

    end
  end
end

