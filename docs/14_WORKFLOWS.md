# Workflows

Workflows let you compose a fixed sequence of `Riffer::Workflow::Step` classes into a deterministic pipeline. Each step is a small unit of work with a declared input and output. It receives validated input, performs one stage of the workflow, and passes validated output to the next step until the workflow produces a final result.

## Example Usage of User-Facing API

This example takes a small weather input and turns it into a simple plan recommendation.
For convenience, the same example is available as `examples/workflows/weather_recommendation.rb` and can be run with `bundle exec ruby examples/workflows/weather_recommendation.rb`.

```text
weather input
  |
  v
NormalizeWeather
  |
  v
AssessConditions
  |
  v
RecommendPlan
  |
  v
result.output
```

The flow is: normalize the incoming weather data, assess the conditions, then return `indoor` or `outdoor` with a short summary.

```ruby
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

result = workflow.run(condition: "Rain", temperature_c: 21.0)

result.success?      # => true
result.output        # => {recommendation: "indoor", summary: "..."}
result.failed_step   # => nil
result.error         # => nil
```

## Failure Behavior

A workflow stops at the first failed step.

There are two ways a workflow can fail:

- Invalid workflow setup or invalid `run` arguments raise immediately. For example: empty `steps`, a non-step class in `steps`, or a non-hash `context`.
- Failures during step execution do not raise from `run`. Instead, `run` returns a failed `Riffer::Workflow::Result`. This includes step input validation, exceptions raised inside a step, and step output validation.

When a step fails:

- the workflow run fails
- remaining steps are skipped
- `result.failure?` is `true`
- `result.error` contains the exception
- `result.failed_step` contains the step identifier
- `result.output` contains the last successful output, or `nil` if no step succeeded

## Trade-Offs

- Workflow data must be a hash, and the framework does not rewrite keys. That keeps the behavior simple and explicit, but it means workflow authors are responsible for making sure each step returns data in the shape the next step expects.
- Steps are plain Ruby classes, so they can call Agents, Tools, other Workflows, or any other application code directly. This keeps the workflow API small and flexible, but it does not provide a special adapter layer or higher-level conveniences for common agent/tool step patterns.
- `Workflow#run` returns a `Result` object for step failures instead of raising. This makes failures easier to inspect and compose, but it means callers need to check the returned result rather than relying only on exception flow.
- Execution lives in a separate `Runner` class, and workflow results are represented with `Result` and `StepResult` objects instead of being assembled inline with hashes inside `Workflow#run`. This adds more internal structure, but it keeps execution flow and result handling easier to test and reason about.
- To keep the implementation focused on the core requirements, instrumentation is minimal. There is no built-in step timing, logging, or richer execution tracing yet, which keeps the design smaller but gives users less visibility into workflow execution.

## What I Would Build Next

- A shared workflow state model. Right now, each step receives the previous step’s output and passes a new hash to the next step, so authors must explicitly carry forward any fields that later steps still need. A shared state layer could make some sequential workflows more ergonomic.
- Conditional and branching workflows. Right now, workflows are strictly linear. The next step would be a small branching model where a workflow can choose the next step based on the current validated data, with an optional merge point when branches need to rejoin. That would cover common `if/else` routing without forcing the API all the way to a general graph model.
- Persistence and suspend/resume. Saving workflow state and step results at each boundary would make it possible to pause long-running workflows, support human review, and resume safely later instead of requiring the whole workflow to complete in one process.

## Assumptions And Open Questions

- The current design assumes that passing the previous step’s output directly into the next step is enough for most sequential workflows. That keeps the model simple, but it may be less ergonomic for workflows where steps mostly add to or update a larger shared state.
- The current target is deterministic, fixed pipelines rather than agent-style orchestration.
- The design assumes fail-fast execution is the right default. The workflow stops at the first failed step rather than attempting retries or partial continuation.
