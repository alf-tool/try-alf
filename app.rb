require 'path'
require 'rack/robustness'
require 'rack/timeout'
require 'alf-core'
require 'alf/lang/parser/safer'
require 'alf-sequel'
require 'alf-rack'
require 'alf/rack/query'

DbUrl     = ENV['DATABASE_URL'] ||= "sap.db"
DbOptions = { parser: Alf::Lang::Parser::Safer }
Queries   = (Path.dir/"examples").glob("*.yml").map(&:load)
PublicUrl = (Path.dir/'public').glob("*").map{|p| "/#{p.basename}"}

TryAlf = ::Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::Static, urls: PublicUrl, root: "public"
  map '/one' do
    run lambda{|env|
      Alf::Rack::Response.new(env){|r| r.body = Queries.sample }
    }
  end
  map '/query' do
    use Rack::Timeout
    Rack::Timeout.timeout = 0.01
    use Alf::Rack::Connect do |cfg|
      cfg.database = Alf::Database.new(DbUrl, DbOptions)
    end
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
      q.catch_all  = false
    }
  end
  ['/', '/try/', '/about/', '/cheatsheet/'].each do |url|
    map(url) do
      run Rack::File.new("public/index.html")
    end
  end
end
