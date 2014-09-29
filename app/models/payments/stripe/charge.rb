class Payments::Stripe::Charge < ActiveRecord::Base
  self.table_name = 'stripe_charges' # use namespaced table
  include Rails.application.routes.url_helpers
  has_paper_trail

  # belongs_to :user

  validates :amount, numericality: { greater_than: 0 }

  monetize :amount_cents

  def charge options
    fail ArgumentError unless options[:amount] >= 50 && # 50 cents minimum
      (!!options[:token] ^ !!options[:customer]) # boolean-coerced xor

    begin
      charge = Stripe::Charge.create(
        amount:          options[:amount], # cents
        currency:        'usd',
        card:            options[:token], # obtained with Stripe.js
        customer:        options[:customer], # either card xor customer
        description:     options[:description],
        capture:         options[:capture] || true,
        application_fee: options[:application_fee],
        expand:          %w(customer invoice)
      )
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]

      logger.debug "Status is: #{e.http_status}"
      logger.debug "Type is: #{err[:type]}"
      logger.debug "Code is: #{err[:code]}"
      # param is '' in this case
      logger.debug "Param is: #{err[:param]}"
      logger.debug "Message is: #{err[:message]}"
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
    rescue => e
      # Something else happened, completely unrelated to Stripe
    end
  end

  def refund charge_id
    # options: amount (default all), refund_application_fee
    charge = Stripe::Charge.retrieve(charge_id)
    charge.refund
  end

  def capture charge_id
    # options: amount (default all, max authorized), application_fee
    charge = Stripe::Charge.retrieve(charge_id)
    charge.capture
  end
end
