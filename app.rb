Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

require 'path'
require 'sprockets'
require 'rack/robustness'
require 'rack/timeout'
require 'alf-core'
require 'alf/lang/parser/safer'
require 'alf-sequel'
require 'alf-rack'
require 'alf/rack/query'
require 'sinatra/base'
require 'wlang/tilt'

ENV['DATABASE_URL'] ||= "sqlite://sap.db"
DbUrl     = ENV['DATABASE_URL']
SequelDb  = ::Sequel.connect(DbUrl)
DbOptions = { parser: Alf::Lang::Parser::Safer }
PublicDir = Path.dir/'public'
PublicUrl = PublicDir.glob("*").map{|p| "/#{p.basename}"}
Doc       = (PublicDir/'doc.json').load

class App < Sinatra::Base

  configure do
    set :wlang, {
      layout: :html5
    }
  end

  configure :test do
    enable  :raise_errors
    enable  :dump_errors
    disable :show_exceptions
  end

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
    set :reload_templates, true
  end

  get '/' do
    wlang :try, locals: locals(:try, title: "Try!")
  end

  get %r{^/try/?$} do
    wlang :try, locals: locals(:try, title: "Try!")
  end

  get %r{^/about/?$} do
    wlang :about, locals: locals(:about, title: "About")
  end

  get %r{^/cheatsheet/?$} do
    wlang :cheatsheet, locals: locals(:cheatsheet, title: "Cheatsheet", doc: Doc)
  end

  get %r{^/blog/?$} do
    articles = (PublicDir/'blogging')
      .glob('*.html')
      .map do |f|
        id = f.basename.rm_ext
        text = f
          .read[/^(.*?)<h2/m, 1]
          .gsub(/<h1>/, "<h1><a href='/blog/#{id}'>")
          .gsub(/<\/h1>/, "</a></h1>")
        { id: id, text: text }
      end
      .reverse
    wlang :blog, locals: locals(:blog, title: "Blog", articles: articles)
  end

  get %r{^/blog/(.*?)$} do |url|
    article = (PublicDir/'blogging'/url).sub_ext('.html')
    if article.inside?(PublicDir) && article.exists?
      article = article.read
      title = article[%r{<h1>(.*?)</h1>}, 1]
      wlang :article, locals: locals(:blog, title: title, article: article)
    else
      not_found
    end
  end

  get %r{^/doc/?$} do
    article = (PublicDir/'pages/intro.html').read
    wlang :doc, locals: locals(:doc, title: "Documentation", doc: Doc, article: article)
  end

  get %r{^/doc/(.*?)$} do |url|
    article = (PublicDir/url).sub_ext('html')
    if article.inside?(PublicDir) && article.exists?
      article = article.read
      title = article[%r{<h1>(.*?)</h1>}, 1]
      wlang :doc, locals: locals(:doc, title: title, doc: Doc, article: article)
    else
      not_found
    end
  end

private

  def locals(main, locals)
    locals.merge({
      is_try: (main == :try),
      is_doc: (main == :doc),
      is_cheatsheet: (main == :cheatsheet),
      is_blog: (main == :blog),
      is_about: (main == :about),
    })
  end

end

TryAlf = ::Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::Static, urls: PublicUrl, root: "public"

  map '/assets' do
    environment = Sprockets::Environment.new
    environment.append_path 'assets/css'
    environment.append_path 'assets/js'
    run environment
  end

  map '/query' do
    use Rack::Robustness do |g|
      g.status 400
      g.content_type "text/plain"
      g.body{|ex| ex.message }
      g.ensure(true){|ex|
        puts "CouCOUCOUCOU"
        puts ex.message
        puts ex.backtrace.join("\n")
      }
    end
    use Rack::Timeout; Rack::Timeout.timeout = 1
    use Alf::Rack::Connect do |cfg|
      cfg.database = Alf::Database.new(SequelDb, DbOptions)
    end
    run Alf::Rack::Query.new{|q|
      q.type_check = true
      q.catch_all  = false
    }
  end

  run App
end
