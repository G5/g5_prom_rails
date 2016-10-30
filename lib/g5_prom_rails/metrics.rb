class G5PromRails::MetricsContainer
  attr_reader :per_process, :per_application

  def initialize
    @per_process = Prometheus::Client::Registry.new
    @per_application = Prometheus::Client::Registry.new
  end
end
