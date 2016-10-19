require 'spec_helper'

describe APNS do
  describe '.send_notifications' do
    let(:notification) { APNS::Notification.new '123', 'hi' }

    subject { described_class.send_notifications [notification] }

    it { expect { subject }.not_to raise_error NoMethodError }
  end
end
