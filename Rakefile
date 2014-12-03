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
desc "Import documentation from alf-doc"
task :doc => [:"doc:json", :"doc:html"]

desc %q{Run all RSpec tests}
task :test do
  require 'rspec'
  RSpec::Core::Runner.run(%w[-I. -Ispec --pattern=spec/**/test_*.rb --color .])
end
