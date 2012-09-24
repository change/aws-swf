SWF
==========

This is our SWF wrapper library. It will likely eventually be gemified.

For now, you can follow the example in ../feature-matrix/ to see how to use it.

Basically, you'll want to require `swf`, `workflows`, `swf/boot`, `swf/decision_task_handler` and `swf/activity_task_handler` (in feature-matrix, we have a `lib/swf.rb` that does all this for you)

You will probably want your own `lib/swf/boot.rb` and `lib/swf/runner.rb` that get your SWF domain, task list, and anything else important for all workflows/activities to have access to.

If you want to run workers from outside of an irb context, you'll probably want to copy `bin/swf_fm` and have it call your new Boot as well.


Workflows
=========

    require './lib/swf' # this should do all the path munging and requiring necessary
    require 'myactivity'

    module MyWorkflow

      def self.workflow_type
        SWF::Workflows.effect_workflow_type('foobar_workflow', '1',
          default_child_policy: :request_cancel,
          default_task_start_to_close_timeout:      3600,
          default_execution_start_to_close_timeout: 3600,
        )
      end

      def self.start(input_param, execution_options = {})
        execution_options[:task_list] ||= SWF.task_list
        execution_options.merge!({
          input: {
            input_param: input_param
          }.to_json
        })

        workflow_type.start_execution(execution_options)
      end

      class DecisionTaskHandler < SWF::DecisionTaskHandler
        register('foobar_workflow', '1')

        # this method "magically" gets called when a workflow of ('foobar_workflow', 1) is executed, and on new events
        def handle
          new_events.each {|event|
            case event.event_type
            when 'WorkflowExecutionStarted'
              decision_task.schedule_activity_task(
                MyActivity.activity_type_foobar_activity(runner),
                input: workflow_input.merge({other_param: 'foobar'}),
                task_list: workflow_task_list
              )
            when 'ActivityTaskCompleted'
              decision_task.complete_workflow_execution
            end
          }
        end
      end
    end

Activities
==========
    require './lib/swf' # this should do all the path munging and requiring necessary

    module MyActivity

      def self.activity_type_combine_output runner
        runner.effect_activity_type('foobar_activity', '1',
          default_task_heartbeat_timeout:             3600,
          default_task_schedule_to_start_timeout:     3600,
          default_task_schedule_to_close_timeout:     7200,
          default_task_start_to_close_timeout:        3600
        )
      end


      class ActivityTaskHandler < SWF::ActivityTaskHandler
        register

        # this method "magically" gets called when an activity of type ("foobar_activity", 1) is scheduled
        def handle_foobar_activity
          puts activity_task_ipnut["input_param"]
          puts activity_task_input["other_param"]
        end
      end
    end


