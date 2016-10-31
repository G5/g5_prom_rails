require 'rails_helper'

RSpec.describe "G5PromRails.count_models", type: :request do
  before { Post.create!(title: "Foo") }

  it "works" do
    get "/probe"
    expect(response).to have_http_status(200)
    expect(response.body).to include("# TYPE model_rows gauge")
    expect(response.body).to include("# HELP model_rows model row counts")
    expect(response.body).to include(%[model_rows{app="dummy",model="posts"} 1])
  end
end
