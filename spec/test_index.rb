require 'spec_helper'
describe "/" do

  it 'works' do
    get '/'
    expect(status).to eq(200)
    expect(title).to eq("Try!")
  end

end
