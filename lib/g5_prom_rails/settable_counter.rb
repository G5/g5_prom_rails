# prometheus-client provides a counter that can only be incremented. That works
# great for instrumenting events, but in the case of something like Sidekiq
# Processed count, prometheus (the server) can handle resets and all kinds of
# great stuff if I simply pass the count as-is. Rather than having to monkey
# with saving the previous value and all that nonsense, I just want to set the
# value and let the server deal with it.
class G5PromRails::SettableCounter < Prometheus::Client::Metric
  def type
    :counter
  end

  def set(labels, value)
    @values[label_set_for(labels)] = value
  end
end
