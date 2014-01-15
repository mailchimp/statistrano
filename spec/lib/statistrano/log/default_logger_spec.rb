require 'spec_helper'

describe Statistrano::Log::DefaultLogger do

  before :each do
    formatter_double = instance_double "Statistrano::Log::DefaultLogger::Formatter",
                                        output: "stubbed"
    Formatter = Statistrano::Log::DefaultLogger::Formatter unless defined?(Formatter)
    allow( Formatter ).to receive(:new)
                      .and_return( formatter_double )
  end

  describe "#info [& debug]" do
    it "outputs to stdout" do
      expect( $stdout ).to receive(:puts)
      subject.info 'foo'
    end

    it "defaults to a blank status" do
      expect( Formatter ).to receive(:new)
                         .with( '', :bright, 'msg' )

      subject.info 'msg'
    end

    it "uses a status if given one" do
      expect( Formatter ).to receive(:new)
                         .with( :status, :bright, 'msg' )

      subject.info :status, 'msg'
    end

    it "colorizes green if given :success as status" do
      expect( Formatter ).to receive(:new)
                         .with( :success, :green, 'msg' )

      subject.info :success, 'msg'
    end

    it "takes multiple lines of messages" do
      expect( Formatter ).to receive(:new)
                         .with( '', :bright, 'msg', 'msg2' )

      subject.info 'msg', 'msg2'
    end
  end

  describe "#warn" do
    it "outputs to stdout" do
      expect( $stdout ).to receive(:puts)
      subject.warn 'foo'
    end

    it "defaults to 'warning' status" do
      expect( Formatter ).to receive(:new)
                         .with( 'warning', :yellow, 'msg' )

      subject.warn 'msg'
    end

    it "allows status to be overriden" do
      expect( Formatter ).to receive(:new)
                         .with( :omg, :yellow, 'msg' )

      subject.warn :omg, 'msg'
    end

    it "colorizes yellow" do
      expect( Formatter ).to receive(:new)
                         .with( 'warning', :yellow, 'msg' )

      subject.warn 'msg'
    end

    it "takes multiple lines of messages" do
      expect( Formatter ).to receive(:new)
                         .with( 'warning', :yellow, 'msg', 'msg2' )

      subject.warn 'msg', 'msg2'
    end
  end

  describe "#error [& fatal]" do
    it "outputs to stderr" do
      expect( $stderr ).to receive(:puts)
      subject.error 'foo'
    end

    it "defaults to 'error' status" do
      expect( Formatter ).to receive(:new)
                         .with( 'error', :red, 'msg' )

      subject.error 'msg'
    end

    it "colorizes red" do
      expect( Formatter ).to receive(:new)
                         .with( 'error', :red, 'msg' )

      subject.error 'msg'
    end

    it "takes multiple lines of messages" do
      expect( Formatter ).to receive(:new)
                         .with( 'error', :red, 'msg', 'msg2' )

      subject.error 'msg', 'msg2'
    end
  end

end

describe Statistrano::Log::DefaultLogger::Formatter do

  describe "#initialize" do
    it "sets status as a string" do
      expect( described_class.new( :status, '', '' ).status ).to eq 'status'
    end

    it "sets the given color" do
      expect( described_class.new( '', 'color', '' ).color ).to eq 'color'
    end

    it "sets msgs" do
      expect( described_class.new( '', '', 'msg', 'msg2' ).msgs ).to match_array ['msg','msg2']
    end
  end

  describe "#output" do
    it "pads messages" do
      subject = described_class.new( '', :green, 'msg' )
      expect( subject.output ).to match /->\s{12}msg/
    end

    it "pads multiple lined messages" do
      subject = described_class.new( '', :green, 'msg', 'msg2' )
      lines = subject.output.split("\n")

      expect( lines.first ).to match /->\s{12}msg/
      expect( lines.last  ).to match /\s{14}msg2/
    end

    it "colorizes status with given color" do
      Rainbow.enabled = true

      rainbow_double = double
      subject = described_class.new( 'status', :green, 'msg' )
      allow( Rainbow::Presenter ).to receive(:new)
                                 .and_call_original
      allow( Rainbow::Presenter ).to receive(:new)
                                 .with('status')
                                 .and_return(rainbow_double)

      expect( rainbow_double ).to receive(:green)
                              .and_return('green')
      subject.output

      unless ENV['RAINBOW']
        Rainbow.enabled = false
      end
    end
  end

end