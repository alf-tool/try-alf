require 'spec_helper'
describe "/about" do

  it 'works' do
    get '/about'
    expect(status).to eq(200)
    expect(title).to eq("About")
  end

end