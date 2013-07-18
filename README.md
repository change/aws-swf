aws-swf
==========

aws-swf is our light framework for developing distributed applications in Ruby to run on [AWS Simple Workflow](http://aws.amazon.com/swf/).

At [change.org](http://www.change.org) we use aws-swf to drive parallelized and distributed processing for machine-learning driven email targeting. A [Sinatra](http://www.sinatrarb.com/) API service receives requests from email campaigners, dynamically spins up resources on EC2, and submits the initial workflow execution to SWF. The EC2 resources bootstrap themselves, copy the data they need from S3, and then begin "listening" on specific SWF tasklists. The initial parent workflow spawns training tasks (in this case, the Ruby activity task then calls out to Python running [scikit-learn](https://github.com/scikit-learn/scikit-learn)), and as they succeed, the subsequent predictions and analysis against the generated models are kicked off in parallelized chunks against the distributed workers. SWF provides the plumbing from the socket up to our application, enabling us to focus on innovating in terms of our data science, performance, UX, etc and to not have to worry about the complexities of message passing across a decentralized system. If a worker dies, a task throws an exception, or somebody spills a cup of coffee on a rack of servers at AWS, configurable timeouts at different levels enable our application to be notified of, and choose how to handle, any of the myriad of problems that tend to pop up when doing massively distributed computing.

While we use aws-swf on EC2, any resource - including your laptop - can be a task runner. This makes integration testing a breeze - you can test the core functionality of your activity task handlers, test the flow control of your decision task handlers, and then actually test end-to-end (against a test domain on SWF) against fixtures from your development box.

For the purposes of this tutorial, we are going to leave the dynamic resource allocation and bootstrapping off the table, and just focus on building an application that we can run locally. You can follow along with the example in [sample-app](sample-app/).


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
A workflow extends [SWF::Workflow](lib/workflows.rb). It should also define a `self.workflow_type` method that calls `effect_workflow_type` to register the module:

```
def self.workflow_type
  effect_workflow_type(WORKFLOW_TYPE, WORKFLOW_VERSION,
    default_child_policy:                     :request_cancel,
    default_task_start_to_close_timeout:      3600,
    default_execution_start_to_close_timeout: 3600,
  )
end
```

The workflow module should also have a DecisionTaskHandler inner-class that registers and defines `handle`:

```
class DecisionTaskHandler < SWF::DecisionTaskHandler
  register(WORKFLOW_TYPE, WORKFLOW_VERSION)

  def handle
    new_events.map {|e| ... }
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

