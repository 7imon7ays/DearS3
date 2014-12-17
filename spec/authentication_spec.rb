require 'spec_helper'

describe DearS3::Cli::S3 do
  context "auth" do
    let(:auth_output) do
      capture(:stdout) { subject.auth }
    end

    it 'Confirms with the user before overriding an existing credentials file' do
      File.any_instance.stub(exists?: true)
      Thor::Shell::Basic.any_instance.stub(ask: 'y')
      auth_output.should include "Override existing '.aws.json'?"
      auth_output.should include "Please enter your AWS access key id:"
      auth_output.should include "Please enter your AWS secret access key:"
    end
  end
end

