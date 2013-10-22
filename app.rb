require 'path'
require 'rack/robustness'
require 'rack/timeout'
require 'alf-core'
require 'alf/lang/parser/safer'
require 'alf-sequel'
require 'alf-rack'
require 'alf/rack/query'

ENV['DATABASE_URL'] ||= "sqlite://sap.db"
DbUrl     = ENV['DATABASE_URL']
SequelDb  = ::Sequel.connect(DbUrl)
DbOptions = { parser: Alf::Lang::Parser::Safer }
Queries   = (Path.dir/"examples").glob("*.yml").map(&:load)
PublicUrl = (Path.dir/'public').glob("*").map{|p| "/#{p.basename}"}

TryAlf = ::Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::Static, urls: PublicUrl, root: "public"
  map '/query' do
    use Rack::Timeout
    Rack::Timeout.timeout = 0.1
    use Alf::Rack::Connect do |cfg|
      cfg.database = Alf::Database.new(SequelDb, DbOptions)
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
  IndexService = Rack::File.new("public")
  run lambda{|env|
    IndexService.call(env.merge('PATH_INFO' => "index.html"))
  }
end
