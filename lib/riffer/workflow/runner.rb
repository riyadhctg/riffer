# frozen_string_literal: true
# rbs_inline: enabled

# Riffer::Workflow::Runner executes a list of Riffer::Workflow::Step
# classes in order.
#
# Validates each step's input before calling it, validates its output
# before passing it to the next step, and stops at the first failure.
# Used internally by Riffer::Workflow#run.
#
class Riffer::Workflow::Runner
  # Runs the given steps with the provided initial input.
  #
  # Returns a Riffer::Workflow::Result containing the per-step trace and
  # the last successful step's output.
  #
  # [steps]   an Array of Riffer::Workflow::Step subclasses.
  # [input]   the Hash passed as input to the first step.
  # [context] the shared context Hash forwarded to every step.
  #
  #--
  #: (Array[singleton(Riffer::Workflow::Step)], Hash[Symbol, untyped], context: Hash[Symbol, untyped]?) -> Riffer::Workflow::Result
  def call(steps, input, context:)
    step_results = [] #: Array[Riffer::Workflow::StepResult]
    current_data = ensure_hash(input)
    last_output = nil #: Hash[Symbol, untyped]?

    steps.each do |step_class|
      step_result = execute_step(step_class, current_data, context: context)
      step_results << step_result

      unless step_result.success?
        return Riffer::Workflow::Result.new(output: last_output, steps: step_results)
      end

      current_data = step_result.output || {}
      last_output = current_data
    end

    Riffer::Workflow::Result.new(output: last_output, steps: step_results)
  end

  private

  #--
  #: (singleton(Riffer::Workflow::Step), Hash[Symbol, untyped], context: Hash[Symbol, untyped]?) -> Riffer::Workflow::StepResult
  def execute_step(step_class, data, context:)
    validated_input = validate_input(step_class, data)
    step = step_class.new
    raw_output = step.call(context: context, **validated_input)
    validated_output = validate_output(step_class, raw_output)

    Riffer::Workflow::StepResult.new(
      step: step_class.identifier,
      output: validated_output
    )
  rescue => e
    Riffer::Workflow::StepResult.new(
      step: step_class.identifier,
      error: e
    )
  end

  #--
  #: (singleton(Riffer::Workflow::Step), Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
  def validate_input(step_class, data)
    return data unless step_class.input

    step_class.input.validate(data)
  end

  #--
  #: (singleton(Riffer::Workflow::Step), untyped) -> Hash[Symbol, untyped]
  def validate_output(step_class, data)
    hash_output = ensure_hash(data)
    return hash_output unless step_class.output

    step_class.output.validate(hash_output)
  end

  #--
  #: (untyped) -> Hash[Symbol, untyped]
  def ensure_hash(value)
    raise Riffer::ValidationError, "workflow data must be a Hash" unless value.is_a?(Hash)

    value
  end
end
