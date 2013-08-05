require './lib/swf/activity_task_handler.rb'

describe SWF::TaskHandler do
  before { $stdout.stub :write }

  subject { Class.new(Object) { extend SWF::TaskHandler } }

  describe '.get_handler_class_or_fail' do
    context "(when nothing registered) " do
      it "fails the activity task" do
        subject.should_receive(:find_handler_class).with(:task_placeholder)
        subject.should_receive(:configuration_help_message) { :configuration_help_message_placeholder }
        subject.should_receive(:fail!) {|task, args|
          task.should == :task_placeholder
          args[:reason].should == "unknown type"
          args[:details].should include 'configuration_help_message_placeholder'
        }

        subject.send :get_handler_class_or_fail, :task_placeholder
      end
    end

    context "(when handler (subclass) is registered with a handle_* method matching activity type's name) " do
      it "returns the handler (subclass)" do
        subject.should_not_receive(:fail!)
        subject.should_receive(:find_handler_class).with(:task_placeholder) { :subclass_placeholder }

        subject.send(:get_handler_class_or_fail, :task_placeholder).should == :subclass_placeholder
      end
    end
  end

  describe '.handle' do
    before {
      subject.should_receive(:find_handler_class).with(:task_placeholder) {
        double(:handler_class, name: 'handler_class_name').tap{|hc|
          hc.should_receive(:new).with(:runner_placeholder, :task_placeholder).and_return(handler)
        }
      }
    }

    let(:handler) { double(:handler).tap {|o|
      @call_handle_receiver = o.should_receive(:call_handle)
    } }

    context "(if subclass#call_handle raises)" do
      it "fails the activity" do
        handler
        @call_handle_receiver.and_raise("fail")
        subject.should_receive(:fail!)

        subject.handle :runner_placeholder, :task_placeholder
      end
    end

    context "(if subclass#call_handle succeeds)" do
      it "all works fine (no activity fail)" do
        subject.should_not_receive(:fail!)

        subject.handle :runner_placeholder, :task_placeholder
      end
    end
  end

end
