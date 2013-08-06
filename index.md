---
layout: page
title: aws-swf
tagline: distributed ruby on aws
---
{% include JB/setup %}

aws-swf is our light framework for developing distributed applications in Ruby to run on [AWS Simple Workflow](http://aws.amazon.com/swf/).

### Installation
aws-swf is hosted on [Rubygems](https://rubygems.org/gems/aws-swf)

Simply add the following to your `Gemfile`:

```ruby
gem 'aws-swf'
```

Also take a look through our [quickstart tutorial](/aws-swf/pages/quickstart/)

<br>

### Background
#### What is this all about?
At [change.org](http://www.change.org) we use aws-swf to drive parallelized and distributed processing for machine-learning driven email targeting. SWF provides the plumbing from the socket up to our application, enabling us to focus on innovating in terms of our data science, performance, UX, etc without having to worry about the complexities of message passing and asynchronous task scheduling across a decentralized system. If a worker dies, a task throws an exception, or somebody spills a cup of coffee on a rack of servers at AWS, configurable timeouts at different levels enable our workflow to be notified of the problem and decide how to handle it. Additionally by focusing on parallelizable algorithms we can scale the number of computational nodes as demand and data sizes dictate - nothing changes in the application code, we simply spin up more workers to handle the additional load.

#### What is Simple Workflow?
SWF allows you to define activities (units of work to be performed) and workflows (decision/flow-control logic that schedules activities based on dependencies, handles failures, etc). You register both under a SWF domain, and can then poll that domain for a given tasklist from any resource (EC2, metal, or other cloud). AWS serves as a centralized place to poll for your distributed deciders and workers - handling message coordination and ensuring decision tasks are processed sequentially. Your decider workflows schedule (often massively parallel) activities, await for success/failure, and then act accordingly. New deciders and activity workers can be brought up and down on demand, and with a small amount of care to handling timeouts and failures, your distributed application can be made incredibly robust and resilient to intermittent failures and network connectivity issues, as well as easily adaptable to different data-scales and time-constraints. Look through the [Introduction to Amazon Simple Workflow Service](http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-intro-to-swf.html) docs for more information. For more detailed reading on workflow patterns, havea look at [the Workflow Patterns initiative](http://www.workflowpatterns.com/).

#### TDD-Ready, Metal-to-cloud
While we use aws-swf on EC2, any resource - including your laptop - can be a task runner. This makes integration testing a breeze - you can unit test the core functionality of your activity task handlers, test the flow control of your decision task handlers, and then actually test end-to-end (against a test domain on SWF) against fixtures from your development box. It is also handy for R&D, if you want to iterate more quickly on a 24-core metal machine (running 24 activity workers, taking advantage of local filesystem speeds), before moving to EC2 and spreading those 24 workers across 12 dual-core instances.

<br>


### License
This project is licensed under [the MIT license](https://github.com/change/aws-swf/blob/master/LICENSE)

<br>

### Shameless Plug
This project was supported in very large part by change.org. And we are hiring! If you want to come work with us and help empower people to Change the world while working on amazing technology [check out our jobs page](http://www.change.org/hiring).



