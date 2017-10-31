require 'prometheus/middleware/exporter'
require_relative 'metrics'
require_relative 'refreshing_exporter'
require_relative 'settable_counter'
require_relative 'sidekiq_timing_middleware'

module G5PromRails
  class Engine < ::Rails::Engine
    isolate_namespace G5PromRails

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "g5_prom_rails.configure" do |app|
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

      Prometheus::Middleware::Exporter.send(
        :prepend,
        G5PromRails::RefreshingExporter
      )

      per_application_middleware_opts = {
        path: G5PromRails::PER_APPLICATION_PATH,
        registry: G5PromRails::Metrics.per_application
      }
      per_process_middleware_opts = {
        path: G5PromRails::PER_PROCESS_PATH,
        registry: G5PromRails::Metrics.per_process
      }

      if defined?(Sidekiq)
        G5PromRails.add_refresh_hook do
          Metrics.update_sidekiq_statistics
        end

        timing_metric = G5PromRails::SidekiqTimingMiddleware.build_metric(
          G5PromRails::Metrics.per_process
        )
        Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add(
              G5PromRails::SidekiqTimingMiddleware,
              metric: timing_metric
            )
          end
        end

        # is sidekiq worker and we have to start a rack web server from which
        # to scrape
        if Sidekiq.server?.present?
          app = Rack::Builder.new do
            use Rack::ShowExceptions
            use Rack::Lint
            use Prometheus::Middleware::Exporter, per_process_middleware_opts
            run -> { [ '404', {}, ["Not Found"] ] }
          end

          Thread.new do
            Rails.logger.info("started g5_prom_rails metrics endpoint...")
            Rack::Server.start(
              app: app,
              Port: (G5PromRails.sidekiq_scrape_server_port || 3000),
            )
          end
        end
      else
        # this is a rails web server and we already have a place to hang rack
        # apps
        app.middleware.use(Prometheus::Middleware::Exporter, per_process_middleware_opts)
        app.middleware.use(Prometheus::Middleware::Exporter, per_application_middleware_opts)
      end
    end
  end
end
