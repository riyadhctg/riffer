# frozen_string_literal: true
# rbs_inline: enabled

class Riffer::Workflow::Step
  extend Riffer::Helpers::ClassNameConverter

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

  #--
  #: (context: Hash[Symbol, untyped]?, **untyped) -> Hash[Symbol, untyped]
  def call(context:, **kwargs)
    raise Riffer::Error, "#{self.class} must implement #call"
  end
end
