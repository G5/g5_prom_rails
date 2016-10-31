require 'rails_helper'

def expect_metric(reg, name, labels, value)
  m = reg.get(name)
  expect(m).to_not be_nil
  expect(m.get(labels)).to eq(value)
end

RSpec.describe G5PromRails::SidekiqApplicationMetrics do
  let(:metrics) { G5PromRails::MetricsContainer.new("test-app") }
  let(:reg) { metrics.per_application }

  before do
    allow(Sidekiq::Stats).to receive(:new).and_return(
      double(
        processed: 1,
        failed: 2,
        retry_size: 3,
      )
    )
    allow(Sidekiq::Stats::Queues).to receive(:new).and_return(
      double(lengths: { "default" => 11, "high" => 12 })
    )
  end

  it "works" do
    metrics.update_sidekiq_statistics
    expect_metric(reg, :sidekiq_processed, { app: "test-app" }, 1)
    expect_metric(reg, :sidekiq_failed, { app: "test-app" }, 2)
    expect_metric(reg, :sidekiq_retry, { app: "test-app" }, 3)
    expect_metric(
      reg,
      :sidekiq_queued,
      { app: "test-app", queue: "default" },
      11
    )
    expect_metric(
      reg,
      :sidekiq_queued,
      { app: "test-app", queue: "high" },
      12
    )
  end
end
