require 'spec_helper'

describe APNS do
  describe '.send_notifications' do
    let(:cert) { 'spec/support/dummy.pem' }
    let(:tcp_socket) { instance_double(TCPSocket).as_null_object }
    let(:ssl_socket) { instance_double(OpenSSL::SSL::SSLSocket).as_null_object }

    before do
      allow(APNS).to receive(:pem).and_return cert
      allow(TCPSocket).to receive(:new).with(APNS.host, APNS.port).and_return(tcp_socket)
      allow(OpenSSL::SSL::SSLSocket).to receive(:new).with(tcp_socket, an_instance_of(OpenSSL::SSL::SSLContext))
        .and_return(ssl_socket)
    end

    let(:notification) { APNS::Notification.new '123', 'hi' }

    subject { described_class.send_notifications [notification] }

    it { expect { subject }.not_to raise_error }

    context 'when there is connection error' do
      let(:error) { StandardError.new }

      before do
        allow(ssl_socket).to receive(:connect).and_raise error
      end

      it { expect { subject }.to raise_error error }
    end
  end
end
