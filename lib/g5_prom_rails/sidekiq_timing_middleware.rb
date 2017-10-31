class G5PromRails::SidekiqTimingMiddleware
  def self.build_metric(reg)
    reg.histogram(
      :sidekiq_job_seconds,
      "job running time in seconds",
      {},
      [
        0,
        0.2,
        0.5,
        1,
        5,
        10,
        30,
        90,
        3.minutes.to_i,
        7.minutes.to_i,
        12.minutes.to_i,
        30.minutes.to_i,
        60.minutes.to_i,
        90.minutes.to_i,
        2.hours.to_i,
        3.hours.to_i,
      ].freeze
    )
  end

  def initialize(options = nil)
    @metric = options[:metric]
  end

  def call(worker, msg, queue)
    @metric.observe(
      { job_class: worker.class.name },
      Benchmark.realtime { yield }
    )
  end
end
