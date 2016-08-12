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

      blog_cache("latest_blog_posts-#{@locale}")

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

    def cached_blog
      blog_cache("blog_posts-#{@locale}")
      render :action => 'blog'
    end

    private

    def blog_cache(cache_key, expires=4.hours)
      # nothing to do here, call the blog code and return
      return blog unless AlaveteliConfiguration::cache_fragments

      # read in the last timestamp
      updated = read_fragment("#{cache_key}-lastupdated")

      # construct the fragment key
      @fragment_key = "#{cache_key}-#{updated}"

      # if the fragment is unreadable or has reached expiry
      # attempt to pull in the blog feed
      if updated.nil? || !fragment_exist?(@fragment_key) ||
         Time.now > (Time.parse(updated) + expires)
        # keep a note of the old key
        old_key = @fragment_key.dup

        # prepare a new timestamp and fragment key
        updated = create_timestamp
        @fragment_key = "#{cache_key}-#{updated}"

        logger.info "attempting to pull in the feed"
        blog

        if @blog_items.empty?
          # attempt to write the previous fragment to our new cache
          fragment = read_fragment(old_key)
          if fragment
            logger.warn "Writing old blog fragment (#{old_key}) to " \
                        "current cache (#{@fragment_key}) due to feed " \
                        "error or timeout."
            write_fragment(@fragment_key, fragment)
          end
        end

        # store the new timestamp
        write_fragment("#{cache_key}-lastupdated", updated)
      end
    end

    def create_timestamp(time=Time.now)
      time.strftime('%Y%m%d-%H:%M:%S')
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
