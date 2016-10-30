# G5 Prom Rails

This gem provides a rails engine that provides very basic help in integrating Prometheus into your Rails app. It brings in Prometheus Exporter middleware, initializes a metrics registry, and can add metrics for common use-cases and Rails gems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'g5_prom_rails'
```

And then execute:
```bash
$ bundle
```

## Usage

The engine brings in the `prometheus-client` ruby gem. It is well-documented, and `g5_prom_rails` doesn't insulate you from how that gem works. You should [read its documentation](https://github.com/prometheus/client_ruby) to understand what metric types are available to you and how to update them. Registries and metrics endpoints are configured for you.

This gem is designed to work when Prometheus scrapes both individual instances of Rails (horizontally scaled processes) and the application as a whole. Application-level metrics are those that are shared between every Rails process, like database model counts or background job queue sizes. Per-process metrics are instrumented events that hit individual processes, like a particular controller action being called. Prometheus deals with aggregating events that happen in multiple disconnected processes, like load balanced Rails web servers.

## Configuration

There are a few configuration points for the engine, which you should specify in an initializer. Here's an example of a simple recommended setup:

**`config/initializers/metrics.rb`**
```ruby
METRICS = Metrics.new

G5PromRails.initialize_per_application = -> (registry) {
  METRICS.initialize_per_application(registry)
}

G5PromRails.initialize_per_application = -> (registry) {
  METRICS.initialize_per_process(registry)
}

G5PromRails.add_refresh_hook do
  METRICS.published_posts.set({}, Post.where(published: true).count)
end
```

**`lib/metrics.rb`**
```ruby
class Metrics
  attr_reader :published_posts, :post_shares

  def initialize_per_application(registry)
    @published_posts = registry.gauge(:my_app_posts, "published blog posts")
  end

  def initialize_per_application(registry)
    @post_shares = registry.counter(:my_app_post_shares, "blog post shares")
  end
end
```

**`app/controllers/posts_controller.rb`**
```ruby
class PostsController < ApplicationController
  def share
    METRICS.post_shares.increment
    # ... a bunch of important business logic
  end
end
```

There are a few things going on here. In the initializer, you have hooks to initialize new metric types depending on their scope. Each lambda is passed a Prometheus registry instance, which is where you attach the metric types. They are safe for concurrent access, and the individual metric instances you're instantiating are the objects you'll be interacting with in your code when you want to instrument something.

The `Metrics` class is part of your codebase, and this structure is only a recommendation. I'm suggesting that fewer global variables are easier to deal with, but you could reimplement what I've done here with multiple globals and keep it all within your initializer (except the controller instrumentation).

We're instrumenting two things in this example: the number of Posts in the database, and the number of times any Post was shared.

Post count hits the database, and no matter which process you asked, the answer would be the same. You do *not* want to ask every process individually as it would generate pointless database queries and multiple copies of the same data.

Share count is per-process. With a load balancer and scaled web processes, different instances of your application might serve the request to share a blog post. You increment a counter in your controller code, and Prometheus deals with aggregating the differing values for this metric from each process.

An additional wrinkle is the `add_refresh_hook` in the initializer. This is a hook to update your metrics when the application-level metrics endpoint is hit. For a metric like database row counts, this is the easiest place to make sure the metrics up-to-date before you provide them to Prometheus. Because this hook is called every time the endpoint is hit, you should avoid any extremely strenuous queries, as it will be called at Prometheus's regular scrape interval.

## Warnings

There are a couple of general Prometheus tips things to keep in mind.

  * Namespace your metrics. If you named a metric `users`, that's the name of the metric for every other user of your Prometheus server. You should name it `your_app_users`. This engine does not force namespaces on you, because it's possible you'll want to aggregate metrics across multiple applications.
  * Read [the official Prometheus guidelines on metric naming](https://prometheus.io/docs/practices/naming/). It's short and extremely helpful.
  * Did you see the big warning at the end of the naming guidelines? Labels in Prometheus are extremely powerful; I encourage you to use them, but don't abuse them. A new time series database is created for every combination of label values. Feel free to use a label that could have dozens of possible values, for instance in your blog post counter to differentiate drafts from published articles. Do *not* use `author_id` as a label to count posts by author. *Especially* do not use multiple labels that could have many possible values, because the effect on the total number of time series databases is multiplicative.

## Sidekiq

Prometheus's strategy is to scrape metrics. If you take a moment to think about it, we have a problem: how do you scrape in-memory metrics from a Sidekiq worker? That process doesn't start a web server.

Well, it does now. If you have Sidekiq and the process is a worker, it will start a thread with a simple Rack server that only serves metric. By default this will run on port 3000, but it can be configured with:

```ruby
G5PromRails.sidekiq_scrape_server_port = 3001
```

## Helpers

There are some common instrumentation tasks that this gem can help you with.

#### Row Counts

When you'd like to instrument the count of certain ActiveRecord models, in an initializer you can:

```ruby
G5PromRails.count_models(:my_app, Post, Comment)
```

Will result in a gauge metric named `model_rows` with a `model` label set to the tableized name of your model and an `app` label set to the `my_app`. In PromQL this will look like:
```promql
model_rows{model="posts", app="my_app"}
```

This metric is left un-namespaced because it gives you the ability to compare these values across applications, while still allowing them to be limited to a single app via PromQL. The values will automatically be refreshed when the application-level metrics endpoint is hit.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
