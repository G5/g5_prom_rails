require 'prometheus/client/rack/exporter'
require_relative 'metrics'
require_relative 'refreshing_exporter'

module G5PromRails
  class Engine < ::Rails::Engine
    isolate_namespace G5PromRails

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "g5_prom_rails.configure_global" do |app|
      G5PromRails::Metrics = MetricsContainer.new

      if G5PromRails.initialize_per_application.present?
        G5PromRails::Metrics.per_application.instance_eval(
          &G5PromRails.initialize_per_application
        )
      end

      if G5PromRails.initialize_per_process.present?
        G5PromRails::Metrics.per_process.instance_eval(
          &G5PromRails.initialize_per_process
        )
      end
    end

    initializer "g5_prom_rails.add_exporter" do |app|
      Prometheus::Client::Rack::Exporter.send(
        :prepend,
        G5PromRails::RefreshingExporter
      )

      app.middleware.use(
        Prometheus::Client::Rack::Exporter,
        path: G5PromRails::PER_PROCESS_PATH,
        registry: G5PromRails::Metrics.per_process
      )
      app.middleware.use(
        Prometheus::Client::Rack::Exporter,
        path: G5PromRails::PER_APPLICATION_PATH,
        registry: G5PromRails::Metrics.per_application
      )
    end
  end
end
