# frozen_string_literal: true

require 'stripe'
require 'sinatra'

unless ENV['APP_ENV'] == 'production'
  require 'dotenv'
  Dotenv.load('.env')
end
Stripe.api_key = ENV['STRIPE_TEST_SECRET_KEY']
Stripe.api_version = '2020-08-27'
ENVPOINT_SECRET = ENV['WEBHOOK_SIGNING_SECRET']

set :static, true
set :public_folder, File.dirname(__FILE__)
set :port, 4242

LOCAL_DOMAIN = "http://localhost:#{settings.port}"
YOUR_DOMAIN = ENV['APP_ENV'] == 'production' ? ENV['HEROKU_DOMAIN'] : LOCAL_DOMAIN

get '/' do
  erb :checkout, locals: { pubkey: ENV['STRIPE_TEST_PUBLIC_KEY'] }
end

post '/webhook' do
  event = nil

  logger.info('MY_LOG: Receive webhook request')

  # Verify webhook signature and extract the event
  # See https://stripe.com/docs/webhooks/signatures for more information.
  begin
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    payload = request.body.read
    event = Stripe::Webhook.construct_event(payload, sig_header, ENVPOINT_SECRET)
  rescue JSON::ParserError => e
    # Invalid payload
    logger.error('MY_LOG: webhook Invalid payload')
    return status 400
  rescue Stripe::SignatureVerificationError => e
    # Invalid signature
    logger.error('MY_LOG: webhook Invalid signature')
    return status 400
  end

  logger.info("MY_LOG: EVENT: #{event['type']} #{event.id}")

  begin
    case event['type']
    when 'checkout.session.completed'
      logger.info('MY_LOG: case EVENT checkout.session.completed')
      checkout_session = event['data']['object']

      # TODO: fill in with your own logic
      logger.info("Fulfilling order for #{checkout_session.id}")
    when 'payment_intent.requires_action'
      logger.info('MY_LOG: case EVENT payment_intent.requires_action')
      payment_intent = event['data']['object']
      logger.info("MY_LOG: payment intent #{payment_intent}")
    else
      logger.error("MY_LOG: WTF event #{event['type']}")
    end
  rescue StandardError => e
    logger.error("MY_LOG: WTF #{e.inspect}")
    return status 200
  end

  return status 200
end

post '/create-checkout-session' do
  content_type 'application/json'

  session = Stripe::Checkout::Session.create(
    payment_method_types: %w[card boleto],
    payment_method_options: {
      boleto: {
        expires_after_days: 3
      }
    },
    line_items: [{
      price_data: {
        unit_amount: 2000,
        currency: 'brl',
        product_data: {
          name: 'Stubborn Attachments',
          images: ['https://i.imgur.com/EHyR2nP.png']
        }
      },
      quantity: 1
    }],
    mode: 'payment',
    success_url: YOUR_DOMAIN + '/success.html',
    cancel_url: YOUR_DOMAIN + '/cancel.html'
  )

  redirect session.url, 303
end
