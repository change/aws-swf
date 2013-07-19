require './lib/sample_activity'

describe SampleActivity do
  let(:test_run_identifier) { "spec-aws-swf/%08x-%08x" % [Time.now.to_i, rand(0xFFFFFFFF)] }
  let(:settings) {
    {
      swf_domain:     'aws-swf-test',
      s3_bucket:      'aws-swf-test',
      s3_path:        test_run_identifier,
      local_data_dir: '/tmp'
    }
  }

  # we stub runner.s3_bucket.objects[test_run_identifier] to return our s3_object double
  let(:s3_object) { double(:s3_object) }
  let(:s3_bucket) {
    double(:s3_bucket,
      objects: double(:s3_objects).tap {|s3_objects|
        s3_objects.stub(:[]).with(test_run_identifier) { s3_object }
      }
    )
  }
  let(:runner){
    double(:runner,
      settings: settings,
      s3_bucket: s3_bucket,
      s3_path: test_run_identifier
    )
  }

  let(:task_list){ 'lorem_task_list' }


  describe SampleActivity::ActivityTaskHandler do
    let(:activity_type){ double(:activity_type, name: 'sample_activity', version: '1') }

    let(:activity_input) {
      {
        "input_param" => "input",
        "decision_param" => "decision"
      }
    }
    let(:activity_task) {
      double(:task,
        activity_type: activity_type,
        input: activity_input.to_json,
        local_data_dir: '/tmp'
      )
    }

    let(:handler) { SampleActivity::ActivityTaskHandler.new(runner, activity_task) }

    describe '#handle_sample_activity' do
      it "returns the params" do
        s3_object.should_receive(:write).with(activity_input.merge({activity_param: "activity"}).to_json)
        handler.send(:handle_sample_activity)
      end
    end
  end
end
