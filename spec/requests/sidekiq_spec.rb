require 'rails_helper'

# NOTE TO FUTURE ME: Sidekiq tests have a different middleware chain. The code
# that registers the middleware in the engine initializer isn't what is getting
# tested. See spec/rails_helper.

RSpec.describe "Sidekiq Statistics", type: :request do
  it "works" do
    get "/probe"
    expect(response).to have_http_status(200)
    expect(response.body).to include("# TYPE sidekiq_processed counter")
    expect(response.body).to include("# HELP sidekiq_processed jobs processed")
    expect(response.body).to include(%[sidekiq_processed])
  end


  it "works" do
    TestWorker.perform_async
    get "/metrics"
    expect(response).to have_http_status(200)
    expect(response.body).to include("# TYPE sidekiq_job_seconds histogram")
    expect(response.body).to include("# HELP sidekiq_job_seconds job running time in seconds")
    expect(response.body).to include(
      %[sidekiq_job_seconds_count{job_class="TestWorker"} 1]
    )
  end
end
