# -*- encoding : utf-8 -*-
# If defined, ALAVETELI_TEST_THEME will be loaded in config/initializers/theme_loader
ALAVETELI_TEST_THEME = 'asktheeu-theme'
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','..','spec','spec_helper'))

describe InfoRequest, 'when patched by the asktheeu-theme' do

  describe '#law_used_full' do

    it 'returns "access to information"' do
      expect(InfoRequest.new.law_used_full).to eq('access to information')
    end

  end

  describe '#law_used_short' do

    it 'returns "information"' do
      expect(InfoRequest.new.law_used_short).to eq('information')
    end

  end

end

describe PublicBody, 'when patched by the asktheeu-theme' do

  describe '#is_foi_officer?' do

    it 'always returns false' do
      body = PublicBody.new(:request_email => 'blah@example.com')
      user = User.new(:email => 'user@example.com')
      expect(body.is_foi_officer?(user)).to eq(false)
    end

  end

end

describe OutgoingMessage, 'when patched by the asktheeu-theme' do

  describe '#default_letter' do

    it 'returns nil for a follow up message' do
      internal_review_request = FactoryGirl.build(:internal_review_request)
      expect(internal_review_request.default_letter).to be_nil
    end

    it 'returns text about Regulation 1049/2001' do
      initial_request = FactoryGirl.build(:initial_request)
      expected = 'Regulation 1049/2001'
      expect(initial_request.default_letter).to match(expected)
    end

  end

  describe '#get_text_for_indexing' do

    it 'strips the salutation' do
      body = <<-EOF.strip_heredoc
      Dear someone,
      Please give me some information
      EOF
      initial_request = FactoryGirl.build(:initial_request, :body => body)
      expected = 'Dear someone'
      expect(initial_request.get_text_for_indexing).not_to match(expected)
    end

    it 'strips the text about Regulation 1049/2001' do
      body = <<-EOF.strip_heredoc
      Dear someone,
      Please give me some information
      EOF
      initial_request = FactoryGirl.build(:initial_request)
      initial_request.update_attribute(:body, initial_request.default_letter + body)
      expect(initial_request.get_text_for_indexing).
        not_to match(initial_request.default_letter)
    end

    it 'redacts an email address' do
      body = <<-EOF.strip_heredoc
      Dear someone,
      Please give me some information to me@example.com
      EOF
      initial_request = FactoryGirl.build(:initial_request)
      expected = /[email address]/
      initial_request.update_attribute(:body, initial_request.default_letter + body)
      expect(initial_request.get_text_for_indexing).
      to match(expected)
    end

  end

end
