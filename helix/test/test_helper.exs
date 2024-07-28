Test.DB.on_start()

ExUnit.start()

ExUnit.after_suite(fn _ ->
  Test.DB.on_finish()
end)
