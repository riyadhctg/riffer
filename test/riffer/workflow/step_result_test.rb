# frozen_string_literal: true

require "test_helper"

describe Riffer::Workflow::StepResult do
  it "is successful when no error is present" do
    step_result = Riffer::Workflow::StepResult.new(step: "a", output: {x: 1})

    expect(step_result).must_be :success?
    expect(step_result).wont_be :failure?
  end

  it "is a failure when an error is present" do
    step_result = Riffer::Workflow::StepResult.new(step: "a", error: StandardError.new("nope"))

    expect(step_result).must_be :failure?
    expect(step_result).wont_be :success?
  end
end
