class G5PromRails::MetricsContainer
  MODEL_COUNT_NAME = :model_rows

  attr_reader :per_process, :per_application

  def initialize
    @per_process = Prometheus::Client::Registry.new
    @per_application = Prometheus::Client::Registry.new
    @model_count_gauge = @per_application.gauge(MODEL_COUNT_NAME, "model row counts")
  end

  def update_model_count_gauge(app, *models)
    models.each do |model|
      @model_count_gauge.set(
        { app: app, model: model.name.tableize },
        model.count
      )
    end
  end
end
