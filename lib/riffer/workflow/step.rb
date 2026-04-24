# frozen_string_literal: true
# rbs_inline: enabled

# Riffer::Workflow::Step is the base class for all workflow steps.
#
# Provides a DSL for declaring +input+ and +output+ schemas with
# Riffer::Params, and an identifier used in Riffer::Workflow::Result.
# Subclasses must implement the +call+ method, which receives validated
# input and returns a Hash matching the output schema.
#
# See Riffer::Workflow and Riffer::Params.
#
#   class NormalizeWeather < Riffer::Workflow::Step
#     input do
#       required :condition, String
#       required :temperature_c, Float
#     end
#
#     output do
#       required :condition, String
#       required :temperature_c, Float
#     end
#
#     def call(context:, condition:, temperature_c:)
#       {condition: condition.strip.downcase, temperature_c: temperature_c}
#     end
#   end
#
class Riffer::Workflow::Step
  extend Riffer::Helpers::ClassNameConverter

  # Gets or sets the step identifier.
  #
  # When called without arguments, returns the explicit identifier if set,
  # otherwise derives one from the class name.
  #
  # [value] an optional identifier override.
  #
  # Raises Riffer::ArgumentError if the step class is anonymous.
  #
  #--
  #: (?String?) -> String
  def self.identifier(value = nil)
    class_name = name
    if class_name.nil? || class_name.empty?
      raise Riffer::ArgumentError, "#{Riffer::Workflow::Step} subclasses must be named classes"
    end

    if value.nil?
      return @identifier if @identifier
      class_name_to_path(class_name)
    else
      @identifier = value.to_s
    end
  end

  # Gets or sets the input schema for this step.
  #
  # When a block is given, defines the schema using the Riffer::Params DSL.
  # When called with no arguments, returns the configured Riffer::Params, or
  # +nil+ if none was declared.
  #
  # Raises Riffer::ArgumentError if +params+ is provided and is not a
  # Riffer::Params instance.
  #
  #--
  #: (?Riffer::Params?) ?{ () -> void } -> Riffer::Params?
  def self.input(params = nil, &block)
    if block
      @input_params = Riffer::Params.new
      @input_params.instance_eval(&block)
    elsif params.nil?
      @input_params
    else
      raise Riffer::ArgumentError, "input must be a Riffer::Params" unless params.is_a?(Riffer::Params)
      @input_params = params
    end
  end

  # Gets or sets the output schema for this step.
  #
  # When a block is given, defines the schema using the Riffer::Params DSL.
  # When called with no arguments, returns the configured Riffer::Params, or
  # +nil+ if none was declared.
  #
  # Raises Riffer::ArgumentError if +params+ is provided and is not a
  # Riffer::Params instance.
  #
  #--
  #: (?Riffer::Params?) ?{ () -> void } -> Riffer::Params?
  def self.output(params = nil, &block)
    if block
      @output_params = Riffer::Params.new
      @output_params.instance_eval(&block)
    elsif params.nil?
      @output_params
    else
      raise Riffer::ArgumentError, "output must be a Riffer::Params" unless params.is_a?(Riffer::Params)
      @output_params = params
    end
  end

  # Executes the step with validated input.
  #
  # Receives the shared workflow +context+ and keyword arguments matching
  # the declared input schema. Must return a Hash matching the declared
  # output schema.
  #
  # Raises Riffer::Error if not implemented by a subclass.
  #
  #--
  #: (context: Hash[Symbol, untyped]?, **untyped) -> Hash[Symbol, untyped]
  def call(context:, **kwargs)
    raise Riffer::Error, "#{self.class} must implement #call"
  end
end
