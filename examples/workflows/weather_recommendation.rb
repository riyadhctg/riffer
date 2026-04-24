# frozen_string_literal: true

# Weather Recommendation Workflow
#
# Demonstrates a three-step Riffer::Workflow that turns a raw weather
# reading into a plan recommendation:
#
# - NormalizeWeather normalizes the raw input.
# - AssessConditions picks +indoor+ or +outdoor+ with a short reason.
# - RecommendPlan formats a user-facing summary.
#
# Also shows both happy-path and failure-path output from
# Riffer::Workflow::Result (success?, output, failed_step, error, and
# the per-step trace).
#
# Run:
#
#   bundle exec ruby examples/workflows/weather_recommendation.rb
#
# See docs/14_WORKFLOWS.md.
#
require "riffer"

class NormalizeWeather < Riffer::Workflow::Step
  input do
    required :condition, String
    required :temperature_c, Float
  end

  output do
    required :condition, String
    required :temperature_c, Float
  end

  def call(context:, condition:, temperature_c:)
    {
      condition: condition.strip.downcase,
      temperature_c: temperature_c
    }
  end
end

class AssessConditions < Riffer::Workflow::Step
  input do
    required :condition, String
    required :temperature_c, Float
  end

  output do
    required :condition, String
    required :temperature_c, Float
    required :recommendation, String
    required :reason, String
  end

  def call(context:, condition:, temperature_c:)
    if condition.include?("rain")
      recommendation = "indoor"
      reason = "Rain makes outdoor plans less appealing."
    elsif temperature_c >= 32.0
      recommendation = "indoor"
      reason = "High heat makes staying inside more comfortable."
    elsif temperature_c <= 5.0
      recommendation = "indoor"
      reason = "Cold weather makes outdoor plans less comfortable."
    else
      recommendation = "outdoor"
      reason = "Conditions look comfortable for being outside."
    end

    {
      condition: condition,
      temperature_c: temperature_c,
      recommendation: recommendation,
      reason: reason
    }
  end
end

class RecommendPlan < Riffer::Workflow::Step
  input do
    required :condition, String
    required :temperature_c, Float
    required :recommendation, String
    required :reason, String
  end

  output do
    required :recommendation, String
    required :summary, String
  end

  def call(context:, condition:, temperature_c:, recommendation:, reason:)
    {
      recommendation: recommendation,
      summary: "#{recommendation.capitalize}: #{condition} at #{temperature_c}C. #{reason}"
    }
  end
end

workflow = Riffer::Workflow.new(
  steps: [NormalizeWeather, AssessConditions, RecommendPlan]
)

def print_result(title, result)
  puts title
  puts "  success?:    #{result.success?}"
  puts "  output:      #{result.output.inspect}"
  puts "  failed_step: #{result.failed_step.inspect}"
  puts "  error:       #{result.error && "#{result.error.class}: #{result.error.message}"}"
  result.steps.each do |step|
    status = step.success? ? "ok " : "err"
    printf("  [%s] %s\n", status, step.step)
  end
  puts
end

print_result(
  "HAPPY PATH: sunny day",
  workflow.run(condition: "Sunny", temperature_c: 24.0)
)

print_result(
  "HAPPY PATH: rainy day",
  workflow.run(condition: "Rain", temperature_c: 21.0)
)

print_result(
  "FAILURE: wrong input type",
  workflow.run(condition: "Cloudy", temperature_c: "warm")
)
