require 'swf/task_handler'
require 'set'

module SWF

  # subclass must call .register(), and define #handle(runner, task)
  class ActivityTaskHandler
    extend TaskHandler

    @@handler_classes = Set.new

    attr_reader :runner, :activity_task
    def initialize(runner, task)
      @runner = runner
      @activity_task = task
    end

    def call_handle
      send self.class.handler_method_name(activity_task)
    end

    def activity_task_input
      JSON.parse(activity_task.input)
    end

    # Register statically self (subclass) to handle activities
    def self.register
      @@handler_classes << self
    end

    def self.fail!(task, args={})
      task.fail!(args)
    end

    def self.find_handler_class(task)
      @@handler_classes.find {|x| x.instance_methods.include? handler_method_name task }
      # TODO: detect when two classes define the same named handle_* method ?!?!
    end

    def self.configuration_help_message
      "Each activity task handler running on this task list in this domain must provide a handler class with a handle_* function for this activity_type's name.\n" +
      "I only have these classes: #{@@handler_classes.inspect}"
    end

    def self.handler_method_name(task)
      "handle_#{task.activity_type.name}".to_sym
    end

  end

end
