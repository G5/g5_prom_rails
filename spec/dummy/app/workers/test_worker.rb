class TestWorker
  include Sidekiq::Worker

  def perform
    1+1
  end
end
