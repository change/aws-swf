require './lib/swf/boot'

describe SWF::Boot do
  before do
    $stdout.stub!(:write)

    SWF::Boot.stub(:settings) {
      { domain_name: 'phony_domain', task_list_name: 'phony_task_list'}
    }
  end

  describe '.swf_runner' do
    it "creates a new Runner object with the proper arguments" do
      SWF::Runner.should_receive(:new).with('phony_domain', 'phony_task_list')
      SWF::Boot.swf_runner
    end
  end

  describe '.startup' do
    before do
      SWF::Boot.stub(:swf_runner) { double(:runner, be_worker: 'worker', be_decider: 'decider') }
    end

    context 'without waiting for children' do
      it 'forks deciders' do
        Process.should_receive(:fork).exactly(5).times do |&blk|
          Process.should_receive(:daemon).with(true)
          SWF::Boot.should_receive(:swf_runner).once
          blk.call
        end
        Process.should_receive(:detach).with('decider').exactly(5).times
        SWF::Boot.startup(5,0)
      end
      it 'forks workers' do
        Process.should_receive(:fork).exactly(5).times do |&blk|
          Process.should_receive(:daemon).with(true)
          SWF::Boot.should_receive(:swf_runner).once
          blk.call
        end
        Process.should_receive(:detach).with('worker').exactly(5).times
        SWF::Boot.startup(0,5)
      end
    end

    context 'with waiting for children' do
      it 'forks deciders' do
        Process.should_receive(:fork).exactly(5).times do |&blk|
          Process.should_not_receive(:daemon)
          SWF::Boot.should_receive(:swf_runner).once
          blk.call
        end
        Process.should_receive(:wait).with('decider').exactly(5).times
        SWF::Boot.startup(5,0,true)
      end
      it 'forks workers' do
        Process.should_receive(:fork).exactly(5).times do |&blk|
          Process.should_not_receive(:daemon)
          SWF::Boot.should_receive(:swf_runner).once
          blk.call
        end
        Process.should_receive(:wait).with('worker').exactly(5).times
        SWF::Boot.startup(0,5,true)
      end
    end
  end

  describe '.terminate_children' do
    it 'calls Process.kill for each pid passed' do
      [1,2,3].each {|pid|
        Process.should_receive(:kill).with("TERM", pid).once
      }
      SWF::Boot.terminate_children([1,2,3])
    end
  end

end
