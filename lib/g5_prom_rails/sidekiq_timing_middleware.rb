class G5PromRails::SidekiqTimingMiddleware
  def self.build_metric(reg)
    reg.histogram(
      :sidekiq_job_seconds,
      "job running time in seconds",
      {},
      [
        10,
        30,
        90,
        3.minutes.to_i,
        7.minutes.to_i,
        12.minutes.to_i,
        20.minutes.to_i,
        35.minutes.to_i,
        60.minutes.to_i,
        80.minutes.to_i,
        2.hours.to_i,
        3.hours.to_i,
        5.hours.to_i,
        10.hours.to_i,
      ]
    )
  end

  def initialize(options = nil)
    @app = options[:app]
    @metric = options[:metric]
  end

  def call(worker, msg, queue)
    @metric.observe(
      { app: @app, job_class: worker.class.name },
      Benchmark.realtime { yield }
    )
  end
end
