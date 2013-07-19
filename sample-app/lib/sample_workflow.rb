require 'aws-swf'
require './lib/sample_activity'

module SampleWorkflow

  extend SWF::Workflows

  WORKFLOW_NAME    = 'sample_workflow'
  WORKFLOW_VERSION = '1'

  # this tells SWF what workflow type this module handles
  # it is currently a one-to-one correspondance
  def self.workflow_type
    effect_workflow_type(WORKFLOW_NAME, WORKFLOW_VERSION,
      default_child_policy:         :request_cancel,
      default_task_start_to_close_timeout:      3600,
      default_execution_start_to_close_timeout: 3600,
    )
  end

  class DecisionTaskHandler < SWF::DecisionTaskHandler
    register(WORKFLOW_NAME, WORKFLOW_VERSION) # registers the class with the workflow type
    # the decider will poll for new events
    # if they are of type ('sample_workflow', '1') they will get passed to handle
    def handle
      # for all possible event types see
      # http://docs.aws.amazon.com/sdkfornet/latest/apidocs/html/T_Amazon_SimpleWorkflow_Model_HistoryEvent.htm
      new_events.each {|event|
        case event.event_type
        when 'WorkflowExecutionStarted'
          schedule_sample_activity
        when 'ActivityTaskCompleted'
          decision_task.complete_workflow_execution
        when 'ActivityTaskFailed'
          decision_task.fail_workflow_execution
        end
      }
      # if you care about not just new events:
      # events.map {|e| e }
    end

    def schedule_sample_activity
      decision_task.schedule_activity_task(SampleActivity.activity_type_sample_activity(runner),
        input: workflow_input.merge({decision_param: 'decision'}).to_json,
        task_list: workflow_task_list
      )
    end
  end
end