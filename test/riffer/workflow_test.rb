# frozen_string_literal: true

require "test_helper"

module WorkflowTestSteps
  class SummarizerAgent < Riffer::Agent
    identifier "workflow-test-summarizer"
    model "mock/riffer-1"
    instructions "You are a concise summarizer."
  end

  class Increment < Riffer::Workflow::Step
    input do
      required :n, Integer
    end
    output do
      required :n, Integer
    end

    def call(context:, n:)
      {n: n + 1}
    end
  end

  class Double < Riffer::Workflow::Step
    input do
      required :n, Integer
    end
    output do
      required :n, Integer
    end

    def call(context:, n:)
      {n: n * 2}
    end
  end

  class Echo < Riffer::Workflow::Step
    def call(context:, **kwargs)
      kwargs
    end
  end

  class GreetTool < Riffer::Tool
    description "Greets a person"
    params do
      required :name, String
    end

    def call(context:, name:)
      text("Hello, #{name}!")
    end
  end

  class Greet < Riffer::Workflow::Step
    input do
      required :name, String
    end
    output do
      required :greeting, String
    end

    def call(context:, name:)
      response = GreetTool.new.call_with_validation(context: context, name: name)
      {greeting: response.content}
    end
  end

  class Summarize < Riffer::Workflow::Step
    input do
      required :text, String
    end

    output do
      required :summary, String
    end

    def call(context:, text:)
      response = SummarizerAgent.generate("Summarize:\n\n#{text}", context: context)
      {summary: response.content}
    end
  end
end

describe Riffer::Workflow do
  describe "construction" do
    it "freezes the steps array" do
      workflow = Riffer::Workflow.new(steps: [WorkflowTestSteps::Increment])
      expect(workflow.steps).must_be :frozen?
    end

    it "raises when steps is empty" do
      expect { Riffer::Workflow.new(steps: []) }.must_raise(Riffer::ArgumentError)
    end

    it "raises when steps is not an Array" do
      expect { Riffer::Workflow.new(steps: WorkflowTestSteps::Increment) }.must_raise(Riffer::ArgumentError)
    end

    it "raises when a step is not a Workflow::Step subclass" do
      expect { Riffer::Workflow.new(steps: [String]) }.must_raise(Riffer::ArgumentError)
    end

    it "raises when context is not a Hash" do
      expect {
        Riffer::Workflow.new(steps: [WorkflowTestSteps::Increment], context: "bad")
      }.must_raise(Riffer::ArgumentError)
    end
  end

  describe "#run" do
    it "runs steps sequentially, flowing output into next input" do
      workflow = Riffer::Workflow.new(
        steps: [WorkflowTestSteps::Increment, WorkflowTestSteps::Double]
      )
      result = workflow.run(n: 3)

      expect(result).must_be :success?
      expect(result.output).must_equal(n: 8)
      expect(result.steps.size).must_equal 2
      expect(result.steps.map(&:step)).must_equal ["workflow_test_steps/increment", "workflow_test_steps/double"]
    end

    it "raises when context passed to run is not a Hash" do
      workflow = Riffer::Workflow.new(steps: [WorkflowTestSteps::Echo])
      expect { workflow.run(context: "bad") }.must_raise(Riffer::ArgumentError)
    end

    it "uses the context provided at construction when run is called without one" do
      seen = nil
      step_class = Class.new(Riffer::Workflow::Step) do
        define_method(:call) do |context:, **kwargs|
          seen = context
          kwargs
        end
      end
      WorkflowTestSteps.const_set(:ContextCapture, step_class)

      workflow = Riffer::Workflow.new(
        steps: [WorkflowTestSteps::ContextCapture],
        context: {user_id: 42}
      )
      workflow.run

      expect(seen).must_equal(user_id: 42)
    ensure
      WorkflowTestSteps.send(:remove_const, :ContextCapture) if WorkflowTestSteps.const_defined?(:ContextCapture)
    end

    it "integrates with Riffer::Tool inside a step" do
      workflow = Riffer::Workflow.new(steps: [WorkflowTestSteps::Greet])
      result = workflow.run(name: "Ada")

      expect(result).must_be :success?
      expect(result.output).must_equal(greeting: "Hello, Ada!")
    end

    it "integrates with Riffer::Agent inside a step" do
      workflow = Riffer::Workflow.new(steps: [WorkflowTestSteps::Summarize])
      result = workflow.run(text: "Summarize this text")

      expect(result).must_be :success?
      expect(result.output).must_equal(summary: "Mock response")
    end
  end
end
