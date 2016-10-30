require 'rails_helper'

RSpec.describe "/probe", type: :request do
  it "works" do
    get "/probe"
    expect(response).to have_http_status(200)
    expect(response.body).to_not include("test_process_gauge")
    expect(response.body).to include("# TYPE test_app_gauge gauge")
    expect(response.body).to include("# HELP test_app_gauge test app gauge description")
    expect(response.body).to include("test_app_gauge 31981")
  end
end

RSpec.describe "/metrics", type: :request do
  it "works" do
    get "/metrics"
    expect(response).to have_http_status(200)
    expect(response.body).to_not include("test_app_gauge")

    expect(response.body).to include("# TYPE test_process_gauge gauge")
    expect(response.body).to include("# HELP test_process_gauge test process gauge description")
    expect(response.body).to include("test_process_gauge 123")
  end
end
