test_app_gauge = nil
test_process_gauge = nil

G5PromRails.count_models(Post)

G5PromRails.initialize_per_application = -> (reg) {
  test_app_gauge = reg.gauge(:test_app_gauge, "test app gauge description")
}

G5PromRails.initialize_per_process = -> (reg) {
  test_process_gauge = reg.gauge(:test_process_gauge, "test process gauge description")
  test_process_gauge.set({}, 123)
}

G5PromRails.add_refresh_hook do
  test_app_gauge.set({}, 31981)
end
