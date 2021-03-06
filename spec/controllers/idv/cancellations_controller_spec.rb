require 'rails_helper'

describe Idv::CancellationsController do
  describe 'before_actions' do
    it 'includes before_actions from IdvSession' do
      expect(subject).to have_actions(:before, :redirect_if_sp_context_needed)
    end
  end

  describe '#new' do
    it 'tracks the event in analytics when referer is nil' do
      stub_sign_in
      stub_analytics
      properties = { request_came_from: 'no referer', step: nil }

      expect(@analytics).to receive(:track_event).with(Analytics::IDV_CANCELLATION, properties)

      get :new
    end

    it 'tracks the event in analytics when referer is present' do
      stub_sign_in
      stub_analytics
      request.env['HTTP_REFERER'] = 'http://example.com/'
      properties = { request_came_from: 'users/sessions#new', step: nil }

      expect(@analytics).to receive(:track_event).with(Analytics::IDV_CANCELLATION, properties)

      get :new
    end

    it 'tracks the event in analytics when step param is present' do
      stub_sign_in
      stub_analytics
      properties = { request_came_from: 'no referer', step: 'first' }

      expect(@analytics).to receive(:track_event).with(Analytics::IDV_CANCELLATION, properties)

      get :new, params: { step: 'first' }
    end
  end

  describe '#destroy' do
    it 'tracks an analytics event' do
      stub_sign_in
      stub_analytics

      expect(@analytics).to receive(:track_event).with(
        Analytics::IDV_CANCELLATION_CONFIRMED,
        step: 'first',
      )

      delete :destroy, params: { step: 'first' }
    end
  end
end
