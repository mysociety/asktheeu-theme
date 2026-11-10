# -*- encoding : utf-8 -*-
require_relative '../spec_helper'

describe GeneralController, "when patched by the asktheeu-theme" do

  describe "caching blog content" do

    context "creating the timestamp" do

      it "returns a string" do
        expect(controller.send(:create_timestamp)).to be_a(String)
      end

      it "does not contain spaces" do
        expect(controller.send(:create_timestamp)).not_to include(" ")
      end

      it "can be read back correctly" do
        time = Time.zone.parse("2016-08-01 09:29:16")
        timestamp = controller.send(:create_timestamp, time)
        expect(Time.zone.parse(timestamp)).to eq(time)
      end

    end

    context "fetching blog posts" do
      let(:blog) { instance_double(Blog) }

      before { allow(Blog).to receive(:new).and_return(blog) }

      it "fetches the posts" do
        expect(blog).to receive(:posts)
        controller.send(:blog_cache)
      end

      it "ignores a timeout" do
        allow(blog).to receive(:posts).and_raise(Timeout::Error)
        expect { controller.send(:blog_cache) }.not_to raise_error
      end

      it "ignores a malformed feed" do
        allow(blog).to receive(:posts).
          and_raise(REXML::ParseException.new('malformed'))
        expect { controller.send(:blog_cache) }.not_to raise_error
      end
    end

  end

end
