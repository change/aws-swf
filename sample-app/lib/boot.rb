require 'aws-swf'
require './lib/runner'

module SampleApp; end

module SampleApp::Boot

  extend SWF::Boot
  extend self

  def swf_runner
    SampleApp::Runner.new(settings)
  end

  def settings
    {
      swf_domain:     ENV["SWF_DOMAIN"],
      s3_bucket:      ENV["S3_BUCKET"],
      s3_path:        ENV["S3_PATH"],
      local_data_dir: ENV["LOCAL_DATA_DIR"]
    }
  end
end
