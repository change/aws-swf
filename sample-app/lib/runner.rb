require 'aws-swf'

require './lib/sample_workflow'
require './lib/sample_activity'


module SampleApp
  class Runner < SWF::Runner

    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end

    # REQUIRED METHODS
    def domain_name
      settings[:swf_domain]
    end

    def task_list_name
      [ settings[:s3_bucket], settings[:s3_path] ].join(":")
    end



    # AVAILABLE FOR OVERRIDE
    #def be_decider; end

    def be_worker
      before_work
      super
    end

    def before_work; end


    # HELPER METHODS, ETC
    def s3_bucket
      AWS::S3.new.buckets[settings[:s3_bucket]]
    end

    def s3_path
      settings[:s3_path]
    end

  end
end
