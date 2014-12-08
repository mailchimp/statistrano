require 'spec_helper'

describe "Statistrano::Deployment::Strategy::Releases#deploy integration", :integration do

  context "with a single target" do
    before :each do
      reenable_rake_tasks
      Given.fixture "base"
      @subject = define_deployment "single_target", :releases do
        build_task "remote:copy"
        local_dir  "build"
        remote_dir File.join( Dir.pwd, "deployment" )

        release_count 2
        remotes [{ hostname: 'localhost', verbose: true }]
      end

      allow( Time ).to receive(:now).and_return(1372020000)
      @subject.deploy

      allow( Time ).to receive(:now).and_return(1372030000)
      @subject.deploy

      allow( Time ).to receive(:now).and_return(1372040000)
      @subject.deploy
    end

    after :each do
      Given.cleanup!
    end

    it "generates a release with the correct time stamp,\n" +
       "restricts the release count to the defined number,\n" +
       "& symlinks the pub_dir to the most recent release" do
      expect( release_folder_contents ).to match_array ["1372030000", "1372040000"]
      expect( release_folder_contents.length ).to eq 2
      resp = Statistrano::Shell.run_local("ls -l deployment")
      expect( resp.stdout ).to match /current\s->(.+)\/deployment\/releases\/1372040000/
    end

    context "when pre_symlink_task fails" do
      it "leaves the release inplace, but unlinked" do
        @subject = define_deployment "single_target", :releases do
          build_task "remote:copy"
          local_dir  "build"
          remote_dir File.join( Dir.pwd, "deployment" )

          release_count 2
          remotes [{ hostname: 'localhost', verbose: true }]
          pre_symlink_task do
            false
          end
        end

        allow( Time ).to receive(:now).and_return(1372050000)

        expect {
          @subject.deploy
        }.to raise_error SystemExit

        expect( release_folder_contents ).to match_array ["1372030000", "1372040000", "1372050000"]
        resp = Statistrano::Shell.run_local("ls -l deployment")
        expect( resp.stdout ).to match /current\s->(.+)\/deployment\/releases\/1372040000/
      end
    end
  end

  context "with multiple remotes" do

    before :each do
      reenable_rake_tasks
      Given.fixture "base"
      subject = define_deployment "multi_target", :releases do
        build_task "remote:copy"
        local_dir  "build"
        hostname   "localhost"
        remote_dir File.join( Dir.pwd, "deployment" )

        release_count 2
        remotes [
          { remote_dir: File.join( Dir.pwd, "deployment", "target01" ) },
          { remote_dir: File.join( Dir.pwd, "deployment", "target02" ) },
          { remote_dir: File.join( Dir.pwd, "deployment", "target03" ) }
        ]
      end

      allow( Time ).to receive(:now).and_return(1372020000)
      subject.deploy

      allow( Time ).to receive(:now).and_return(1372030000)
      subject.deploy

      allow( Time ).to receive(:now).and_return(1372040000)
      subject.deploy
    end

    after :each do
      Given.cleanup!
    end

    it "generates a release with the correct time stamp,\n" +
       "restricts the release count to the defined number,\n" +
       "& symlinks the pub_dir to the most recent release" do
      expect( multi_release_folder_contents )
        .to match_array [ "target01/releases/1372030000", "target01/releases/1372040000",
                          "target02/releases/1372030000", "target02/releases/1372040000",
                          "target03/releases/1372030000", "target03/releases/1372040000" ]

      ["target01","target02","target03"].each do |target|
        resp = Statistrano::Shell.run_local("ls -l deployment/#{target}")
        expect( resp.stdout ).to match /current\s->(.+)\/deployment\/#{target}\/releases\/1372040000/
      end
    end
  end

end
