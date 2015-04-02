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
            begin
                blog
            rescue
                @blog_items = []
                @twitter_user = MySociety::Config.get('TWITTER_USERNAME', '')
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

    RequestController.class_eval do
      # Page new form posts to
      def new
          # All new requests are of normal_sort
          if !params[:outgoing_message].nil?
              params[:outgoing_message][:what_doing] = 'normal_sort'
          end

          # If we've just got here (so no writing to lose), and we're already
          # logged in, force the user to describe any undescribed requests. Allow
          # margin of 1 undescribed so it isn't too annoying - the function
          # get_undescribed_requests also allows one day since the response
          # arrived.
          if !@user.nil? && params[:submitted_new_request].nil? && !@user.can_leave_requests_undescribed?
              @undescribed_requests = @user.get_undescribed_requests
              if @undescribed_requests.size > 1
                  render :action => 'new_please_describe'
                  return
              end
          end

          # Banned from making new requests?
          user_exceeded_limit = false
          if !authenticated_user.nil? && !authenticated_user.can_file_requests?
              # If the reason the user cannot make new requests is that they are
              # rate-limited, it’s possible they composed a request before they
              # logged in and we want to include the text of the request so they
              # can squirrel it away for tomorrow, so we detect this later after
              # we have constructed the InfoRequest.
              user_exceeded_limit = authenticated_user.exceeded_limit?
              if !user_exceeded_limit
                  @details = authenticated_user.can_fail_html
                  render :template => 'user/banned'
                  return
              end
              # User did exceed limit
              @next_request_permitted_at = authenticated_user.next_request_permitted_at
          end

          # First time we get to the page, just display it
          if params[:submitted_new_request].nil? || params[:reedit]
              if user_exceeded_limit
                  render :template => 'user/rate_limited'
                  return
              end
              return render_new_compose(batch=false)
          end

          # Check we have :public_body_id - spammers seem to be using :public_body
          # erroneously instead
          if params[:info_request][:public_body_id].blank?
            redirect_to frontpage_path and return
          end

          # See if the exact same request has already been submitted
          # TODO: this check should theoretically be a validation rule in the
          # model, except we really want to pass @existing_request to the view so
          # it can link to it.
          @existing_request = InfoRequest.find_existing(params[:info_request][:title], params[:info_request][:public_body_id], params[:outgoing_message][:body])

          # Create both FOI request and the first request message
          @info_request = InfoRequest.create_from_attributes(params[:info_request],
                                                             params[:outgoing_message])
          @outgoing_message = @info_request.outgoing_messages.first

          # Maybe we lost the address while they're writing it
          if !@info_request.public_body.is_requestable?
              render :action => 'new_' + @info_request.public_body.not_requestable_reason
              return
          end

          # See if values were valid or not
          if !@existing_request.nil? || !@info_request.valid?
              # We don't want the error "Outgoing messages is invalid", as in this
              # case the list of errors will also contain a more specific error
              # describing the reason it is invalid.
              @info_request.errors.delete(:outgoing_messages)

              render :action => 'new'
              return
          end

          # Show preview page, if it is a preview
          if params[:preview].to_i == 1
              return render_new_preview
          end

          if user_exceeded_limit
              render :template => 'user/rate_limited'
              return
          end

          if !authenticated?(
                  :web => _("To send your FOI request").to_str,
                  :email => _("Then your FOI request to {{public_body_name}} will be sent.",:public_body_name=>@info_request.public_body.name),
                  :email_subject => _("Confirm your FOI request to {{public_body_name}}",:public_body_name=>@info_request.public_body.name)
              )
              # do nothing - as "authenticated?" has done the redirect to signin page for us
              return
          end

          if params[:post_redirect_user]
              # If an admin has clicked the confirmation link on a users behalf,
              # we don’t want to reassign the request to the administrator.
              @info_request.user = params[:post_redirect_user]
          else
              @info_request.user = authenticated_user
          end
          # This automatically saves dependent objects, such as @outgoing_message, in the same transaction
          @info_request.save!
          # TODO: send_message needs the database id, so we send after saving, which isn't ideal if the request broke here.
          @outgoing_message.send_message
          flash[:request_sent] = true
          flash[:notice] = _("<p>Your {{law_used_full}} request has been <strong>sent on its way</strong>!</p>
              <p><strong>We will email you</strong> when there is a response, or after {{late_number_of_days}} working days if the authority still hasn't
              replied by then.</p>
              <p>If you write about this request (for example in a forum or a blog) please link to this page, and add an
              annotation below telling people about your writing.</p>",:law_used_full=>@info_request.law_used_full,
              :late_number_of_days => AlaveteliConfiguration::reply_late_after_days)

          flash[:notice] = flash[:notice] += _(%Q(
    <div id="ms_srv_wrapper" style="display:none;">
        <p><a href="https://www.surveygizmo.co.uk/s3/1979939/2014-Baselining-AskTheEU" id="ms_srv_link" data-transaction="report">
            We're running a short survey to help us understand how well AskTheEU works. If you'd like to take it, click here.
        </a></p>
    </div>))

          redirect_to show_new_request_path(:url_title => @info_request.url_title)
      end
    end

end
