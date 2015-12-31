require "spec_helper"
require "print"

$class_count = 0

describe Print do
  let(:test_class) { Class.new { include Print }.tap { |c| eval("Foo#{$class_count += 1} = c") } }
  let(:sub_class) { Class.new(test_class).tap { |c| eval("Foo#{$class_count += 1} = c") } }

  describe "#print" do
    let(:context) {
      instance_double("Print::Context").tap do |context|
        expect(context).to receive(:done)
        expect(context).to receive(:in_list).and_return(false)
      end
    }
    
    context "with no filters" do
      let(:instance) { test_class.new }
      it "should print but produce no output" do
        instance.print(context)
      end
    end

    context "with one filter" do
      let(:instance) { test_class.new }
      before(:example) do
        Print.add_filter(test_class.name, { level: 5 .. 11 }) do |context, item|
          context.output("output")
        end
      end

      it "should produce no output when context level not within filter level" do
        expect(context).to receive(:level).and_return(1)
        instance.print(context)
      end

      it "should produce output when context level within filter level" do
        expect(context).to receive(:level).and_return(8)
        expect(context).to receive(:output)
        instance.print(context)
      end
    end

    context "with multiple filters" do
      let(:instance) { test_class.new }
      before(:example) do
        Print.add_filter(test_class.name, { level: 6 .. 11 }) do |context, item|
          context.output("6-11")
        end

        Print.add_filter(test_class.name, { level: 8 .. 11 }) do |context, item|
          context.output("8-11")
        end

        Print.add_filter(test_class.name, { level: 5 .. 11 }) do |context, item|
          context.output("5-11")
        end
      end

      it "should produce no output when context level not within filter level" do
        expect(context).to receive(:level).and_return(1).at_least(:once)
        instance.print(context)
      end

      it "should produce output when context level within filter level" do
        expect(context).to receive(:level).and_return(8).at_least(:once)
        expect(context).to receive(:output).with("8-11")
        instance.print(context)
      end
    end

    context "subclasses inherit filters" do
      let(:instance) { sub_class.new }
      
      before(:example) do
        Print.add_filter(test_class.name, { level: 6 .. 11 }) do |context, item|
          context.output("6-11")
        end
      end

      it "should use filters for parent classes" do
        expect(context).to receive(:level).and_return(8).at_least(:once)
        expect(context).to receive(:output).with("6-11")
        instance.print(context)
      end
    end
  end
end
