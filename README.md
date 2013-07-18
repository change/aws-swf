aws-swf
==========

aws-swf is our light framework for developing distributed applications in Ruby to run on [AWS Simple Workflow](http://aws.amazon.com/swf/).

At [change.org](http://www.change.org) we use aws-swf to drive parallelized and distributed processing for machine-learning driven email targeting. SWF provides the plumbing from the socket up to our application, enabling us to focus on innovating in terms of our data science, performance, UX, etc without having to worry about the complexities of message passing and asynchronous task scheduling across a decentralized system. If a worker dies, a task throws an exception, or somebody spills a cup of coffee on a rack of servers at AWS, configurable timeouts at different levels enable our application to be notified of, and choose how to handle, that or most any other issue that tend to pop up when doing massively distributed computing. Additionally by focusing on parallelizable algorithms we can scale the number of computational nodes as demand and data sizes dictate - nothing changes in the application code, we simply spin up more workers to handle the additional load.

While we use aws-swf on EC2, any resource - including your laptop - can be a task runner. This makes integration testing a breeze - you can test the core functionality of your activity task handlers, test the flow control of your decision task handlers, and then actually test end-to-end (against a test domain on SWF) against fixtures from your development box.

For the purposes of this tutorial, we are going to leave dynamic resource allocation and bootstrapping off the table, and just focus on building an application that we can run locally. You can follow along with the example in [sample-app](sample-app/).


App Structure
=========
An aws-swf application has a few basic components:


###[SampleApp::Boot](sample-app/lib/boot.rb)
extends [SWF::Boot](lib/swf/boot.rb), defines `swf_runner` which calls your Runner, passing any settings.

###[SampleApp::Runner](sample-app/lib/runner.rb)
subclass of [SWF::Runner](lib/swf/runner.rb), allows you to setup any global settings you want accessible to all workers. You can also redefine `be_worker` or `be_decider` to add before and after hooks:

```
def be_worker
  # we want this to be done before any activity handler
  # reports to SWF it is ready to pick up an activity task
  build_data_index
  super
end
```

###[SampleApp::SampleWorkflow](sample-app/lib/sample_workflow.rb)
A workflow extends [SWF::Workflow](lib/workflows.rb). It should also define a `self.workflow_type` method that calls `effect_workflow_type` to register the module. This is where you can set default timeouts for the workflow type. Note that if you change one of these defaults, you must increment WORKFLOW_VERSION:

```
def self.workflow_type
  effect_workflow_type(WORKFLOW_TYPE, WORKFLOW_VERSION,
    default_child_policy:                     :request_cancel,
    default_task_start_to_close_timeout:      3600,
    default_execution_start_to_close_timeout: 3600,
  )
end
```
See the [aws-sdk docs](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/WorkflowType.html) for all available parameters.


The workflow module should also have a DecisionTaskHandler inner-class that registers and defines `handle`. This method will be called as new events occur.

```
class DecisionTaskHandler < SWF::DecisionTaskHandler
  register(WORKFLOW_TYPE, WORKFLOW_VERSION)

  def handle
    new_events.each {|e| ... }
  end
end
```

###[SampleApp::SampleActivity](sample-app/lib/sample_activity.rb)

Launching a Workflow
=====================

```
SampleApp::SampleWorkflow.start(
  options,
  execution_start_to_close_timeout: timeout,
)
```

