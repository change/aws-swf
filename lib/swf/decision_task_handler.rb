require 'swf/task_handler'

module SWF

  class MissingWorkflowStartedEvent < StandardError; end

  # subclass must call .register(name, version), and define #handle(runner, task)
  class DecisionTaskHandler
    extend TaskHandler

    @@handler_classes_by_name_version = {}

    # Register statically self (subclass) to handle workflow_type with given name and version
    def self.register name, version
      @@handler_classes_by_name_version [ [name.to_s, version.to_s] ] = self
    end

    def self.fail! task, args={}
      task.fail_workflow_execution args
    end

    def self.find_handler_class task
      type = task.workflow_type
      @@handler_classes_by_name_version[ [type.name, type.version] ]
    end

    def self.configuration_help_message
      "Each decision task handler running on this task list in this domain must know how to handle this workflow_type's name and version.\n" +
      "I only know: #{@@handler_classes_by_name_version.inspect}"
    end

    attr_reader :runner, :decision_task

    def initialize(runner, decision_task)
      @runner = runner
      @decision_task = decision_task
    end

    def call_handle
      handle
    end

    def events
      # make events into an array to avoid token timeout issues
      # see https://forums.aws.amazon.com/thread.jspa?threadID=98925
      @events ||= decision_task.events.to_a
    end

    def new_events
      enum_for(:_new_events)
    end

    def _new_events &block
      events.each {|e|
        yield(e) if e.new?
      }
    end

    def workflow_started_event
      @workflow_started_event ||= begin
        events.find {|e| e.event_type == 'WorkflowExecutionStarted' } or raise MissingWorkflowStartedEvent, "Missing WorkflowExecutionStarted event in #{runner}"
      end
    end

    def workflow_task_list
      @workflow_task_list ||= workflow_started_event.attributes.task_list
    end

    def workflow_input
      @workflow_input ||= JSON.parse(workflow_started_event.attributes.input)
    end

    def event_input(event)
      JSON.parse(event.attributes.input)
    end

  end

end
