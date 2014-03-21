require 'spec_helper'

describe Statistrano::Deployment::Registerable do

  describe "::register_strategy" do
    it "calls register strategy on Deployment" do
      class Foo; end
      expect( Statistrano::Deployment::Strategy ).to receive(:register)
                                       .with( Foo, :foo )

      class Foo
        extend Statistrano::Deployment::Registerable

        register_strategy :foo
      end
    end
  end

end