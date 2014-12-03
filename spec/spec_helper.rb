ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'app'

RSpec.configure do |c|
  c.include Rack::Test::Methods

  def app
    TryAlf
  end

  def status
    last_response.status
  end

  def content_type
    last_response.content_type
  end

  def body
    last_response.body
  end

  def title
    body[%r{<title>Alf Relational Algebra - (.*?)</title>}, 1]
  end

  c.include Rack::Test::Methods
end
