# -*- encoding : utf-8 -*-
# Add a callback - to be executed before each request in development,
# and at startup in production - to patch existing app classes.
# Doing so in init/environment.rb wouldn't work in development, since
# classes are reloaded, but initialization is not run each time.
# See http://stackoverflow.com/questions/7072758/plugin-not-reloading-in-development-mode
#
Rails.configuration.to_prepare do
  # Front page needs some additional info
  GeneralController.class_eval do
    # Make sure it doesn't break if blog is not available
    def frontpage
      medium_cache
      @locale = I18n.locale.to_s
      successful_query = InfoRequestEvent.make_query_from_params( :latest_status => ['successful'] )
      @track_thing = TrackThing.create_track_for_search_query(successful_query)
      @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'),
                             :title => _('Successful requests'),
                             :has_json => true } ]

      blog_cache("latest-blog-posts")

      @top_requests = if params[:e] == "52"
        InfoRequest.where(:described_state => "successful").
          order(:updated_at).limit(2)
      else
        [
          InfoRequest.
            where(:url_title => 'dg_trade_contacts_with_industry').first,
          InfoRequest.
            where(:url_title => 'commissioners_expenses_2012_and_2').first
        ].compact
      end

      if @top_requests.empty?
        @top_requests = InfoRequest.top_requests.limit(2)
      end
    end

    def blog_cache(cache_key_root)
      # nothing to do here, call the blog code and return
      return blog unless AlaveteliConfiguration::cache_fragments

      @blog_key = blog_cache_key(cache_key_root, Time.zone.now)

      if fragment_exist?(@blog_key)
        # Use the cached version
      else
        blog

        if @blog_items.empty?
          # Couldn't get anything from the blog, probably due to a timeout
          # Look back in time to try to get a cached version
          old_keys = (1..6).map do |i|
            blog_cache_key("latest-blog-posts", i.hours.ago)
          end
          usable_old_key = old_keys.find { |key| fragment_exist?(key) }

          if usable_old_key
            # If there's an old cache of the blog, update the current cache so
            # that we won't get further timeouts
            logger.warn "Writing old blog fragment (#{usable_old_key}) to " \
                        "current cache (#{@blog_key}) due to feed " \
                        "error or timeout."
            write_fragment(@blog_key, read_fragment(usable_old_key))
          else
            # Nothing from the feed and no old cache. Not much we can do now, so
            # cache the empty items until the next attempt so that we're not
            # preventing the homepage load
          end
        else
          # We got some new posts. Let the view cache them
        end
      end
    end

    def blog_cache_key(cache_key_root, time)
      "#{ cache_key_root }-#{ @locale }-#{ time.strftime('%Y%m%d-%H') }"
    end
  end

  PublicBodyController.class_eval do
    def index
      # Retrieve no bodies, but return them through a pagination object,
      # so the view code works the same
      @public_bodies = PublicBody.where(false).paginate(:page => 10)
      @description = ''
      render :template => "public_body/list"
    end
  end

  HelpController.class_eval do
    def help_out
      render :template => "help/help_out"
    end

    def right_to_know
      render :template => "help/right_to_know"
    end
  end

  RequestGameController.class_eval do
    def play
      session[:request_game] = Time.now

      @missing = InfoRequest.
        where_old_unclassified.
          where(:prominence => 'normal').
            count
      @total = InfoRequest.count
      @done = @total - @missing
      @percentage = (@done.to_f / @total.to_f * 10000).round / 100.0
      @requests = InfoRequest.
        includes(:public_body, :user).
          where_old_unclassified.
            limit(3).
              where(:prominence => 'normal').
                order('random()')

      if @missing == 0
        flash[:notice] = _('<p>All done! Thank you very much for your help.</p><p>There are <a href="{{helpus_url}}">more things you can do</a> to help {{site_name}}.</p>',
                           :helpus_url => help_help_out_path,
                           :site_name => site_name)
      end

      @league_table_28_days = RequestClassification.league_table(10, [ "created_at >= ?", Time.now - 28.days ])
      @league_table_all_time = RequestClassification.league_table(10)
      @play_urls = true
    end
  end

end
