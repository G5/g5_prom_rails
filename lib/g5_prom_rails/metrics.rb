require_relative 'sidekiq_application_metrics'

class G5PromRails::MetricsContainer
  if defined?(Sidekiq)
    include G5PromRails::SidekiqApplicationMetrics
  end

  MODEL_COUNT_NAME = :model_rows

  attr_reader :app
  attr_reader :per_process, :per_application

  def initialize(app)
    @app = app
    @per_process = Prometheus::Client::Registry.new
    @per_application = Prometheus::Client::Registry.new
    @model_count_gauge = @per_application.gauge(MODEL_COUNT_NAME, "model row counts")
    try(:initialize_sidekiq_application)
  end

  def update_model_count_gauge(*models)
    models.each do |model|
      @model_count_gauge.set(
        { app: app, model: model.name.tableize },
        model.count
      )
    end
  end

protected

  def app_hash(h = {})
    { app: app }.merge(h)
  end
end
