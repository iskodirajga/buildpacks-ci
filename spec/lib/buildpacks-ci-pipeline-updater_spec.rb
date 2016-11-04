# encoding: utf-8
require 'yaml'
require 'json'
require 'spec_helper'
require_relative '../../lib/buildpacks-ci-pipeline-updater'

describe BuildpacksCIPipelineUpdater do
  describe '#parse_args' do

    subject { described_class.new.parse_args(args) }

    context 'with --include specified' do
      let(:args) { %w(--include target_string) }

      it 'sets the include option correctly' do
        expect(subject[:include]).to eq('target_string')
      end
    end

    context 'with --exclude specified' do
      let(:args) { %w(--exclude bad_string) }

      it 'sets the exclude option correctly' do
        expect(subject[:exclude]).to eq('bad_string')
      end
    end

    context 'with --template specified' do
      let(:args) { %w(--template template_name) }
      let(:cmd)  { "" }

      it 'sets the template option correctly' do
        expect(subject[:template]).to eq('template_name')
      end
    end
  end

  describe '#set_pipeline' do
    let(:target_name)                    { 'concourse-target' }
    let(:cmd)                            { "" }
    let(:pipeline_variable_filename)     { "" }
    let(:buildpacks_ci_pipeline_updater) { described_class.new }

    subject do
      buildpacks_ci_pipeline_updater
        .set_pipeline(target_name: target_name,
                      name: pipeline_name,
                      cmd: cmd,
                      options: options,
                      pipeline_variable_filename: pipeline_variable_filename
                     )
    end

    describe 'input validation' do
      context "'--include' specified, pipeline name does not match" do
        let(:options)       { { include: 'target' } }
        let(:pipeline_name) { 'other-pipeline' }

        it 'returns without executing fly set-pipeline' do
          expect(buildpacks_ci_pipeline_updater).to_not receive(:system)
          subject
        end
      end

      context "'--exclude' specified, pipeline name matches the exclusion" do
        let(:options)       { { exclude: 'bad' } }
        let(:pipeline_name) { 'bad-pipeline' }

        it 'returns without executing fly set-pipeline' do
          expect(buildpacks_ci_pipeline_updater).to_not receive(:system)
          subject
        end
      end
    end

    describe 'building the fly command' do
      let(:target_name) { 'concourse-target' }
      let(:cmd)  { "erb this" }
      let(:options)       { { } }
      let(:pipeline_name) { 'our-pipeline' }
      let(:lpass_credential_files) { {
        lpass_concourse_private: 'private.yml',
        lpass_deployments_buildpacks: 'deployments.yml',
        lpass_repos_private_keys: 'keys.yml',
        lpass_bosh_release_private_keys: 'bosh.yml'
      } }

      before do
        allow(buildpacks_ci_pipeline_updater).to receive(:puts)
        allow(buildpacks_ci_pipeline_updater).to receive(:credential_filenames).and_return(lpass_credential_files)
      end

      it 'has a pipeline name' do
        expect(buildpacks_ci_pipeline_updater).to receive(:system).with(/pipeline=our-pipeline/)
        subject
      end

      it 'has a concourse target' do
        expect(buildpacks_ci_pipeline_updater).to receive(:system).with(/target=concourse-target/)
        subject
      end

      it 'has config set by an evaluated command' do
        expect(buildpacks_ci_pipeline_updater).to receive(:system).with(/config=<\(erb this\)/)
        subject
      end

      it 'loads env vars from lpass credential files' do
        expect(buildpacks_ci_pipeline_updater).to receive(:system) do |fly_command|
          expect(fly_command).to match /load-vars-from=\<\(.*lpass show private.yml.*\)/
          expect(fly_command).to match /load-vars-from=\<\(.*lpass show deployments.yml.*\)/
          expect(fly_command).to match /load-vars-from=\<\(.*lpass show keys.yml.*\)/
          expect(fly_command).to match /load-vars-from=\<\(.*lpass show bosh.yml.*\)/
        end
        subject
      end

      it 'loads env vars from public config' do
        expect(buildpacks_ci_pipeline_updater).to receive(:system).with(/load-vars-from=public-config.yml/)
        subject
      end

      context 'when pipeline specific config is specified' do
        let(:pipeline_variable_filename) { "specific-config.yml" }

        it 'loads env vars from specified config file' do
          expect(buildpacks_ci_pipeline_updater).to receive(:system).with(/load-vars-from=specific-config.yml/)
          subject
        end
      end

      context 'with PIPELINE_PREFIX set' do
        before { ENV['PIPELINE_PREFIX'] = 'prefix-' }

        after { ENV['PIPELINE_PREFIX'] = nil }

        it 'has a pipeline name' do
          expect(buildpacks_ci_pipeline_updater).to receive(:system).with(/pipeline=prefix-our-pipeline/)
          subject
        end
      end
    end
  end

  # describe '#update_standard_pipelines'
  # describe '#update_bosh_lite_pipelines'
  # describe '#get_cf_version_from_deployment_name'
  # describe '#update_buildpack_pipelines'
  # describe '#get_config'
  # describe '#run!'
end
