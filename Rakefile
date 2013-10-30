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

  desc "Copy all HTML pages"
  task :html do
    `rm -rf public/blogging public/api public/pages && cp -R ../alf/alf-doc/compiled/html/* public && mv public/blog public/blogging`
  end

end
task :default => [:"doc:json", :"doc:html"]