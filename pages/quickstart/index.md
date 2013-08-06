---
layout: page
title: "Quickstart"
description: "Get up and running fast with aws-swf"
group: navigation
---
{% include JB/setup %}
This tutorial follows along with [sample-aws-swf-app](https://github.com/vijaykramesh/sample-aws-swf-app) on Github.

<div class="toc well"></div>

<br>
### App Structure

An aws-swf application has three basic components:

#### Workflows
These define your decision task handling. A workflow is responsible for starting activities/child-workflows and handling success/failure. Your workflow pattern can be as complicated or as simple as your application demands - because of the distributed nature of activity processing, and your ability to use task-lists to pair certain activities to certain types of resources, your decision task handler can simply define the workflow pattern, including failure handling, etc. See [the Workflow Patterns initiative](http://www.workflowpatterns.com/) for a wealth of information about workflows and process handling.

#### Activities
An activity is where your aws-swf application does actual units of work. Your workflow will initiate activities, passing on input data. Returns success or failure back to the workflow.

#### Runner
Your application includes a Boot module that creates a Runner instance. This is what sets a resource up to poll SWF for decisions and activities.

<br>

### Workflows
####[SampleApp::SampleWorkflow](https://github.com/vijaykramesh/sample-aws-swf-app/blob/master/lib/sample_workflow.rb)
A workflow extends [SWF::Workflow](https://github.com/change/aws-swf/blob/master/lib/workflows.rb). It should also define a `self.workflow_type` method that calls `effect_workflow_type` to register the module. This is where you can set default timeouts for the workflow type (see the [aws-sdk docs](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/WorkflowType.html) for all available parameters). Note that if you change one of these defaults, you must increment `WORKFLOW_VERSION`:

```ruby
def self.workflow_type
  effect_workflow_type(WORKFLOW_TYPE, WORKFLOW_VERSION,
    default_child_policy:                     :request_cancel,
    default_task_start_to_close_timeout:      3600,
    default_execution_start_to_close_timeout: 3600,
  )
end
```


The workflow module should also have a `DecisionTaskHandler` inner-class that registers and defines `handle`. This method will be called as new events occur.

```ruby
class DecisionTaskHandler < SWF::DecisionTaskHandler
  register(WORKFLOW_TYPE, WORKFLOW_VERSION)

  def handle
    new_events.each {|e| ... }
  end
end
```

<br>

####Event handling
Your workflow does sequential event handling across a distributed network of deciders - scheduling activities, acting on success/failure, creating child workflows, etc. For a full list of history events, [see the docs](http://docs.aws.amazon.com/sdkfornet/latest/apidocs/html/T_Amazon_SimpleWorkflow_Model_HistoryEvent.htm). See [the Workflow Patterns initiative](http://www.workflowpatterns.com/) for a wealth of information about workflow patterns.

<br>
#####Simple workflow - single activity
```ruby
def handle
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
end

def schedule_sample_activity
  decision_task.schedule_activity_task(SampleActivity.activity_type_sample_activity(runner),
    input: workflow_input.merge({decision_param: 'decision'}).to_json,
    task_list: workflow_task_list
  )
end
```

<br>

#####Child workflows
There is a one-to-one correspondance between a workflow module and a workflow type on SWF. However, an application may have multiple child workflows that a parent workflow initiates and handles. A child workflow is just a normal workflow that signals to the parent workflow when execution is complete/failed.

```ruby
def handle
  child_workflow_failed = false
  scheduled_child_workflows = []
  completed_child_workflows = []
  new_events.each {|event|
    case event.event_type
    when 'WorkflowExecutionStarted'
      scheduled_child_workflows = schedule_child_workflows
    when 'ChildWorkflowExecutionFailed'
      child_workflow_failed = true
    when 'ChildWorkflowExecutionCompleted'
      completed_child_workflows << event.attributes.workflow_execution
    end
  }

  if child_workflow_failed
    decision_task.fail_workflow_execution
  elsif (scheduled_child_workflows - completed_child_workflows).empty?
    decision_task.complete_workflow_execution
  end
end

def schedule_child_workflows
  10.times.map {|i|
    decision_task.start_child_workflow_execution(
      AnotherWorkflow.workflow_type,
      input: another_input_hash(i).to_json,
      task_list: decision_task.workflow_execution.task_list,
      tag_list: another_tag_array(i),
    )
  }
end
```

<br>

#####Multiple activities
`TODO`

<br>

### Activities
####[SampleApp::SampleActivity](https://github.com/vijaykramesh/sample-aws-swf-app/blob/master/lib/sample_activity.rb)
An activity module can handle multiple activity types. For each it must define an `activity_type_<activity_name>` class method that receives a runner and calls `runner.effect_activity_type`. This is where you can set activity specific timeouts (again, [see the docs](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/ActivityType.html))

```ruby
def self.activity_type_sample_activity(runner)
  runner.effect_activity_type('sample_activity', '1',
    default_task_heartbeat_timeout:             3600,
    default_task_schedule_to_start_timeout:     3600,
    default_task_schedule_to_close_timeout:     7200,
    default_task_start_to_close_timeout:        3600
  )
end
```

Your activity module should also have a `ActivityTaskHandler` inner-class that registers and defines `handle_<activity_name>` methods to handle activity tasks as they are scheduled by decision tasks.

```ruby
class ActivityTaskHandler < SWF::ActivityTaskHandler
  register

  def handle_sample_activity
    ...
  end
end
```

<br>

###Running your application

####Launching Workers
Launching workers for workflow and activity tasks is just as simple as calling `SampleApp::Boot.startup(num_deciders, num_workers, wait_for_children, &rescue)`. However in automating resource bootstrapping you might want a simple shell script like [sample-app/bin/swf_run.rb](sample-app/bin/swf_run.rb)

```ruby
#!/usr/bin/env ruby

require './lib/boot'

def run!
  startup_hash = ARGV.inject(Hash.new(0)) {|h,i| h[i.to_sym] += 1; h }
  SampleApp::Boot.startup(startup_hash[:d], startup_hash[:w], true)
end

run!
```

which you can then call via init/upstart/monit/etc:

```bash
$ SWF_DOMAIN=some_domain S3_BUCKET=some_bucket S3_PATH=some_path LOCAL_DATA_DIR=/tmp ruby ./sample-app/bin/swf_run.rb d d w w w
```

TODO
- demonstrate starting workers on multiple physical resources
- demonstrate automating launching EC2 resources, using tags to bootstrap
- demonstrate rescue logging to S3


####Starting a Workflow

You start a workflow by calling the `start` method on your workflow module, passing input and configuration options (see [the docs](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/WorkflowType.html#start_execution-instance_method) for configuration specifics)

```ruby
SWF.domain_name = "some_domain"
SampleWorkflow.start(
  { input_param: "some input" },
  task_list: "some_task_list",
  execution_start_to_close_timeout: 3600,
)
```

The workflow will be submitted to SWF; assuming you have started a decision task handler on that domain and task list, the WorkflowExecutionStarted event will be picked up by SampleWorkflow::DecisionTaskHandler#handle

See [the integration spec](https://github.com/vijaykramesh/sample-aws-swf-app/blob/master/spec/integration/sample_workflow_spec.rb) for an end-to-end example.

### What's next?
