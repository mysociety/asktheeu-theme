# -*- encoding : utf-8 -*-
# If defined, ALAVETELI_TEST_THEME will be loaded in config/initializers/theme_loader
ALAVETELI_TEST_THEME = 'asktheeu-theme'
require File.expand_path(File.join(File.dirname(__FILE__),
                         '..','..','..','..', '..', 'spec','spec_helper'))

describe GeneralController, "when patched by the asktheeu-theme" do

  describe "caching blog content" do

    before do
      allow(controller).to receive(:get_blog_content)
    end

    context "creating the timestamp" do

      it "returns a string" do
        expect(controller.send(:create_timestamp)).to be_a(String)
      end

      it "does not contain spaces" do
        expect(controller.send(:create_timestamp)).not_to include(" ")
      end

      it "can be read back correctly" do
        time = Time.parse("2016-08-01 09:29:16")
        timestamp = controller.send(:create_timestamp, time)
        expect(Time.parse(timestamp)).to eq(time)
      end

    end

    context "caching is disabled" do

      before do
        allow(AlaveteliConfiguration).to receive(:cache_fragments).
          and_return(false)
      end

      it "does not attempt to read from the cache" do
        allow(controller).to receive(:get_blog_content)
        expect(controller).not_to receive(:read_fragment)
        controller.send(:blog_cache, "test", 1.minute)
      end

      it "calls the get_blog_content controller action" do
        expect(controller).to receive(:get_blog_content)
        controller.send(:blog_cache, "test", 1.minute)
      end

    end

    context "the cache is empty" do

      before do
        allow(AlaveteliConfiguration).to receive(:cache_fragments).
          and_return(true)
        allow(controller).to receive(:read_fragment).with("test-lastupdated").
          and_return(nil)
        allow(controller).to receive(:write_fragment)
      end

      context "the blog is available" do

        before do
          controller.instance_variable_set(:@blog_items, ["content"])
        end

        it "calls the get_blog_content controller action" do
          expect(controller).to receive(:get_blog_content)
          controller.send(:blog_cache, "test", 10.minutes)
        end

        it "sets the cache that holds the last updated timestamp" do
          expect(controller).to receive(:write_fragment).
            with("test-lastupdated", anything)
          controller.send(:blog_cache, "test", 10.minutes)
        end

      end

      context "the blog is not available" do

        before do
          controller.instance_variable_set(:@blog_items, [])
          allow(controller).to receive(:read_fragment).with("test-lastupdated").
            and_return(nil)
          allow(controller).to receive(:read_fragment).with("test-").
            and_return(nil)
        end

        it "calls the get_blog_content controller action" do
          expect(controller).to receive(:get_blog_content)
          controller.send(:blog_cache, "test", 10.minutes)
        end

        it "sets the cache that holds the last updated timestamp" do
          expect(controller).to receive(:write_fragment).
            with("test-lastupdated", anything)
          controller.send(:blog_cache, "test", 10.minutes)
        end

        it "does not attempt to write new fragment if there isn't an old one" do
          allow(controller).to receive(:read_fragment).with("test-").
            and_return(nil)
          expect(controller).to receive(:write_fragment).once
          controller.send(:blog_cache, "test", 10.minutes)
        end

      end

    end

    context "there is cached content" do
      let(:updated) { "#{Time.now - 3.minutes}"}

      before do
        allow(AlaveteliConfiguration).to receive(:cache_fragments).
          and_return(true)
        allow(controller).to receive(:write_fragment)
        allow(controller).to receive(:read_fragment).with("test-lastupdated").
          and_return(updated)
        allow(controller).to receive(:fragment_exist?).with("test-#{updated}").
          and_return(true)
      end

      context "the cache is fresh" do

        it "does not call the get_blog_content controller action" do
          expect(controller).to_not receive(:get_blog_content)
          controller.send(:blog_cache, "test", 4.minutes)
        end

        it "does not set the cache that holds the last updated timestamp" do
          expect(controller).to_not receive(:write_fragment).
            with("test-lastupdated", anything)
          controller.send(:blog_cache, "test", 4.minutes)
        end

        context "but the content fragment can not be read" do

          it "calls the blog controller action" do
            controller.instance_variable_set(:@blog_items, ["content"])
            allow(controller).to receive(:fragment_exist?).
              with("test-#{updated}").and_return(false)
            allow(controller).to receive(:read_fragment).
              and_return(nil)
            expect(controller).to receive(:get_blog_content)
            controller.send(:blog_cache, "test", 4.minutes)
          end

        end

      end

      context "the cache is stale" do

        context "the blog is not available" do

          before do
            controller.instance_variable_set(:@blog_items, [])
            allow(controller).to receive(:read_fragment).with("test-#{updated}").
              and_return("old fragment")
          end

          it "calls the get_blog_content controller action" do
            expect(controller).to receive(:get_blog_content)
            controller.send(:blog_cache, "test", 2.minutes)
          end

          it "sets the cache that holds the last updated timestamp" do
            expect(controller).to receive(:write_fragment).
              with("test-lastupdated", anything)
            controller.send(:blog_cache, "test", 2.minutes)
          end

          it "writes out the previous fragment if there is one" do
            allow(controller).to receive(:write_fragment).
              with("test-lastupdated", anything)
            expect(controller).to receive(:write_fragment).
              with(anything, "old fragment")
            controller.send(:blog_cache, "test", 2.minutes)
          end

        end

        context "the blog is available" do

          before do
            controller.instance_variable_set(:@blog_items, ["content"])
          end

          it "calls the get_blog_content controller action" do
            expect(controller).to receive(:get_blog_content)
            controller.send(:blog_cache, "test", 2.minutes)
          end

          it "sets the cache that holds the last updated timestamp" do
            expect(controller).to receive(:write_fragment).
              with("test-lastupdated", anything)
            controller.send(:blog_cache, "test", 2.minutes)
          end

        end

      end

    end

  end

end
