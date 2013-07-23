aws-swf
==========

aws-swf is our light framework for developing distributed applications in Ruby to run on [AWS Simple Workflow](http://aws.amazon.com/swf/).

At [change.org](http://www.change.org) we use aws-swf to drive parallelized and distributed processing for machine-learning driven email targeting. SWF provides the plumbing from the socket up to our application, enabling us to focus on innovating in terms of our data science, performance, UX, etc without having to worry about the complexities of message passing and asynchronous task scheduling across a decentralized system. If a worker dies, a task throws an exception, or somebody spills a cup of coffee on a rack of servers at AWS, configurable timeouts at different levels enable our workflow to be notified of the problem and decide how to handle it. Additionally by focusing on parallelizable algorithms we can scale the number of computational nodes as demand and data sizes dictate - nothing changes in the application code, we simply spin up more workers to handle the additional load.

While we use aws-swf on EC2, any resource - including your laptop - can be a task runner. This makes integration testing a breeze - you can unit test the core functionality of your activity task handlers, test the flow control of your decision task handlers, and then actually test end-to-end (against a test domain on SWF) against fixtures from your development box. It is also handy for R&D, if you want to iterate more quickly on a 24-core metal machine (running 24 activity workers, taking advantage of local filesystem speeds), before moving to EC2 and spreading those 24 workers across 12 dual-core instances.

For the purposes of this tutorial, we are going to leave dynamic resource allocation and bootstrapping off the table, and just focus on building an application that can be run locally. You can follow along with the example in [sample-app](sample-app/).

## Amazon Simple Workflow
SWF allows you to define activities (units of work to be performed) and workflows (decision/flow-control logic that schedules activities based on dependencies, handles failures, etc). You register both under a SWF domain, and can then poll that domain for a given tasklist from any resource (EC2, metal, or other cloud). AWS serves as a centralized place to poll for your distributed deciders and workers - handling message coordination and ensuring decision tasks are processed sequentially. Your decider workflows schedule (often massively parallel) activities, await for success/failure, and then act accordingly. New deciders and activity workers can be brought up and down on demand, and with a small amount of care to handling timeouts and failures, your distributed application can be made incredibly robust and resilient to intermittent failures and network connectivity issues, as well as easily adaptable to different data-scales and time-constraints. Look through the [Introduction to Amazon Simple Workflow Service](http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-intro-to-swf.html) docs for more information.

## App Structure

An aws-swf application has three basic components:

### Workflows
These define your decision task handling. A workflow is responsible for starting activities/child-workflows and handling success/failure.

### Activities
An activity is where your aws-swf application does actual units of work. Your workflow will initiate activities, passing on input data. Returns success or failure back to the workflow.

### Runner
Your application includes a Boot module that creates a Runner instance. This is what sets a resource up to poll SWF for decisions and activities.

## SampleApp

###[SampleApp::Boot](sample-app/lib/boot.rb)
extends [SWF::Boot](lib/swf/boot.rb), loads settings from the environment (or a chef data bag, or S3, or locally on the worker node, etc), and defines `swf_runner` which calls your Runner, passing any settings.

```ruby
module SampleApp::Boot

  extend SWF::Boot
  extend self

  def swf_runner
    SampleApp::Runner.new(settings)
  end

  def settings
    {
      swf_domain:     ENV["SWF_DOMAIN"],
      s3_bucket:      ENV["S3_BUCKET"],
      s3_path:        ENV["S3_PATH"],
      local_data_dir: ENV["LOCAL_DATA_DIR"]
    }
  end
end
```

###[SampleApp::Runner](sample-app/lib/runner.rb)
subclass of [SWF::Runner](lib/swf/runner.rb), allows you to setup any global settings you want accessible to all workers. Your runner must define `domain_name` and `task_list_name` (probably as methods that parse settings)

```ruby
def domain_name
  settings[:swf_domain]
end

def task_list_name
  [ settings[:s3_bucket], settings[:s3_path] ].join(":")
end
```

You can also redefine `be_worker` or `be_decider` to add before and after hooks:

```ruby
def be_worker
  # we want this to be done before any activity handler
  # reports to SWF it is ready to pick up an activity task
  build_data_index
  super
end

def build_data_index
  # fetch data from s3, build a binary index, etc
  # make sure to wrap in a mutex so multiple workers
  # on the same resource don't override one-another
  ...
end
```

###[SampleApp::SampleWorkflow](sample-app/lib/sample_workflow.rb)
A workflow extends [SWF::Workflow](lib/workflows.rb). It should also define a `self.workflow_type` method that calls `effect_workflow_type` to register the module. This is where you can set default timeouts for the workflow type (see the [aws-sdk docs](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/WorkflowType.html) for all available parameters). Note that if you change one of these defaults, you must increment `WORKFLOW_VERSION`:

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

####Event handling
Your workflow does sequential event handling across a distributed network of deciders - scheduling activities, acting on success/failure, creating child workflows, etc. For a full list of history events, [see the docs](http://docs.aws.amazon.com/sdkfornet/latest/apidocs/html/T_Amazon_SimpleWorkflow_Model_HistoryEvent.htm).

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

#####Multiple activities
TODO

#####Child workflows
There is a one-to-one correspondance between a workflow module and a workflow type on SWF. However, an application may have multiple child workflows that a parent workflow initiates and handles.

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

###[SampleApp::SampleActivity](sample-app/lib/sample_activity.rb)
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

##Running your application

###Launching Workers
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

```shell
$ SWF_DOMAIN=some_domain S3_BUCKET=some_bucket S3_PATH=some_path LOCAL_DATA_DIR=/tmp ruby ./sample-app/bin/swf_run.rb d d w w w
```

TODO
- demonstrate starting workers on multiple physical resources
- demonstrate automating launching EC2 resources, using tags to bootstrap
- demonstrate rescue logging to S3


###Starting a Workflow

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

See [the integration spec](sample-app/spec/integration/sample_workflow_spec.rb) for an end-to-end example.



##Shameless Plug
This project was supported in very large part by change.org. And we are hiring! If you want to come work with us and help empower people to Change the world while working on amazing technology [check out our jobs page](http://www.change.org/hiring).
