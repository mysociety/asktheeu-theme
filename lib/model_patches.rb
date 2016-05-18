# -*- encoding : utf-8 -*-
# Add a callback - to be executed before each request in development,
# and at startup in production - to patch existing app classes.
# Doing so in init/environment.rb wouldn't work in development, since
# classes are reloaded, but initialization is not run each time.
# See http://stackoverflow.com/questions/7072758/plugin-not-reloading-in-development-mode
#
Rails.configuration.to_prepare do

  # Remove UK-specific references to FOI
  InfoRequest.instance_eval do

    THEME_LAW_USED_READABLE_DATA =
      { :foi => { :short => _('documents'),
                  :full => _('access to documents'),
                  :with_a => _('An access to documents request'),
                  :act => _('Regulation 1049/2001') }
      }

  end

  # Remove UK-specific references to FOI
  InfoRequest.class_eval do
    def self.top_requests
      ids = connection.select_values <<-SQL.strip_heredoc.gsub("\n", " ")
      SELECT info_request_id
      FROM "track_things"
      WHERE (info_request_id IS NOT NULL)
      GROUP BY info_request_id
      ORDER BY COUNT(*) DESC;
      SQL

      where(:id => ids).order("position(id::text in '#{ ids }')")
    end

    def applicable_law
      begin
        THEME_LAW_USED_READABLE_DATA.fetch(law_used.to_sym)
      rescue KeyError
        raise "Unknown law used '#{law_used}'"
      end
    end

  end

  OutgoingMessage.class_eval do

    # Add intro paragraph to new request template
    def default_letter
      return nil if self.message_type == 'followup'

      _("Under the right of access to documents in the EU treaties, as developed in " \
        "Regulation 1049/2001, I am requesting documents which contain the following " \
        "information:\n\n")
    end

    # Modify the search snippet to hide the intro paragraph.
    # TODO: Need to have locale information in the model to improve this (issue #255)
    def get_text_for_indexing(strip_salutation = true, opts = {})
      if opts.empty?
        text = body.strip
      else
        text = body(opts).strip
      end

      # Remove salutation
      text.sub!(/Dear .+,/, "") if strip_salutation
      # TODO: can't be more specific without locale
      text.sub!(/[^\n]+1049\/2001[^:\n]+:? ?/, "")
      # Remove email addresses from display/index etc.
      self.remove_privacy_sensitive_things!(text)

      text
    end

  end

  # Disable funcionality to let users of the site act on behalf of the public
  # body, since we aren't sure right now this is safe enough
  PublicBody.class_eval do

    def is_foi_officer?(user)
      false
    end

  end

  User.class_eval do

    validates :name,
              :on => :create,
              :format => {
                :with => /\s/,
                :message => _("Please enter your full name"),
                :allow_blank => true
              }

  end

end
