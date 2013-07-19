require 'aws-swf'

module SampleActivity

  # this tells SWF what activity types this module can handle
  def self.activity_type_sample_activity(runner)
    runner.effect_activity_type('sample_activity', '1',
      default_task_heartbeat_timeout:             3600,
      default_task_schedule_to_start_timeout:     3600,
      default_task_schedule_to_close_timeout:     7200,
      default_task_start_to_close_timeout:        3600
    )
  end

  # a single module can handle many activity types
  def self.activity_type_lorem_activity(runner)
     runner.effect_activity_type('other_activity', '1',
      default_task_heartbeat_timeout:             3600,
      default_task_schedule_to_start_timeout:     3600,
      default_task_schedule_to_close_timeout:     7200,
      default_task_start_to_close_timeout:        3600
    )
  end

  class ActivityTaskHandler < SWF::ActivityTaskHandler
    register

    # this method "magically" gets called when an activity of type ("sample_activity", 1) is scheduled
    def handle_sample_activity
      # do some computation, store results to s3, etc.
      runner.s3_bucket.objects[runner.s3_path].write(
        {
          input_param: activity_task_input["input_param"],
          decision_param: activity_task_input["decision_param"],
          activity_param: "activity"
        }.to_json
      )
    end

    # likewise for ("other_activity", "1")
    def handle_other_activity; end

  end
end