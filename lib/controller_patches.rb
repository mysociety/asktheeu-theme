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

   #   begin
   #     blog
   #   rescue
        @blog_items = []
        @twitter_user = MySociety::Config.get('TWITTER_USERNAME', '')
   #   end

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

end
