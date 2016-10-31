module G5PromRails
  PER_PROCESS_PATH = "/metrics"
  PER_APPLICATION_PATH = "/probe"

  cattr_accessor :initialize_per_application, :initialize_per_process
  cattr_accessor :sidekiq_scrape_server_port

  def self.add_refresh_hook(&block)
    @@refresh_hooks ||= []
    @@refresh_hooks << block
  end

  def self.refresh_gauges
    return if @@refresh_hooks.nil?
    @@refresh_hooks.each { |b| b.call }
  end

  def self.count_models(*models)
    add_refresh_hook do
      Metrics.update_model_count_gauge(*models)
    end
  end
end

# Down here due to fun behavior in implementing apps where G5PromRails module
# isn't defined if a class is defined straight up as G5PromRails::Whatever.
# Just scripting things.
require "g5_prom_rails/engine"
