module G5PromRails::RefreshingExporter
  def respond_with(format)
    G5PromRails.refresh_gauges if @path == G5PromRails::PER_APPLICATION_PATH
    super
  end
end
