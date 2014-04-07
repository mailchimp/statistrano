require 'spec_helper'

describe Statistrano::Deployment::Manifest do

  describe "#initialize" do
    it "stores the provided remote_dir & remote" do
      remote     = :remote
      remote_dir = :remote_dir
      subject = described_class.new( remote_dir, remote )

      expect( subject.remote_dir ).to eq remote_dir
      expect( subject.remote ).to eq remote
    end
  end

  describe "#data" do
    it "returns serialized data from remote" do
      remote  = instance_double("Statistrano::Remote")
      subject = described_class.new '/var/www/proj', remote
      expect( remote ).to receive(:run)
                      .with('cat /var/www/proj/manifest.json')
                      .and_return( HereOrThere::Response.new('[{"key":"val"}]','',true))

      expect( subject.data ).to match_array [{ key: 'val' }]
    end

    it "returns empty array if manifest file is missing" do
      remote  = instance_double("Statistrano::Remote")
      subject = described_class.new '/var/www/proj', remote
      expect( remote ).to receive(:run)
                      .with('cat /var/www/proj/manifest.json')
                      .and_return( HereOrThere::Response.new("","cat: /var/www/proj/manifest.json: No such file or directory\n",false))

      expect( subject.data ).to match_array []
    end

    it "logs error when manifest contains invalid JSON" do
      config  = double("Statistrano::Config", hostname: 'web01')
      remote  = instance_double("Statistrano::Remote", config: config )
      subject = described_class.new '/var/www/proj', remote
      expect( remote ).to receive(:run)
                      .with('cat /var/www/proj/manifest.json')
                      .and_return( HereOrThere::Response.new("invalid","",true))
      expect( Statistrano::Log ).to receive(:error)
      subject.data
    end

    it "returns @_data if set" do
      remote  = instance_double("Statistrano::Remote")
      subject = described_class.new '/var/www/proj', remote

      subject.instance_variable_set(:@_data, 'data')
      expect( subject.data ).to eq 'data'
    end

    it "sets @_data with return" do
      remote  = instance_double("Statistrano::Remote")
      subject = described_class.new '/var/www/proj', remote
      allow( remote ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )

      data = subject.data
      expect( subject.instance_variable_get(:@_data) ).to eq data
    end
  end

  describe "#push" do
    it "adds data to the data array" do
      remote  = instance_double("Statistrano::Remote")
      allow( remote ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', remote

      new_data = {foo: 'bar'}
      subject.push new_data
      expect( subject.data ).to include new_data
    end

    it "symbolizes keys in passed data" do
      remote  = instance_double("Statistrano::Remote")
      allow( remote ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', remote

      new_data = {"foo" => 'bar'}
      subject.push new_data
      expect( subject.data ).to include foo: 'bar'
    end

    it "raises error if provided data cannot be converted to JSON" do
      remote  = instance_double("Statistrano::Remote")
      allow( remote ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', remote

      data = double
      expect( data ).to receive(:respond_to?)
                    .with(:to_json).and_return(false)

      expect{
        subject.push data
      }.to raise_error ArgumentError, "data must be serializable as JSON"
    end
  end

  describe "#put" do
    # a "safer" version of `push`, will update a
    # data_glob in place matched on key
    let(:remote) { instance_double("Statistrano::Remote") }

    context "when item doesn't exist" do
      it "adds the item w/o disturbing existing data" do
        subject = described_class.new "remote_dir", remote
        allow( remote ).to receive(:run)
                       .and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )

        subject.put( { foo: "bar" }, :foo )
        expect( subject.data ).to match_array [{key: "val"},{foo: "bar"}]
      end
    end

    context "when item does exist" do
      it "updates the item w/o distrubing existing data" do
        subject = described_class.new "remote_dir", remote
        allow( remote ).to receive(:run)
                       .and_return( HereOrThere::Response.new('[{"key":"val"},{"key":"foo","marker":"orig"}]','',true) )

        subject.put( {key:"foo",marker:"new"}, :key )
        expect( subject.data ).to match_array [{key: "val"},{key:"foo",marker:"new"}]
      end
    end
  end

  describe "#remove_if" do
    it "removes data that matches the condition" do
      remote  = instance_double("Statistrano::Remote")
      allow( remote ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', remote

      subject.remove_if { |item| item.has_key?(:key) }
      expect( subject.data ).to match_array []
    end
    it "retains data that doesn't match condition" do
      remote  = instance_double("Statistrano::Remote")
      allow( remote ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', remote

      subject.remove_if { |item| !item.has_key?(:key) }
      expect( subject.data ).to match_array [{key:"val"}]
    end
  end

  describe "#save!" do
    it "tests if file exists" do
      config  = double("Statistrano::Config", hostname: 'web01')
      remote  = instance_double("Statistrano::Remote", config: config )
      allow( remote ).to receive(:run)
                     .and_return( HereOrThere::Response.new("",'',true) )
      subject = described_class.new '/var/www/proj', remote

      expect( remote ).to receive(:run)
                      .with("[ -f /var/www/proj/manifest.json ] && echo \"exists\"")
                      .and_return( HereOrThere::Response.new("exists\n",'',true) )
      subject.save!
    end

    context "when manifest didn't previously exist" do
      it "creates manifest" do
        config  = double("Statistrano::Config", hostname: 'web01')
        remote  = instance_double("Statistrano::Remote", config: config )
        allow( remote ).to receive(:run)
                       .and_return( HereOrThere::Response.new("",'',true) )
        subject = described_class.new '/var/www/proj', remote

        expect( remote ).to receive(:run)
                        .with("[ -f /var/www/proj/manifest.json ] && echo \"exists\"")
                        .and_return( HereOrThere::Response.new('','',true) )
        expect( remote ).to receive(:run)
                        .with("touch /var/www/proj/manifest.json " +
                              "&& chmod 770 /var/www/proj/manifest.json")
                        .and_return( HereOrThere::Response.new("",'',true) )
        subject.save!
      end
    end

    context "when manifest exists" do
      it "doesn't touch & chmod file" do
        config  = double("Statistrano::Config", hostname: 'web01')
        remote  = instance_double("Statistrano::Remote", config: config )
        allow( remote ).to receive(:run)
                       .and_return( HereOrThere::Response.new("",'',true) )
        subject = described_class.new '/var/www/proj', remote

        expect( remote ).to receive(:run)
                        .with("[ -f /var/www/proj/manifest.json ] && echo \"exists\"")
                        .and_return( HereOrThere::Response.new("exists\n",'',true) )
        expect( remote ).not_to receive(:run)
                        .with("touch /var/www/proj/manifest.json " +
                              "&& chmod 770 /var/www/proj/manifest.json")
        subject.save!
      end
    end

    it "writes serialized data to remote_path" do
      config  = double("Statistrano::Config", hostname: 'web01')
      remote  = instance_double("Statistrano::Remote", config: config )
      allow( remote ).to receive(:run)
                     .with("cat /var/www/proj/manifest.json")
                     .and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      allow( remote ).to receive(:run)
                     .with("[ -f /var/www/proj/manifest.json ] && echo \"exists\"")
                     .and_return( HereOrThere::Response.new("exists\n",'',true) )
      subject = described_class.new '/var/www/proj', remote

      expect( remote ).to receive(:run)
                      .with( "echo '[{\"key\":\"val\"}]' > /var/www/proj/manifest.json" )
                      .and_return( HereOrThere::Response.new('','',true) )

      subject.save!
    end

    it "logs error if fails" do
      config  = double("Statistrano::Config", hostname: 'web01')
      remote  = instance_double("Statistrano::Remote", config: config )
      allow( remote ).to receive(:run)
                     .with("cat /var/www/proj/manifest.json")
                     .and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      allow( remote ).to receive(:run)
                     .with("[ -f /var/www/proj/manifest.json ] && echo \"exists\"")
                     .and_return( HereOrThere::Response.new("exists\n",'',true) )
      subject = described_class.new '/var/www/proj', remote

      expect( remote ).to receive(:run)
                      .with( "echo '[{\"key\":\"val\"}]' > /var/www/proj/manifest.json" )
                      .and_return( HereOrThere::Response.new('','couldnt do it',false) )

      expect( Statistrano::Log ).to receive(:error)
      subject.save!
    end
  end

end