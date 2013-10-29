require 'alf-core'
require 'alf-doc'
require 'json'
require 'alf/doc/to_html'

namespace :doc do

  desc "Generates doc.json"
  task :json do
    # generate doc.json
    (Path.dir/"public/doc.json").write(Alf::Doc.all.tuple_extract.to_json)
  end

  desc "Generates API pages"
  task :api do
    # generate API pages for every object
    [:operators, :predicates, :aggregators].each do |kind|
      Alf::Doc.query(kind).each do |obj|
        target = (Path.dir/'public/api')/"#{obj.name}.html"
        puts "#{obj.name} -> #{target}"
        target.write Alf::Doc::ToHtml.new.send(kind.to_s[0...-1].to_sym, obj)
      end
    end
  end

  desc "Generates other pages"
  task :pages do
    Alf::Doc.pages.each do |page|
      target = page.relocate(page.parent, Path.dir/'public/api', ".html")
      puts "#{page} -> #{target}"
      target.write Alf::Doc::ToHtml.new.page(page.read)
    end
  end

  desc "Generates blog pages"
  task :blog do
    (Path.dir/"blog").glob("*.md") do |page|
      target = page.relocate(page.parent, Path.dir/'public/blogging/', ".html")
      puts "#{page} -> #{target}"
      target.write Alf::Doc::ToHtml.new.page(page.read)
    end
  end

end
task :default => [:"doc:json", :"doc:api", :"doc:pages", :"doc:blog"]