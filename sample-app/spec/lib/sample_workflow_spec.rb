require './lib/sample_workflow'

describe SampleWorkflow do
  let(:test_run_identifier) { "spec-aws-swf/%08x-%08x" % [Time.now.to_i, rand(0xFFFFFFFF)] }
  let(:settings) {
    {
      swf_domain:     'aws-swf-test',
      s3_bucket:      'aws-swf-test',
      s3_path:        test_run_identifier,
      local_data_dir: '/tmp'
    }
  }
  let(:runner){
    double(:runner,
      settings: settings
    )
  }

  let(:task_list){ 'lorem_task_list' }

  describe SampleWorkflow::DecisionTaskHandler do

    let(:decision_task) {
      double(:decision_task,
        new_events: [],
        events: [],
        domain: :domain_placeholder
      )
    }

    let(:handler) { SampleWorkflow::DecisionTaskHandler.new(runner, decision_task) }
    let(:workflow_started_input) {
      {
        "input_param" => "input"
      }
    }

    let(:workflow_started_event) {
      double(:event,
        event_type: 'WorkflowExecutionStarted',
        attributes: double(:attributes,
          task_list: task_list,
          input: workflow_started_input.to_json
        )
      )
    }

    let(:activity_scheduled_event) {
      double(:event,
        event_type: 'ActivityTaskScheduled',
        event_id: 'SA',
        attributes: double(:attributes,
          activity_type: double(:activity_type, name: 'sample_activity'),
        )
      )
    }

    let(:activity_completed_event) {
      double(:event,
        event_type: 'ActivityTaskCompleted',
        event_id: 'SA_COMPLETED',
        attributes: double(:attributes, scheduled_event_id: 'SA')
      )
    }

    let(:activity_failed_event) {
      double(:event,
        event_type: 'ActivityTaskFailed',
        attributes: double(:attributes, scheduled_event_id: 'SA')
      )
    }

    context 'with a WorkflowExecutionStarted event' do
      before do
        handler.stub(:workflow_started_event) { workflow_started_event }
      end

      # state-dependent test for handle
      describe '#handle' do

        context 'new events processing' do
          it "calls #schedule_sample_activity on WorkflowExecutionStarted" do
            handler.stub(:new_events) { [ workflow_started_event ] }
            handler.should_receive(:schedule_sample_activity)
            handler.send(:handle)
          end

          context "on ActivityTaskCompleted" do
            before do
              handler.stub(:new_events) { [ activity_completed_event ] }
            end
            it "calls decision_task.complete_workflow_execution" do
              decision_task.should_receive(:complete_workflow_execution)
              handler.send(:handle)
            end
          end

        end
      end

      # state-independent tests, this stuff all gets called by handle
      describe '#schedule_sample_activity' do
        it 'schedules an activity_type_sample_activity activity task with the proper arguments' do
          SampleActivity.stub(:activity_type_sample_activity).and_return(:activity_type_sample_activity)
          activity_task_input = workflow_started_input.merge({decision_param: "decision"})
          decision_task.should_receive(:schedule_activity_task).with(:activity_type_sample_activity, input: activity_task_input.to_json, task_list: task_list)
          handler.send(:schedule_sample_activity)
        end
      end

    end
  end

end
