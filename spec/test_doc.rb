require 'spec_helper'
describe "/doc and subpages" do

  it 'works on /doc/' do
    get '/doc/'
    expect(status).to eq(200)
    expect(title).to eq("Documentation")
  end

  it 'works on a page' do
    get '/doc/pages/ruby-basics'
    expect(status).to eq(200)
    expect(title).to eq("Ruby basics")
  end

end