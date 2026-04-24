# frozen_string_literal: true
# rbs_inline: enabled

# Represents the outcome of a single workflow step.
#
# On success, +output+ contains the step's validated Hash output.
# On failure, +error+ contains the exception raised for that step.
#
class Riffer::Workflow::StepResult
  attr_reader :step #: String

  attr_reader :output #: Hash[Symbol, untyped]?

  attr_reader :error #: StandardError?

  #--
  #: (step: String, ?output: Hash[Symbol, untyped]?, ?error: StandardError?) -> void
  def initialize(step:, output: nil, error: nil)
    @step = step
    @output = output
    @error = error
  end

  # Returns true when the step succeeded.
  #
  #--
  #: () -> bool
  def success? = @error.nil?

  # Returns true when the step failed.
  #
  #--
  #: () -> bool
  def failure?
    !success?
  end
end
