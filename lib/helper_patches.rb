# -*- encoding : utf-8 -*-

Rails.configuration.to_prepare do

  WidgetHelper.class_eval do

    def status_description(info_request, status)
      case status
      when 'waiting_classification'
        _('Unknown Status')
      when 'waiting_response', 'waiting_response_overdue', 'waiting_response_very_overdue'
        _('Waiting Response')
      when 'not_held'
        _('Not Held')
      when 'rejected'
        _('Rejected')
      when 'successful'
        _('Successful')
      when 'partially_successful'
        _('Partial Success')
      when 'waiting_clarification'
        _('Waiting Clarification')
      when 'gone_postal'
        _('Gone Postal')
      when 'internal_review'
        _('Internal Review')
      when 'error_message'
        _('Error message')
      when 'requires_admin'
        _('Requires Admin')
      when 'user_withdrawn'
        _('User Withdrawn')
      when 'attention_requested'
        _('Attention Requested')
      when 'vexatious'
        _('Vexatious')
      else
        if InfoRequest.respond_to?(:theme_display_status)
          InfoRequest.theme_display_status(status)
        else
          _('Unknown')
        end
      end
    end

  end

 end