source "https://rubygems.org"

ruby '1.9.3'

gem 'thin'
gem "sequel",  "~> 4.2"
gem "rack-robustness", "~> 1.1"

gem "alf-core",   :git => "git://github.com/alf-tool/alf-core.git"
gem "alf-sql",    :git => "git://github.com/alf-tool/alf-sql.git"
gem "alf-sequel", :git => "git://github.com/alf-tool/alf-sequel.git"
gem "alf-test",   :git => "git://github.com/alf-tool/alf-test.git"
gem "alf-rack",   :git => "git://github.com/alf-tool/alf-rack.git"

# gem 'alf-core',   path: "../alf-core"
# gem 'alf-sql',    path: "../alf-sql"
# gem 'alf-sequel', path: "../alf-sequel"
# gem 'alf-test',   path: "../alf-test"
# gem 'alf-rack',   path: "../alf-rack"

group :runtime do
  gem "pg", "~> 0.17"
end

group :development do
  gem "sqlite3", "~> 1.3"
end
