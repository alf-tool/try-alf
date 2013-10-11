require 'alf-core'
require 'alf-test'
require 'alf-sequel'
require 'sequel'

ENV['DATABASE_URL'] ||= Alf::Test::Sap.sequel_uri(:memory)

namespace :db do

  desc "Create the database"
  task :create do
    db = ::Sequel.connect(ENV['DATABASE_URL'])
    Alf::Test::Sap.install_sap_on(db)
  end

  desc "Migrate the database"
  task :migrate do
  end

end
