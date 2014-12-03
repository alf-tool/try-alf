require 'spec_helper'
describe "/cheatsheet" do

  it 'works' do
    get '/cheatsheet'
    expect(status).to eq(200)
    expect(title).to eq("Cheatsheet")
  end

end
