# frozen_string_literal: true

require "test_helper"

module StepTestFixtures
  class MyStep < Riffer::Workflow::Step
  end

  class CustomId < Riffer::Workflow::Step
    identifier "custom.id"
  end

  class WithParams < Riffer::Workflow::Step
    input do
      required :x, Integer
    end
    output do
      required :y, Integer
    end
  end
end

describe Riffer::Workflow::Step do
  describe ".identifier" do
    it "derives an identifier from the class name" do
      expect(StepTestFixtures::MyStep.identifier).must_equal "step_test_fixtures/my_step"
    end

    it "allows a custom identifier to be set" do
      expect(StepTestFixtures::CustomId.identifier).must_equal "custom.id"
    end

    it "raises for anonymous classes" do
      anon = Class.new(Riffer::Workflow::Step)
      expect { anon.identifier }.must_raise(Riffer::ArgumentError)
    end
  end

  describe ".input / .output" do
    it "accepts a block DSL and stores a Riffer::Params" do
      expect(StepTestFixtures::WithParams.input).must_be_kind_of Riffer::Params
      expect(StepTestFixtures::WithParams.output).must_be_kind_of Riffer::Params
    end

    it "returns nil when not declared" do
      expect(StepTestFixtures::MyStep.input).must_be_nil
      expect(StepTestFixtures::MyStep.output).must_be_nil
    end

    it "raises when given a non-Params value" do
      klass = Class.new(Riffer::Workflow::Step)
      expect { klass.input({}) }.must_raise(Riffer::ArgumentError)
      expect { klass.output({}) }.must_raise(Riffer::ArgumentError)
    end
  end

  describe "#call" do
    it "raises by default, requiring subclasses to implement it" do
      expect { StepTestFixtures::MyStep.new.call(context: nil) }.must_raise(Riffer::Error)
    end
  end
end
