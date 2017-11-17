class EmailSettings < ActiveRecord::Base
  belongs_to :conference

  has_paper_trail on: [:update], ignore: [:updated_at], meta: { conference_id: :conference_id }

  def get_values(conference, user, event = nil)
    h = {
      'email' => user.email,
      'name' => user.name,
      'conference' => conference.title,
      'conference_start_date' => conference.start_date,
      'conference_end_date' => conference.end_date,
      'registrationlink' => Rails.application.routes.url_helpers.conference_conference_registration_url(
                            conference.short_title, host: (ENV['OSEM_HOSTNAME'] || 'localhost:3000')),
      'conference_splash_link' => Rails.application.routes.url_helpers.conference_url(
                                  conference.short_title, host: (ENV['OSEM_HOSTNAME'] || 'localhost:3000')),

      'schedule_link' => Rails.application.routes.url_helpers.conference_schedule_url(
                         conference.short_title, host: (ENV['OSEM_HOSTNAME'] || 'localhost:3000'))
    }

    if conference.program.cfp
      h['cfp_start_date'] = conference.program.cfp.start_date
      h['cfp_end_date'] = conference.program.cfp.end_date
    else
      h['cfp_start_date'] = 'Unknown'
      h['cfp_end_date'] = 'Unknown'
    end

    if conference.venue
      h['venue'] = conference.venue.name
      h['venue_address'] = conference.venue.address
    else
      h['venue'] = 'Unknown'
      h['venue_address'] = 'Unknown'
    end

    if conference.registration_period
      h['registration_start_date'] = conference.registration_period.start_date
      h['registration_end_date'] = conference.registration_period.end_date
    end

    if event
      h['eventtitle'] = event.title
      h['proposalslink'] = Rails.application.routes.url_helpers.conference_program_proposals_url(
                           conference.short_title, host: (ENV['OSEM_HOSTNAME'] || 'localhost:3000'))
    end
    h
  end

  def expand_event_template(event, user, template)
    values = get_values(event.program.conference, user, event)
    parse_template(template, values)
  end


  def expand_conf_template(conference, user, template)
    values = get_values(conference, user)
    parse_template(template, values)
  end

  private

  def parse_template(text, values)
    values.each do |key, value|
      if value.kind_of?(Date)
        text = text.gsub "{#{key}}", value.strftime('%Y-%m-%d') unless text.blank?
      else
        text = text.gsub "{#{key}}", value unless text.blank? || value.blank?
      end
    end
    text
  end
end
