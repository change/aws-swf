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

  end
end
