require 'test_helper'

class RemotePaycometTest < Test::Unit::TestCase
  # Las tarjetas de prueba son las siguientes:
  # - 4539232076648253
  # - 5445288852200883
  # - 6011454638812167
  # - 377960095195350

  # Para todas estas tarjetas de prueba: mes 05 y año: año actual + 1. CVV: 123
  # Si se obtiene un error 102 querrá decir que los datos de tarjeta/mes/año/cvv enviados no son correctos.

  def setup
    @SUCCESS_MESSAGE = 'Sin error'
    @USER_NOT_FOUND_MESSAGE = 'Usuario no encontrado. Contacte con PAYCOMET'

    @gateway = PaycometGateway.new({
      login: "xxx",
      secret_key: "xxx",
      terminal: "1",
      jet_id: "xxx",
      ip: "127.0.0.1"
    })
    @credit_card = CreditCard.new(
        :month              => '5',
        :year               => '2021',
        :number             => '4539232076648253',
        :verification_value => '123'
      )
    @credit_card_jet_token = "xxx"
    @amount = 1300
    @user_payment_token = 'xxx|xxx'
    @invalid_user_payment_token = 'xxx|xxx'
  end

  def test_successful_add_user
    options = {}
    response = @gateway.add_user(@credit_card, options)
    assert_success response
    assert_equal @SUCCESS_MESSAGE, response.message
    assert_valid_user_payment_token response
  end

  def test_successful_add_user_token
    options = {}
    response = @gateway.add_user_token(@credit_card_jet_token, options)
    assert_success response
    assert_equal @SUCCESS_MESSAGE, response.message
    assert_valid_user_payment_token response
  end

  def test_successful_info_user
    options = {}
    response = @gateway.info_user(@user_payment_token, options)
    assert_equal @SUCCESS_MESSAGE, response.message
    assert_success response
    assert_not_nil response.params['ds_merchant_pan']
    assert_not_nil response.params['ds_card_brand']
    assert_not_nil response.params['ds_card_type']
    assert_not_nil response.params['ds_card_i_country_iso3']
    assert_not_nil response.params['ds_expirydate']
    assert_not_nil response.params['ds_card_hash']
    assert_not_nil response.params['ds_card_category']
    assert_not_nil response.params['ds_sepa_card']
  end

  def test_successful_remove_user
    options = {}
    response = @gateway.remove_user(@user_payment_token, options)
    assert_equal @SUCCESS_MESSAGE, response.message
    assert_success response
  end

  def test_successful_purchase
    options = {
      order_id: "#{rand(1000)}"
    }
    response = @gateway.purchase(@amount, @user_payment_token, options)
    assert_equal @SUCCESS_MESSAGE, response.message
    assert_success response
    assert_not_nil response.params['ds_merchant_amount']
    assert_not_nil response.params['ds_merchant_currency']
    assert_not_nil response.params['ds_merchant_cardcountry']
    assert_valid_order_auth_token response
  end

  def test_successful_purchase_with_more_options
    options = {
      order_id: "#{rand(1000)}",
      description: "This is a product description",
      owner: "This is a transaction description",
      scoring: 10, # This is a risk scoring value (0-100)
      client_data: {
        field1: "client_data is a JSON value with info about client",
        field2: "Another client info field"
      }.to_json,
      merchant_descriptor: "merchant info for invoice"
      #sca_exception: ""
      #trx_type: ""
      #escrow_targets: ""
      #user_interaction: ""
    }
    response = @gateway.purchase(@amount, @user_payment_token, options)
    assert_equal @SUCCESS_MESSAGE, response.message
    assert_success response
    assert_not_nil response.params['ds_merchant_amount']
    assert_not_nil response.params['ds_merchant_currency']
    assert_not_nil response.params['ds_merchant_cardcountry']
    assert_valid_order_auth_token response
  end

  def test_failed_purchase
    options = {
      order_id: "#{rand(1000)}"
    }
    response = @gateway.purchase(@amount, @invalid_user_payment_token, options)
    assert_failure response
    assert_equal @USER_NOT_FOUND_MESSAGE, response.message
  end

  def test_successful_authorize_and_capture
    options = {
      order_id: "#{rand(1000)}"
    }
    auth = @gateway.authorize(@amount, @user_payment_token, options)
    assert_success auth

    options = {
      user_payment_token: @user_payment_token
    }
    assert capture = @gateway.capture(@amount, auth.authorization, options)
    assert_success capture
    assert_equal @SUCCESS_MESSAGE, capture.message
  end

  def test_failed_authorize
    options = {
      order_id: "#{rand(1000)}"
    }
    response = @gateway.authorize(@amount, @invalid_user_payment_token, options)
    assert_failure response
    assert_equal @USER_NOT_FOUND_MESSAGE, response.message
  end

  def test_partial_capture
    options = {
      order_id: "#{rand(1000)}"
    }
    auth = @gateway.authorize(@amount, @user_payment_token, options)
    assert_success auth

    options = {
      user_payment_token: @user_payment_token
    }
    capture = @gateway.capture(@amount-1, auth.authorization, options)
    assert_success capture
  end

  def test_failed_capture
    options = {
      user_payment_token: @user_payment_token
    }
    response = @gateway.capture(@amount, 'x|x', options)
    assert_failure response
    assert_equal 'No se pudo encontrar la preautorización', response.message
  end

  def test_successful_refund
    options = {
      order_id: "#{rand(1000)}"
    }
    purchase = @gateway.purchase(@amount, @user_payment_token, options)
    assert_success purchase

    options = {
      user_payment_token: @user_payment_token
    }
    refund = @gateway.refund(@amount, purchase.authorization, options)
    assert_success refund
    assert_equal @SUCCESS_MESSAGE, refund.message
  end

  def test_partial_refund
    options = {
      order_id: "#{rand(1000)}"
    }
    purchase = @gateway.purchase(@amount, @user_payment_token, options)
    assert_success purchase

    options = {
      user_payment_token: @user_payment_token
    }
    refund = @gateway.refund(@amount-1, purchase.authorization, options)
    assert_success refund
  end

  def test_failed_refund
    options = {
      user_payment_token: @user_payment_token
    }
    response = @gateway.refund(@amount, 'x|x', options)
    assert_failure response
    assert_equal 'Operación anterior no encontrada. No se pudo ejecutar la devolución', response.message
  end

  def test_successful_void
    options = {
      order_id: "#{rand(1000)}"
    }
    auth = @gateway.authorize(@amount, @user_payment_token, options)
    assert_success auth

    options = {
      user_payment_token: @user_payment_token,
      amount: @amount
    }
    void = @gateway.void(auth.authorization, options)
    assert_success void
    assert_equal @SUCCESS_MESSAGE, void.message
  end

  def test_failed_void
    options = {
      user_payment_token: @user_payment_token,
      amount: @amount
    }
    response = @gateway.void('x|x', options)
    assert_failure response
    assert_equal 'No se pudo encontrar la preautorización', response.message
  end

  def test_successful_verify
    options = {
      order_id: "#{rand(1000)}",
      user_payment_token: @user_payment_token,
      amount: @amount
    }
    response = @gateway.verify(@user_payment_token, options)
    assert_success response
    assert_match %r{#{@SUCCESS_MESSAGE}}, response.message
  end

  def test_failed_verify
    options = {
      order_id: "#{rand(1000)}",
      user_payment_token: @user_payment_token,
      amount: @amount
    }
    response = @gateway.verify('x|x', options)
    assert_failure response
    assert_match %r{#{@USER_NOT_FOUND_MESSAGE}}, response.message
  end

  def test_invalid_login
    gateway = PaycometGateway.new(
      login: "xxx",
      secret_key: 'xxx',
      terminal: '1',
      ip: '127.0.0.1'
    )

    options = {
      order_id: "#{rand(1000)}"
    }
    response = gateway.purchase(@amount, @user_payment_token, options)
    assert_failure response
    assert_match %r{Campo DS_MERCHANT_MERCHANTCODE incorrecto}, response.message
  end

  def test_dump_transcript
    # This test will run a purchase transaction on your gateway
    # and dump a transcript of the HTTP conversation so that
    # you can use that transcript as a reference while
    # implementing your scrubbing logic.  You can delete
    # this helper after completing your scrub implementation.
    options = {
      order_id: "#{rand(1000)}"
    }
    dump_transcript_and_fail(@gateway, @amount, @user_payment_token, options)
  end

  def test_transcript_scrubbing
    options = {
      order_id: "#{rand(1000)}"
    }
    transcript = capture_transcript(@gateway) do
      @gateway.purchase(@amount, @user_payment_token, options)
    end
    transcript = @gateway.scrub(transcript)
    assert_scrubbed(@user_payment_token.split('|').last, transcript)
  end

  private

  def assert_valid_user_payment_token(response)
    assert_not_nil response.params['ds_iduser']
    assert_not_nil response.params['ds_token_user']
    assert_not_nil response.authorization
    assert_equal response.authorization, "#{response.params['ds_iduser']}|#{response.params['ds_token_user']}"
  end

  def assert_valid_order_auth_token(response)
    assert_not_nil response.params['ds_merchant_order']
    assert_not_nil response.params['ds_merchant_authcode']
    assert_not_nil response.authorization
    assert_equal response.authorization, "#{response.params['ds_merchant_order']}|#{response.params['ds_merchant_authcode']}"
  end

end
