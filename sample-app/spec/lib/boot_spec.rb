require './lib/boot'

describe SampleApp::Boot do
  let(:settings) { double(:settings) }
  before do
    SampleApp::Boot.stub(:settings) { settings }
  end

  describe '.swf_runner' do
    before do
      stub_const("SampleApp::Runner", double(:runner).tap {|r| r.should_receive(:new).with(settings) } )
    end
    it "creates a new Runner object with the proper arguments" do
      SampleApp::Boot.swf_runner
    end
  end
end