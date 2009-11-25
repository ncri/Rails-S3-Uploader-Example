# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_s3_uploader_example_session',
  :secret      => 'ab70ae13300667404263d55ecc4f4b4c0ad6cb25374594234e473aa7a1c935b7e505823516361527db002673259cc2f1101d7c24053daa62bd832f3286db4444'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
