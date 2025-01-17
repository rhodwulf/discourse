# frozen_string_literal: true

require 'version'

RSpec.describe Discourse::VERSION do
  context "has_needed_version?" do
    it "works for major comparisons" do
      expect(Discourse.has_needed_version?('1.0.0', '1.0.0')).to eq(true)
      expect(Discourse.has_needed_version?('2.0.0', '1.0.0')).to eq(true)
      expect(Discourse.has_needed_version?('0.0.1', '1.0.0')).to eq(false)
    end

    it "works for minor comparisons" do
      expect(Discourse.has_needed_version?('1.1.0', '1.1.0')).to eq(true)
      expect(Discourse.has_needed_version?('1.2.0', '1.1.0')).to eq(true)
      expect(Discourse.has_needed_version?('2.0.0', '1.1.0')).to eq(true)
      expect(Discourse.has_needed_version?('0.1.0', '0.1.0')).to eq(true)

      expect(Discourse.has_needed_version?('1.0.0', '1.1.0')).to eq(false)
      expect(Discourse.has_needed_version?('0.0.1', '0.1.0')).to eq(false)
    end

    it "works for tiny comparisons" do
      expect(Discourse.has_needed_version?('2.0.0', '2.0.0')).to eq(true)
      expect(Discourse.has_needed_version?('2.0.1', '2.0.0')).to eq(true)
      expect(Discourse.has_needed_version?('1.12.0', '2.0.0')).to eq(false)
      expect(Discourse.has_needed_version?('1.12.0', '2.12.5')).to eq(false)
    end

    it "works for beta comparisons when current_version is beta" do
      expect(Discourse.has_needed_version?('1.3.0.beta3', '1.2.9')).to eq(true)
      expect(Discourse.has_needed_version?('1.3.0.beta3', '1.3.0.beta1')).to eq(true)
      expect(Discourse.has_needed_version?('1.3.0.beta3', '1.3.0.beta4')).to eq(false)
      expect(Discourse.has_needed_version?('1.3.0.beta3', '1.3.0')).to eq(false)
    end

    it "works for beta comparisons when needed_version is beta" do
      expect(Discourse.has_needed_version?('1.2.0', '1.3.0.beta3')).to eq(false)
      expect(Discourse.has_needed_version?('1.2.9', '1.3.0.beta3')).to eq(false)
      expect(Discourse.has_needed_version?('1.3.0.beta1', '1.3.0.beta3')).to eq(false)
      expect(Discourse.has_needed_version?('1.3.0.beta4', '1.3.0.beta3')).to eq(true)
      expect(Discourse.has_needed_version?('1.3.0', '1.3.0.beta3')).to eq(true)
    end
  end

  context "find_compatible_resource" do
    shared_examples "test compatible resource" do
      it "returns nil when the current version is above all pinned versions" do
        expect(Discourse.find_compatible_resource(version_list, "2.6.0")).to be_nil
      end

      it "returns the correct version if matches exactly" do
        expect(Discourse.find_compatible_resource(version_list, "2.5.0.beta4")).to eq("twofivebetafour")
      end

      it "returns the closest matching version" do
        expect(Discourse.find_compatible_resource(version_list, "2.4.6.beta12")).to eq("twofivebetatwo")
      end

      it "returns the lowest version possible when using an older version" do
        expect(Discourse.find_compatible_resource(version_list, "1.4.6.beta12")).to eq("twofourtwobetaone")
      end
    end

    it "returns nil when nil" do
      expect(Discourse.find_compatible_resource(nil)).to be_nil
    end

    it "returns nil when empty" do
      expect(Discourse.find_compatible_resource("")).to be_nil
    end

    it "raises an error on invalid input" do
      expect { Discourse.find_compatible_resource("1.0.0.beta1 12f82d5") }.to raise_error(Discourse::InvalidVersionListError)
    end

    context "with a regular compatible list" do
      let(:version_list) { <<~YML
        2.5.0.beta6: twofivebetasix
        2.5.0.beta4: twofivebetafour
        2.5.0.beta2: twofivebetatwo
        2.4.4.beta6: twofourfourbetasix
        2.4.2.beta1: twofourtwobetaone
        YML
      }
      include_examples "test compatible resource"
    end

    context "handle a compatible resource out of order" do
      let(:version_list) { <<~YML
        2.4.2.beta1: twofourtwobetaone
        2.5.0.beta4: twofivebetafour
        2.5.0.beta6: twofivebetasix
        2.5.0.beta2: twofivebetatwo
        2.4.4.beta6: twofourfourbetasix
        YML
      }
      include_examples "test compatible resource"
    end
  end

  context "find_compatible_git_resource" do
    let!(:git_directory) do
      path = nil

      capture_stdout do
        # Note the lack of colon between version and hash
        path = setup_git_repo(".discourse-compatibility" => "1.0.0.beta1 12f82d5")

        # Simulate a remote upstream
        `cd #{path} && git remote add origin #{path}/.git && git fetch -q`
        `cd #{path} && git branch -u origin/$(git rev-parse --abbrev-ref HEAD)`
      end

      path
    end

    after do
      FileUtils.remove_entry(git_directory)
    end

    it "gracefully handles invalid input" do
      output = capture_stderr do
        expect(Discourse.find_compatible_git_resource(git_directory)).to be_nil
      end

      expect(output).to include("Invalid version list")
    end
  end
end
