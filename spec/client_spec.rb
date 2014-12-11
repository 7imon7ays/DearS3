require 'spec_helper'

describe DearS3::Cli::S3 do
  context "publishing" do
    let(:output_after_publish) { capture(:stdout) { subject.publish } }

    it 'prompts user for index and error document before publishing' do
      Thor::Shell::Basic.any_instance.stub(ask: 'foobar')
      output_after_publish.should include "Files currently in your bucket"
    end
  end
end

