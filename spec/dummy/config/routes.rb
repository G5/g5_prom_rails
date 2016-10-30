Rails.application.routes.draw do
  mount G5PromRails::Engine => "/g5_prom_rails"
end
