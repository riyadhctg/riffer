# frozen_string_literal: true

require "test_helper"

module RunnerTestSteps
  class AddOne < Riffer::Workflow::Step
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

  class RequireFoo < Riffer::Workflow::Step
    input do
      required :foo, String
    end

    def call(context:, foo:)
      {foo: foo}
    end
  end

  class DeclareBar < Riffer::Workflow::Step
    output do
      required :bar, String
    end

    def call(context:, **kwargs)
      {not_bar: "oops"}
    end
  end

  class Boom < Riffer::Workflow::Step
    def call(context:, **kwargs)
      raise "kaboom"
    end
  end

  class ReturnsNil < Riffer::Workflow::Step
    def call(context:, **kwargs)
      nil
    end
  end

  class RecordContext < Riffer::Workflow::Step
    class << self
      attr_accessor :seen_context
    end

    def call(context:, **kwargs)
      self.class.seen_context = context
      kwargs
    end
  end

  class NeverRuns < Riffer::Workflow::Step
    class << self
      attr_accessor :ran
    end
    self.ran = false

    def call(context:, **kwargs)
      self.class.ran = true
      kwargs
    end
  end
end

describe Riffer::Workflow::Runner do
  let(:runner) { Riffer::Workflow::Runner.new }

  it "runs steps sequentially and returns a successful Result" do
    result = runner.call(
      [RunnerTestSteps::AddOne, RunnerTestSteps::AddOne, RunnerTestSteps::AddOne],
      {n: 0},
      context: nil
    )

    expect(result).must_be :success?
    expect(result.output).must_equal(n: 3)
    expect(result.steps.map(&:success?)).must_equal [true, true, true]
  end

  it "captures input validation failures and skips subsequent steps" do
    RunnerTestSteps::NeverRuns.ran = false

    result = runner.call(
      [RunnerTestSteps::RequireFoo, RunnerTestSteps::NeverRuns],
      {},
      context: nil
    )

    expect(result).must_be :failure?
    expect(result.failed_step).must_equal "runner_test_steps/require_foo"
    expect(result.error).must_be_kind_of Riffer::ValidationError
    expect(result.steps.size).must_equal 1
    expect(RunnerTestSteps::NeverRuns.ran).must_equal false
  end

  it "captures output validation failures" do
    result = runner.call([RunnerTestSteps::DeclareBar], {}, context: nil)

    expect(result).must_be :failure?
    expect(result.error).must_be_kind_of Riffer::ValidationError
  end

  it "captures arbitrary exceptions raised in a step" do
    result = runner.call(
      [RunnerTestSteps::AddOne, RunnerTestSteps::Boom, RunnerTestSteps::AddOne],
      {n: 0},
      context: nil
    )

    expect(result).must_be :failure?
    expect(result.failed_step).must_equal "runner_test_steps/boom"
    expect(result.error).must_be_kind_of RuntimeError
    expect(result.error.message).must_equal "kaboom"
    expect(result.steps.size).must_equal 2
  end

  it "captures non-hash step output as a ValidationError" do
    result = runner.call([RunnerTestSteps::ReturnsNil], {}, context: nil)

    expect(result).must_be :failure?
    expect(result.error).must_be_kind_of Riffer::ValidationError
  end

  it "passes context through to each step" do
    RunnerTestSteps::RecordContext.seen_context = nil

    runner.call([RunnerTestSteps::RecordContext], {}, context: {user_id: 7})

    expect(RunnerTestSteps::RecordContext.seen_context).must_equal(user_id: 7)
  end

  it "preserves the last successful output on the Result when a later step fails" do
    result = runner.call(
      [RunnerTestSteps::AddOne, RunnerTestSteps::Boom],
      {n: 10},
      context: nil
    )

    expect(result).must_be :failure?
    expect(result.output).must_equal(n: 11)
  end
end
