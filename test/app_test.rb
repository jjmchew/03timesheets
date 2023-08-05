ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../app.rb'
require_relative 'testing_methods'

# rubocop:disable Layout/LineLength
class AppTest < Minitest::Test
  include Rack::Test::Methods
  include TestingMethods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Sinatra App'
  end
  # rubocop:enable Layout/LineLength
end