require 'swf'

module SWF

  class Runner

    attr_reader :domain_name, :task_list_name

    def initialize(domain_name, task_list_name)
      @domain_name    = domain_name
      @task_list_name = task_list_name
    end

    def be_decider
      domain.decision_tasks.poll(task_list) {|decision_task|
        DecisionTaskHandler.handle(self, decision_task)
      }
    end

    def be_worker
      domain.activity_tasks.poll(task_list) {|activity_task|
        ActivityTaskHandler.handle(self, activity_task)
      }
    end

    # these are static for workflow executions
    # so no need to refetch per decision_task
    def tag_lists
      @tag_lists ||= {}
    end

    def domain
      @domain ||= begin
        SWF.domain_name = domain_name
        SWF.domain
      end
    end

    def task_list
      @task_list ||= begin
        SWF.task_list = task_list_name
      end
    end


    def effect_activity_type(name, version, options={})
      @activity_types ||= {}
      @activity_types[[name, version]] ||= domain.activity_types.find {|t| [t.name, t.version] == [name, version] }
      @activity_types[[name, version]] ||= domain.activity_types.create(name, version, options)
    end

  end
end
