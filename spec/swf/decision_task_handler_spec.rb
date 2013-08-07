require './lib/swf/decision_task_handler.rb'

subject_class = SWF::DecisionTaskHandler
describe subject_class do

  describe ' .register, .find_handler_class' do
    before { mock_subclass }

    let(:mock_subclass) {
      Class.new(subject_class) {
        register :fake_name, "fake_version"
      }
    }

    it "registers and finds a subclass for a given workflow name/version" do
      subject_class.find_handler_class(double(:task, workflow_type: double(name: 'fake_name', version: 'fake_version'))).should == mock_subclass
    end
  end

  let(:decision_task) { double(:decision_task, events: []) }
  let(:subject){ subject_class.new(:runner_placeholder, decision_task ) }

  describe '#initialize' do
    it 'sets runner & decision_task' do
      subject.runner.should == :runner_placeholder
      subject.decision_task.should == decision_task
    end
  end

  describe '#call_handle' do
    it "calls #handle" do
      subject.should_receive(:handle)
      subject.call_handle
    end
  end

  describe '#events' do
    it 'calls decision_task.events if no @events' do
      subject.instance_variable_set(:@events, nil)
      subject.decision_task.should_receive(:events)
      subject.events.should == []
    end
    it 'otherwise just returns @events' do
      subject.instance_variable_set(:@events, :foobar)
      subject.decision_task.should_not_receive(:events)
      subject.events.should == :foobar
    end
  end

  let(:new_events) {[
    double(:event,
      event_type: 'new_event',
      new?: true
    ),
    double(:event,
      event_type: 'another_new_event',
      new?: true
    )
  ]}

  let(:old_events) {[
    double(:event,
      event_type: 'old_event',
      new?: false
    ),
    double(:event,
      event_type: 'another_old_event',
      new?: false
    )
  ]}

  describe '#new_events' do
    before do
      subject.decision_task.stub(:events) {
        new_events + old_events
      }
    end

    it 'enumerates over new events' do
      subject.send(:new_events).each {|e|
        new_events.include?(e).should be_true
        old_events.include?(e).should be_false
      }
    end

  end

  let(:workflow_started_input){ {"foo" => "bar"} }
  let(:task_list) { 'foobar' }
  let(:workflow_started_event) {
    double(:event,
      event_type: 'WorkflowExecutionStarted',
      attributes: double(:attributes,
        task_list: task_list,
        input: workflow_started_input.to_json
      )
    )
  }

  describe '#workflow_started_event' do
    it 'raises SWF::MissingWorkflowStartedEvent if there is no WorkflowExecutionStartedEvent' do
      ->{ subject.send(:workflow_started_event) }.should raise_exception(SWF::MissingWorkflowStartedEvent)
    end
    it 'otherwise returns the workflow started event' do
      subject.decision_task.stub(:events){ [ workflow_started_event] }
      subject.send(:workflow_started_event).should == workflow_started_event
    end
  end

    context 'with a workflow_started_event' do
      before do
        subject.stub(:workflow_started_event) { workflow_started_event }
      end

      describe '#workflow_task_list' do
        it 'returns the task list' do
          subject.send(:workflow_task_list).should == workflow_started_event.attributes.task_list
        end
      end
      describe '#workflow_input' do
        it 'returns the workflow input as a hash' do
          subject.send(:workflow_input).should == workflow_started_input
        end
      end
    end


  describe '.fail!' do
    it 'fails the workflow execution' do
      task = double(:task).tap {|o| o.should_receive(:fail_workflow_execution).with(:args_placeholder) }
      subject_class.fail! task, :args_placeholder
    end
  end

  describe '.configuration_help_message' do
    it { subject_class.configuration_help_message.should be_is_a String }
    it { subject_class.configuration_help_message.length.should > 100 }
    it { subject_class.configuration_help_message.should include 'decision' }
  end

end
