# frozen_string_literal: true

require "test_helper"

describe Riffer::Workflow::Result do
  let(:ok_a) { Riffer::Workflow::StepResult.new(step: "a", output: {n: 1}) }
  let(:ok_b) { Riffer::Workflow::StepResult.new(step: "b", output: {n: 2}) }
  let(:fail_b) { Riffer::Workflow::StepResult.new(step: "b", error: RuntimeError.new("bad")) }

  it "is successful only when all step results are successful" do
    result = Riffer::Workflow::Result.new(output: {n: 2}, steps: [ok_a, ok_b])

    expect(result).must_be :success?
    expect(result).wont_be :failure?
    expect(result.error).must_be_nil
    expect(result.failed_step).must_be_nil
  end

  it "surfaces the first failing step's error and identifier" do
    result = Riffer::Workflow::Result.new(output: {n: 1}, steps: [ok_a, fail_b])

    expect(result).must_be :failure?
    expect(result.failed_step).must_equal "b"
    expect(result.error).must_be_kind_of RuntimeError
  end

  it "freezes the steps array" do
    result = Riffer::Workflow::Result.new(steps: [ok_a])
    expect(result.steps).must_be :frozen?
  end
end
