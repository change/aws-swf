require 'aws-swf'

module SampleApp
  class Runner < SWF::Runner

    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end

    def be_worker
      before_work # <picard> make it so! </picard>
      super
    end

    def before_work; end

    def s3_bucket
      AWS::S3.new.buckets[settings[:s3_bucket]]
    end

    def s3_path
      settings[:s3_path]
    end

  end
end
