# frozen_string_literal: true
# rbs_inline: enabled

# Riffer::Workflow::Result represents the outcome of a Riffer::Workflow run.
#
# Exposes the final output, the per-step trace, and convenience accessors
# for the first failed step's identifier and error. Returned from
# Riffer::Workflow#run; runtime step failures are reported here rather
# than raised.
#
# See Riffer::Workflow and Riffer::Workflow::StepResult.
#
#   result = workflow.run(condition: "Rain", temperature_c: 21.0)
#
#   if result.success?
#     deliver(result.output)
#   else
#     log("Workflow failed at #{result.failed_step}: #{result.error.message}")
#   end
#
class Riffer::Workflow::Result
  # The last successful step's validated output, or +nil+ if no step succeeded.
  attr_reader :output #: Hash[Symbol, untyped]?

  # The per-step trace, in execution order.
  attr_reader :steps #: Array[Riffer::Workflow::StepResult]

  #--
  #: (?output: Hash[Symbol, untyped]?, ?steps: Array[Riffer::Workflow::StepResult]) -> void
  def initialize(output: nil, steps: [])
    @output = output
    @steps = steps.dup.freeze
  end

  # Returns +true+ when every step succeeded.
  #
  #--
  #: () -> bool
  def success?
    @steps.all?(&:success?)
  end

  # Returns +true+ when any step failed.
  #
  #--
  #: () -> bool
  def failure?
    !success?
  end

  # Returns the exception from the first failed step, or +nil+ when all
  # steps succeeded.
  #
  #--
  #: () -> StandardError?
  def error
    failed = @steps.find(&:failure?)
    failed&.error
  end

  # Returns the identifier of the first failed step, or +nil+ when all
  # steps succeeded.
  #
  #--
  #: () -> String?
  def failed_step
    failed = @steps.find(&:failure?)
    failed&.step
  end
end
