require 'path'
require 'rack/robustness'
require 'alf-core'
require 'alf-sequel'
require 'alf-test'
require 'alf-rack'
require 'alf/rack/query'

Queries = (Path.dir/"examples").glob("*.yml").map(&:load)

TryAlf = ::Rack::Builder.new do

  use Rack::CommonLogger

  # Serve static files in ./public folder
  use Rack::Static, urls: (Path.dir/'public').glob("*").map{|p| "/#{p.basename}"},
                    root: "public"

  # Connect to the suppliers and parts exemplar
  use Alf::Rack::Connect do |cfg|
    ENV['DATABASE_URL'] ||= Alf::Test::Sap.sequel_uri(:sqlite)
    cfg.database = ENV['DATABASE_URL']
  end

  map '/one' do
    run lambda{|env|
      Alf::Rack::Response.new(env){|r| r.body = Queries.sample }
    }
  end

  # Serve query executions under POST /query
  map '/query' do
    use Rack::Robustness do |g|
      g.status 400
      g.content_type "text/plain"
      g.body{|ex| ex.message }
      g.ensure(true){|ex|
        puts ex.message
      }
    end
    run Alf::Rack::Query.new{|q|
      q.type_check = true
      q.catch_all = false
    }
  end

  # Simply redirect to index page on root
  ['/', '/try/', '/blog/', '/about/'].each do |url|
    map(url) do
      run Rack::File.new("public/index.html")
    end
  end
end
