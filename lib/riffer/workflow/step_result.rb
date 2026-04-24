# frozen_string_literal: true
# rbs_inline: enabled

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

  #--
  #: () -> bool
  def success? = @error.nil?

  #--
  #: () -> bool
  def failure?
    !success?
  end
end
