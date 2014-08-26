Parliament.configure do |config|
  # The sum of +1/-1 must meet or exceed this threshold
  #config.threshold = 3

  # Current status must be success
  #config.check_status = true

  # An array of required voters' github usernames
  # Also accepts an array-returning Proc that is called on each check with
  # the raw data from the webhook.
  #config.required_usernames = []
end
