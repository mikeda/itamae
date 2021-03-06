require 'spec_helper'
require 'fakefs/spec_helpers'

module Itamae
  module Backend
    describe Base do
      include FakeFS::SpecHelpers

      class Klass < Itamae::Backend::Base
        def initialize(_)
          @backend = Object.new
          @backend.stub(:send_file)
          @backend.stub(:send_directory)
        end
      end

      describe ".send_file" do
        context "the source file doesn't exist" do
          subject { -> { Klass.new("dummy").send_file("src", "dst") } }
          it { expect(subject).to raise_error(Itamae::Backend::SourceNotExistError, "The file 'src' doesn't exist.") }
        end

        context "the source file exist, but it is not a regular file" do
          before { Dir.mkdir("src")  }
          subject { -> { Klass.new("dummy").send_file("src", "dst") } }
          it { expect(subject).to raise_error(Itamae::Backend::SourceNotExistError, "'src' is not a file.") }
        end

        context "the source file is a regular file" do
          before { FileUtils.touch("src")  }
          subject { -> { Klass.new("dummy").send_file("src", "dst") } }
          it { expect { subject }.not_to raise_error }
        end
      end

      describe ".send_directory" do
        context "the source directory doesn't exist" do
          subject { -> { Klass.new("dummy").send_directory("src", "dst") } }
          it { expect(subject).to raise_error(Itamae::Backend::SourceNotExistError, "The directory 'src' doesn't exist.") }
        end

        context "the source directory exist, but it is not a directory" do
          before { FileUtils.touch("src")  }
          subject { -> { Klass.new("dummy").send_directory("src", "dst") } }
          it { expect(subject).to raise_error(Itamae::Backend::SourceNotExistError, "'src' is not a directory.") }
        end

        context "the source directory is a directory" do
          before { Dir.mkdir("src")  }
          subject { -> { Klass.new("dummy").send_directory("src", "dst") } }
          it { expect { subject }.not_to raise_error }
        end
      end
    end

    describe Ssh do

      describe "#ssh_options" do
        subject { ssh.send(:ssh_options) }

        let!(:ssh) { described_class.new(options) }
        let!(:host_name) { "example.com" }
        let!(:default_option) do
          opts = {}
          opts[:host_name] = nil
          opts.merge!(Net::SSH::Config.for(host_name))
          opts[:user] = opts[:user] || Etc.getlogin
          opts
        end

        context "with host option" do
          let(:options) { {host: host_name} }
          it { is_expected.to eq( default_option.merge({host_name: host_name}) ) }
        end
      end

      describe "#disable_sudo?" do
        subject { ssh.send(:disable_sudo?) }

        let!(:ssh) { described_class.new(options)}

        context "when sudo option is true" do
          let(:options) { {sudo: true} }
          it { is_expected.to eq(false) }
        end

        context "when sudo option is false" do
          let(:options) { {sudo: false} }
          it { is_expected.to eq(true) }
        end
      end
    end
  end
end
