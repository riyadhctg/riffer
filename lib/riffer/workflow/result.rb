# frozen_string_literal: true
# rbs_inline: enabled

# Represents the outcome of a workflow run.
#
# Provides access to the final output, per-step results, and overall
# success or failure.
#
class Riffer::Workflow::Result
  attr_reader :output #: Hash[Symbol, untyped]?

  attr_reader :steps #: Array[Riffer::Workflow::StepResult]

  #--
  #: (?output: Hash[Symbol, untyped]?, ?steps: Array[Riffer::Workflow::StepResult]) -> void
  def initialize(output: nil, steps: [])
    @output = output
    @steps = steps.dup.freeze
  end

  # Returns true when every executed step succeeded.
  #
  #--
  #: () -> bool
  def success?
    @steps.all?(&:success?)
  end

  # Returns true when any executed step failed.
  #
  #--
  #: () -> bool
  def failure?
    !success?
  end

  # Returns the error from the failed step, if any.
  #
  #--
  #: () -> StandardError?
  def error
    failed = @steps.find(&:failure?)
    failed&.error
  end

  # Returns the identifier of the failed step, if any.
  #
  #--
  #: () -> String?
  def failed_step
    failed = @steps.find(&:failure?)
    failed&.step
  end
end
