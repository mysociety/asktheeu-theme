# -*- encoding : utf-8 -*-
# If defined, ALAVETELI_TEST_THEME will be loaded in config/initializers/theme_loader
ALAVETELI_TEST_THEME = 'asktheeu-theme'
require File.expand_path(File.join(File.dirname(__FILE__),
                         '..','..','..','..', '..', 'spec','spec_helper'))

describe GeneralController, 'blog caching' do

  class GeneralController
    def get_blog_content
      @blog_items = ["blog_item"]
    end
  end

  let(:blog_feed) { 'http://example.com/feed' }
  let(:cache_fragments) { true }

  before do
    allow(AlaveteliConfiguration).to receive(:blog_feed).and_return(blog_feed)
    allow(AlaveteliConfiguration).to receive(:cache_fragments)
      .and_return(cache_fragments)
  end

  context 'blog not configured' do

    let(:blog_feed) { '' }

    it 'assigns empty array to blog cache instance variable' do
      controller.send(:blog_cache, 'cache_key', 1.minute)
      expect(controller.instance_variable_get(:@blog_items)).to eq []
    end

  end

  context 'cache disabled' do

    let(:cache_fragments) { false }

    it 'calls the get_blog_content controller action' do
      expect(controller).to receive(:get_blog_content)
      controller.send(:blog_cache, 'cache_key', 1.minute)
    end

    it 'does not calls the fragment controller actions' do
      allow(controller).to receive(:get_blog_content)
      expect(controller).to_not receive(:read_fragment)
      expect(controller).to_not receive(:write_fragment)
      controller.send(:blog_cache, 'cache_key', 1.minute)
    end

  end

  context 'cache empty' do

    before do
      allow(controller).to receive(:read_fragment)
        .with('cache_key')
        .and_return(nil)
    end

    it 'calls the get_blog_content controller action' do
      expect(controller).to receive(:get_blog_content)
      controller.send(:blog_cache, 'cache_key', 1.minute)
    end

    it 'writes fragment cache' do
      expect(controller).to receive(:write_fragment)
        .with('cache_key', '["blog_item"]', expires_in: 1.minute)
      controller.send(:blog_cache, 'cache_key', 1.minute)
    end

  end

  context 'cache full' do

    before do
      allow(controller).to receive(:read_fragment)
        .with('cache_key')
        .and_return('["cached_blog_item"]')
    end

    it 'does not call the get_blog_content controller action' do
      expect(controller).to_not receive(:get_blog_content)
      controller.send(:blog_cache, 'cache_key', 1.minute)
    end

    it 'assigns fragment to blog cache instance variable' do
      controller.send(:blog_cache, 'cache_key', 1.minute)
      expect(controller.instance_variable_get(:@blog_items)).to(
        eq ['cached_blog_item']
      )
    end

  end

end
