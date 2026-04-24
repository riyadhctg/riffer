# frozen_string_literal: true
# rbs_inline: enabled

# Riffer::Workflow composes Riffer::Workflow::Step classes into a
# deterministic, sequential pipeline.
#
# Each step receives validated input, returns a Hash, and passes its
# validated output to the next step. The final Riffer::Workflow::Result
# reports overall success or failure and per-step outcomes.
#
# An optional +context+ Hash is forwarded to every step and is intended
# for cross-cutting data (e.g. a user id, tenant id, or request id) that
# should not flow through each step's declared input and output.
#
# See Riffer::Workflow::Step and Riffer::Workflow::Result.
#
#   workflow = Riffer::Workflow.new(
#     steps: [NormalizeWeather, AssessConditions, RecommendPlan]
#   )
#
#   result = workflow.run(condition: "Rain", temperature_c: 21.0)
#   result.success?     # => true
#   result.output       # => {recommendation: "indoor", summary: "..."}
#   result.failed_step  # => nil
#
class Riffer::Workflow
  attr_reader :steps #: Array[singleton(Riffer::Workflow::Step)]

  attr_reader :context #: Hash[Symbol, untyped]?

  # Creates a new workflow.
  #
  # [steps]   a non-empty Array of Riffer::Workflow::Step subclasses.
  # [context] an optional Hash of shared data available to every step.
  #
  # Raises Riffer::ArgumentError if +steps+ is empty, contains a non-step
  # class, or if +context+ is not a Hash.
  #
  #--
  #: (steps: Array[singleton(Riffer::Workflow::Step)], ?context: Hash[Symbol, untyped]?) -> void
  def initialize(steps:, context: nil)
    validate_steps!(steps)
    validate_context!(context)

    @steps = steps.dup.freeze
    @context = context
  end

  # Runs the workflow with the given input and returns a Riffer::Workflow::Result.
  #
  # Keyword arguments are passed as the first step's input. An optional
  # +context+ overrides the context set at construction time.
  #
  # Does not raise from runtime step failures; inspect the returned Result
  # via +success?+, +failure?+, +error+, and +failed_step+. Raises
  # Riffer::ArgumentError if +context+ is not a Hash.
  #
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
