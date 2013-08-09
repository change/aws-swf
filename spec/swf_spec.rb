require './lib/swf/swf'

describe SWF do

  describe '.swf' do
    before do
      SWF.instance_variable_set(:@swf, nil)
    end
    it 'creates a new AWS::SimpleWorkflow object if @swf is not defined' do
      AWS::SimpleWorkflow.should_receive(:new)
      SWF.swf
    end
  end

  context "domain" do
    after(:each) do
      SWF.instance_variable_set(:@domain_name, nil)
    end

    describe '.domain_name' do
      it "returns @domain_name if set" do
        SWF.instance_variable_set(:@domain_name, 'domain')
        SWF.domain_name.should == 'domain'
      end

      it "throws UndefinedDomainName if @domain_name is not set" do
        ->{ SWF.domain_name }.should raise_exception(SWF::UndefinedDomainName)
      end
    end

    describe '.domain_name=' do
      it "sets @domain_name" do
        SWF.domain_name = 'domain'
        SWF.instance_variable_get(:@domain_name).should == 'domain'
      end
    end

    describe '.domain' do
      let(:domain_object) { double(:domain, exists?: true) }
      before do

        domains = { 'domain' => domain_object }
        SWF.stub(:swf) {
          double(:swf,
            domains: double(:domains).tap{|d| d.stub(:[]) {|arg| domains[arg] || double(:domain, exists?: false) } }
          )
        }
      end

      it 'returns the SWF domain object if domain_name exists as a SWF domain' do
        SWF.stub(:domain_name) { 'domain' }
        SWF.domain.should == domain_object
      end
      it 'throws UnknownSWFDomain if domain_name exists as a SWF domain' do
        SWF.stub(:domain_name) { 'foobar' }
        ->{ SWF.domain }.should raise_exception(SWF::UnknownSWFDomain)
      end
    end

    describe '.task_list' do
      after(:each) do
        SWF.instance_variable_set(:@task_list, nil)
      end
      it "returns @task_list if set" do
        SWF.instance_variable_set(:@task_list, 'task_list')
        SWF.task_list.should == 'task_list'
      end
      it "throws UndefinedTaskList if @task_list not set" do
        ->{ SWF.task_list }.should raise_exception(SWF::UndefinedTaskList)
      end
    end

    describe '.task_list=' do
     it "sets @task_list" do
        SWF.task_list = 'task_list'
        SWF.instance_variable_get(:@task_list).should == 'task_list'
      end
    end
  end

end
