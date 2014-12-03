require 'spec_helper'
describe "/blog" do

  it 'works' do
    get '/blog/'
    expect(status).to eq(200)
    expect(title).to eq("Blog")
  end

  it 'works on an article' do
    get '/blog/2014-12-03-what-would-a-functional-sql-look-like'
    expect(status).to eq(200)
    expect(title).to eq("What would a functional SQL look like?")
  end

end
