require './lib/swf/activity_task_handler.rb'

subject_class = SWF::ActivityTaskHandler
describe subject_class do

  describe ' .register, .find_handler_class' do
    before { mock_subclass }

    let(:mock_subclass) {
      Class.new(subject_class) {
        register
        def handle_fake_activity; end
      }
    }

    it "registers and finds a subclass with a handle_* method matching a given activity name" do
      subject_class.find_handler_class(double(:task, activity_type: double(name: 'fake_activity', version: 'fake_version'))).should == mock_subclass
    end
  end

  let(:subject){ subject_class.new(:runner_placeholder, task) }
  let(:task){ double(:task, activity_type: double(name: 'fake_activity')) }
  describe '#initialize' do
    it 'sets runner & decision_task' do
      subject.runner.should == :runner_placeholder
      subject.activity_task.should == task
    end
  end



  describe '#call_handle' do
    it "calls #handle_* method" do
      subject.should_receive(:handle_fake_activity)

      subject.call_handle
    end
  end

  describe '.fail!' do
    it 'fails the activity task' do
      task = double(:task).tap {|o| o.should_receive(:fail!).with(:args_placeholder) }
      subject_class.fail! task, :args_placeholder
    end
  end

  describe '.configuration_help_message' do
    it { subject_class.configuration_help_message.should be_is_a String }
    it { subject_class.configuration_help_message.length.should > 100 }
    it { subject_class.configuration_help_message.should include 'activity' }
  end

end
