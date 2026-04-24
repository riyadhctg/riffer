# frozen_string_literal: true
# rbs_inline: enabled

class Riffer::Workflow
  attr_reader :steps #: Array[singleton(Riffer::Workflow::Step)]

  attr_reader :context #: Hash[Symbol, untyped]?

  #--
  #: (steps: Array[singleton(Riffer::Workflow::Step)], ?context: Hash[Symbol, untyped]?) -> void
  def initialize(steps:, context: nil)
    validate_steps!(steps)
    validate_context!(context)

    @steps = steps.dup.freeze
    @context = context
  end

  #--
  #: (?context: Hash[Symbol, untyped]?, **untyped) -> Riffer::Workflow::Result
  def run(context: @context, **input)
    validate_context!(context)
    Runner.new.call(@steps, input, context: context)
  end

  private

  #--
  #: (Array[untyped]) -> void
  def validate_steps!(steps)
    raise Riffer::ArgumentError, "steps must be a non-empty Array" unless steps.is_a?(Array) && !steps.empty?

    steps.each_with_index do |step, i|
      unless step.is_a?(Class) && step <= Riffer::Workflow::Step
        raise Riffer::ArgumentError, "steps[#{i}] must be a Riffer::Workflow::Step subclass, got #{step.inspect}"
      end

      step.identifier
    end
  end

  #--
  #: (Hash[Symbol, untyped]?) -> void
  def validate_context!(context)
    return if context.nil? || context.is_a?(Hash)

    raise Riffer::ArgumentError, "context must be a Hash"
  end
end
