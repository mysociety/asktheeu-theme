# -*- encoding : utf-8 -*-
# Add a callback - to be executed before each request in development,
# and at startup in production - to patch existing app classes.
# Doing so in init/environment.rb wouldn't work in development, since
# classes are reloaded, but initialization is not run each time.
# See http://stackoverflow.com/questions/7072758/plugin-not-reloading-in-development-mode
#
Rails.configuration.to_prepare do
  require 'timeout'

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

      blog_cache

      @top_requests = [
        InfoRequest.
          where(:url_title => 'dg_trade_contacts_with_industry').first,
        InfoRequest.
          where(:url_title => 'commissioners_expenses_2012_and_2').first
      ].compact

      if @top_requests.empty?
        @top_requests = InfoRequest.top_requests.limit(2)
      end
    end

    private

    def blog_cache
      Timeout.timeout(1) do
        Blog.new.posts
      end
    rescue Timeout::Error, REXML::ParseException
    end

    def create_timestamp(time=Time.zone.now)
      time.strftime('%Y%m%d-%H:%M:%S')
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
      session[:request_game] = Time.zone.now

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

      @league_table_28_days = RequestClassification.league_table(10,
        [ "request_classifications.created_at >= ?", Time.zone.now - 28.days ])
      @league_table_all_time = RequestClassification.league_table(10)
      @play_urls = true
    end
  end

end
