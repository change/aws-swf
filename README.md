SWF
==========

This is our SWF wrapper library. It will likely eventually be gemified.

For now, you can follow the example in ../feature-matrix/ to see how to use it.

Basically, you'll want to require `swf`, `workflows`, `swf/boot`, `swf/decision_task_handler` and `swf/activity_task_handler` (in feature-matrix, we have a `lib/swf.rb` that does all this for you)

You will probably want your own `lib/swf/boot.rb` and `lib/swf/runner.rb` that get your SWF domain, task list, and anything else important for all workflows/activities to have access to.

If you want to run workers from outside of an irb context, you'll probably want to copy `bin/swf_fm` and have it call your new Boot as well.


Workflows
=========
```ruby
require './lib/swf' # this should do all the path munging and requiring necessary, see feature-matrix/lib/swf.rb for example
require 'myactivity'

module MyWorkflow

  extend SWF::Workflows

  # this tells SWF what workflow type this module handles
  # it is currently a one-to-one correspondance
  def self.workflow_type
    effect_workflow_type('foobar_workflow', '1',
      default_child_policy: :request_cancel,
      default_task_start_to_close_timeout:      3600,
      default_execution_start_to_close_timeout: 3600,
    )
  end

  class DecisionTaskHandler < SWF::DecisionTaskHandler
    register('foobar_workflow', '1') # registers the class with the workflow type

    # the decider will poll for new events, if they are of type ('foobar_workflow', '1') they will get passed to handle
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

      # if you care about not just new events:
      # events.map {|e| e }
    end
  end
end
```

Activities
==========
```ruby
require './lib/swf' # this should do all the path munging and requiring necessary

module MyActivity

  # this tells SWF what activity types this module can handle
  def self.activity_type_foobar_activity(runner)
    runner.effect_activity_type('foobar_activity', '1',
      default_task_heartbeat_timeout:             3600,
      default_task_schedule_to_start_timeout:     3600,
      default_task_schedule_to_close_timeout:     7200,
      default_task_start_to_close_timeout:        3600
    )
  end

  # a single module can handle many activity types
  def self.activity_type_lorem_activity(runner)
     runner.effect_activity_type('lorem_activity', '1',
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

    # likewise for ("lorem_activity", "1")
    def handle_lorem_activity

    end
  end
end
```

