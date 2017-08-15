begin
  require 'sidekiq/api'

  module G5PromRails::SidekiqApplicationMetrics
    extend ActiveSupport::Concern

    def initialize_sidekiq_application
      @processed_counter = G5PromRails::SettableCounter.new(
        :sidekiq_processed,
        "jobs processed"
      )
      per_application.register(@processed_counter)
      @failed_counter = G5PromRails::SettableCounter.new(
        :sidekiq_failed,
        "jobs failed"
      )
      per_application.register(@failed_counter)

      @retry_gauge = per_application.gauge(
        :sidekiq_retry,
        "jobs to be retried"
      )
      @queues_gauge = per_application.gauge(
        :sidekiq_queued,
        "job queue lengths"
      )
    end

    def update_sidekiq_statistics
      stats = Sidekiq::Stats.new
      @processed_counter.set({}, stats.processed)
      @failed_counter.set({}, stats.failed)
      @retry_gauge.set({}, stats.retry_size)

      Sidekiq::Stats::Queues.new.lengths.each do |queue, length|
        @queues_gauge.set({ queue: queue }, length)
      end
    end
  end
rescue LoadError
  if defined?(Sidekiq)
    puts "problem loading sidekiq/api in g5_prom_rails, but you have sidekiq"
  end
end
