require './lib/runner'

class SWF::Runner
  def be_worker;end
end

describe SampleApp::Runner do
  let(:settings) { double(:settings) }
  let(:subject)  { SampleApp::Runner.new(settings) }

  describe '#be_worker' do
    before do
    end
    it 'calls #before_work' do
      subject.should_receive(:before_work)
      subject.send(:be_worker)
    end
  end
end