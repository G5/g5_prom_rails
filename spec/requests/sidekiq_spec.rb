require 'rails_helper'

RSpec.describe "Sidekiq Statistics", type: :request do
  it "works" do
    get "/probe"
    expect(response).to have_http_status(200)
    expect(response.body).to include("# TYPE sidekiq_processed counter")
    expect(response.body).to include("# HELP sidekiq_processed jobs processed")
    expect(response.body).to include(%[sidekiq_processed{app="dummy"} 0])
  end
end
