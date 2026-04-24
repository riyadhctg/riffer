# frozen_string_literal: true
# rbs_inline: enabled

class Riffer::Workflow::Result
  attr_reader :output #: Hash[Symbol, untyped]?

  attr_reader :steps #: Array[Riffer::Workflow::StepResult]

  #--
  #: (?output: Hash[Symbol, untyped]?, ?steps: Array[Riffer::Workflow::StepResult]) -> void
  def initialize(output: nil, steps: [])
    @output = output
    @steps = steps.dup.freeze
  end

  #--
  #: () -> bool
  def success?
    @steps.all?(&:success?)
  end

  #--
  #: () -> bool
  def failure?
    !success?
  end

  #--
  #: () -> StandardError?
  def error
    failed = @steps.find(&:failure?)
    failed&.error
  end

  #--
  #: () -> String?
  def failed_step
    failed = @steps.find(&:failure?)
    failed&.step
  end
end
