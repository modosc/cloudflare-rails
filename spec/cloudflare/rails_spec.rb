require 'spec_helper'

describe CloudflareRails do
  context(format('%s rack-attack %s', ENV['RACK_ATTACK'] ? 'with' : 'without', ENV.fetch('RACK_ATTACK', nil))) do
    it 'has a version number' do
      expect(CloudflareRails::VERSION).not_to be_nil
    end

    describe 'Railtie' do
      let!(:rails_app) do
        ActiveSupport::Dependencies.autoload_once_paths = []
        ActiveSupport::Dependencies.autoload_paths = []
        Class.new(Rails::Application) do
          config.active_support.deprecation = :stderr
          config.eager_load = false
          config.cache_store = :null_store
          config.action_dispatch.return_only_media_type_on_content_type = false
          config.secret_key_base = SecureRandom.hex
          config.middleware.use Rack::Attack if ENV['RACK_ATTACK']
        end
      end

      # by default set these valid - these are the current responses from cloudflare
      let(:ips_v4_body) do
        <<~EOM
          173.245.48.0/20
          103.21.244.0/22
          103.22.200.0/22
          103.31.4.0/22
          141.101.64.0/18
          108.162.192.0/18
          190.93.240.0/20
          188.114.96.0/20
          197.234.240.0/22
          198.41.128.0/17
          162.158.0.0/15
          172.64.0.0/13
          131.0.72.0/22
          104.16.0.0/13
          104.24.0.0/14
        EOM
      end
      let(:ips_v6_body) do
        <<~EOM
          2400:cb00::/32
          2405:8100::/32
          2405:b500::/32
          2606:4700::/32
          2803:f800::/32
          2a06:98c0::/29
          2c0f:f248::/32
        EOM
      end

      let(:ips_v4_status) { 200 }
      let(:ips_v6_status) { 200 }

      before do
        if ENV['RACK_ATTACK']
          Rack::Attack.throttle('requests per ip', limit: 300, period: 5.minutes) do |request|
            # the request object is a Rack::Request
            # https://www.rubydoc.info/gems/rack/Rack/Request
            request.ip unless request.path.start_with? '/assets/'
          end
        end

        stub_request(:get, 'https://www.cloudflare.com/ips-v4/')
          .to_return(status: ips_v4_status, body: ips_v4_body)

        stub_request(:get, 'https://www.cloudflare.com/ips-v6/')
          .to_return(status: ips_v6_status, body: ips_v6_body)
      end

      after do
        # clear our cache just in case (and if possible)
        Rails&.cache&.clear
      end

      if ENV['RACK_ATTACK']
        it 'monkey-patches rack-attack' do
          rails_app.initialize!
          expect(Rack::Attack::Request.included_modules).to include(CloudflareRails::CheckTrustedProxies)
        end
      end

      it 'works with valid responses' do
        expect_any_instance_of(Logger).not_to receive(:error)
        rails_app.initialize!
        expect(Set.new(CloudflareRails::Importer.cloudflare_ips(refresh: true)))
          .to eq(Set.new((ips_v4_body + ips_v6_body).split("\n").map { |ip| IPAddr.new ip }))
      end

      describe 'with unsuccessful responses' do
        let(:ips_v4_status) { 404 }
        let(:ips_v6_status) { 404 }

        it "doesn't break but still logs the error" do
          expect_any_instance_of(Logger).to receive(:error).once.and_call_original
          rails_app.initialize!
          expect(CloudflareRails::Importer.cloudflare_ips(refresh: true)).to be_blank
        end
      end

      describe 'with invalid bodies' do
        let(:ips_v4_body) { 'asdfasdfasdfasdfasdf' }
        let(:ips_v6_body) { "\r\n\r\n\r\n" }

        it "doesn't break but still logs the error" do
          expect_any_instance_of(Logger).to receive(:error).once.and_call_original
          rails_app.initialize!
          expect(CloudflareRails::Importer.cloudflare_ips(refresh: true)).to be_blank
        end
      end

      # functional tests - maybe duplicate of the remote_ip/ip tests above?
      describe 'middleware', type: :request do
        let(:base_ip) { '1.2.3.4' }
        let(:non_cf_ip) { '8.8.4.4' }
        let(:cf_ip) { '197.234.240.1' }
        let(:cf_env) do
          {
            'HTTP_X_FORWARDED_FOR' => "#{base_ip}, #{cf_ip}",
            'REMOTE_ADDR' => cf_ip
          }
        end
        let(:non_cf_env) do
          {
            'HTTP_X_FORWARDED_FOR' => "#{base_ip}, #{non_cf_ip}",
            'REMOTE_ADDR' => non_cf_ip
          }
        end
        let(:cf_proxy_env) do
          {
            'HTTP_X_FORWARDED_FOR' => "#{base_ip}, #{cf_ip}, 127.0.0.1",
            'REMOTE_ADDR' => '127.0.0.1'
          }
        end
        let(:non_cf_proxy_env) do
          {
            'HTTP_X_FORWARDED_FOR' => "#{base_ip}, #{non_cf_ip}, 127.0.0.1",
            'REMOTE_ADDR' => '127.0.0.1'
          }
        end

        before do
          class FooController < ActionController::Base
            def index
              render status: :ok, json: { ip: request.ip, remote_ip: request.remote_ip }
            end
          end

          rails_app.initialize!
          rails_app.routes.draw do
            root to: 'foo#index', format: 'json'
          end
        end

        # based on code from https://github.com/rails/rails/blob/7f18ea14c893cb5c9f04d4fda9661126758332b5/railties/test/application/middleware/remote_ip_test.rb
        def remote_ip(env = {})
          remote_ip = nil
          env = Rack::MockRequest.env_for('/').merge(env).merge!(
            'action_dispatch.show_exceptions' => false,
            'action_dispatch.key_generator' => ActiveSupport::KeyGenerator.new('b3c631c314c0bbca50c1b2843150fe33')
          )

          endpoint = proc do |e|
            remote_ip = ActionDispatch::Request.new(e).remote_ip
            [200, {}, [remote_ip]]
          end

          rails_app.middleware.build(endpoint).call(env)
          # return our ip _and_ our env hash
          [remote_ip, env]
        end

        def ip(env = {})
          ip = nil
          env = Rack::MockRequest.env_for('/').merge(env).merge!(
            'action_dispatch.show_exceptions' => false,
            'action_dispatch.key_generator' => ActiveSupport::KeyGenerator.new('b3c631c314c0bbca50c1b2843150fe33')
          )

          endpoint = proc do |e|
            ip = ActionDispatch::Request.new(e).ip
            [200, {}, [ip]]
          end

          rails_app.middleware.build(endpoint).call(env)
          # return our ip _and_ our env hash
          [ip, env]
        end

        # test two different ways:
        #
        # 1) using the ip/remote_ip methods from above
        # 2) using a functional test with the ip/remote_ip embedded in the response
        #    payload - this probably isn't necessary but i don't 100% understand
        #    what the copied remote_ip code from the rails tests is actually doing.

        %i[ip remote_ip].each do |m|
          describe "request.#{m}" do
            subject { send(m, env) }

            shared_examples 'it gets the correct ip address from rack' do
              it 'works' do
                expect(subject[0]).to eq(expected_ip)
                if ENV['RACK_ATTACK']
                  expect(subject.dig(1, 'rack.attack.throttle_data', 'requests per ip',
                                     :discriminator)).to eq(expected_ip)
                end
              end
            end

            context 'with a cloudflare ip' do
              let(:env) { cf_env }
              let(:expected_ip) { base_ip }

              it_behaves_like 'it gets the correct ip address from rack'
            end

            context 'with a non-cloudflare ip' do
              let(:env) { non_cf_env }
              let(:expected_ip) { non_cf_ip }

              it_behaves_like 'it gets the correct ip address from rack'
            end

            context 'with a cloudflare ip and a local proxy' do
              let(:env) { cf_proxy_env }
              let(:expected_ip) { base_ip }

              it_behaves_like 'it gets the correct ip address from rack'
            end

            context 'works with a non-cloudflare ip and a local proxy' do
              let(:env) { non_cf_proxy_env }
              let(:expected_ip) { non_cf_ip }

              it_behaves_like 'it gets the correct ip address from rack'
            end

            context 'with an invalid ip' do
              let(:base_ip) { 'not-an-ip.test,122.175.218.25' }
              let(:env) { cf_env }
              let(:expected_ip) { '122.175.218.25' }

              it_behaves_like 'it gets the correct ip address from rack'
            end
          end

          describe "##{m}", type: :controller do
            controller do
              def index
                render status: :ok, json: { ip: request.ip, remote_ip: request.remote_ip }
              end
            end

            shared_examples 'it gets the correct ip address from rails' do
              it 'works' do
                request.env.merge! env
                get :index
                expect(response).to have_http_status(:ok)
                expect(JSON[response.body][m.to_s]).to eq(expected_ip)
              end
            end

            context 'with a cloudflare ip' do
              let(:env) { cf_env }
              let(:expected_ip) { base_ip }

              it_behaves_like 'it gets the correct ip address from rails'
            end

            context 'with a non-cloudflare ip' do
              let(:env) { non_cf_env }
              let(:expected_ip) { non_cf_ip }

              it_behaves_like 'it gets the correct ip address from rails'
            end

            context 'with a cloudflare ip and a local proxy' do
              let(:env) { cf_proxy_env }
              let(:expected_ip) { base_ip }

              it_behaves_like 'it gets the correct ip address from rails'
            end

            context 'with a non-cloudflare ip and a local proxy' do
              let(:env) { non_cf_proxy_env }
              let(:expected_ip) { non_cf_ip }

              it_behaves_like 'it gets the correct ip address from rails'
            end

            context 'with an invalid ip' do
              let(:base_ip) { 'not-an-ip.test,122.175.218.25' }
              let(:env) { cf_env }
              let(:expected_ip) { '122.175.218.25' }

              it_behaves_like 'it gets the correct ip address from rails'
            end
          end
        end
      end
    end
  end
end
