##
# The Court of Justice of the European Union have 1 month from the date of
# registration to respond.
#
module CjeuLateCalculator
  def calculate_date_response_required_by
    super unless cjeu?

    date = date_initial_request_last_sent_at + 1.day + 1.month
    date += 1.day while Holiday.weekend_or_holiday?(date)
    date
  end

  def calculate_date_very_overdue_after
    super unless cjeu?

    date = calculate_date_response_required_by + 1.month
    date += 1.day while Holiday.weekend_or_holiday?(date)
    date
  end

  private

  def cjeu?
    public_body.url_title == 'cjeu'
  end
end

Rails.configuration.to_prepare do
  InfoRequest.prepend CjeuLateCalculator
end
