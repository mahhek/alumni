require 'caller'
require 'cgi'
require 'lib/paypal_error_messages'
require "active_merchant"

# Controller with actions for doing DoDirectPayment API call. The name is chosen in consistent with other PayPal SDKs.

class DccController < ApplicationController

#  LNKPNT_STORE_NAME = '2134576890' # Your store name/number
#  puts "hehe"
#  puts File.dirname(__FILE__)
#  ActiveMerchant::Billing::LinkpointGateway.pem_file = File.read( File.dirname(__FILE__) + '/ltlprints-keypair.pem'  ) # Put your PEM file in the directory above this file
#  require 'money'

	include PayPalSDKCallers
	helper :campaigns

	skip_before_filter :require_no_ssl
	before_filter :require_ssl

	def require_ssl
		if RAILS_ENV == 'production' && !request.ssl?
			flash.keep
			redirect_to_self_with_protocol("https://")
			return false
		end
	end

	def pay
    @all = DonateWhatsThis.find(:all)
    if @all.size > 0
      @whats_this = @all.first.content
    else
      @what_this = ""
    end
		@campaign = Campaign.find(params[:campaign_id])
    @organization = @campaign.organization
    @funds = FundRaiser.find_all_by_organization_id(@organization.id)
		@donation_options = @campaign.organization.donation_options
		@user = logged_in_user
		@is_configured = !@campaign.organization.main_credential.nil?
		set_site_branding_from_campaign
		if @user
			@show_offline_option = (@user.has_role?('Administrator') || @user.is_org_admin_for(@campaign.organization))
		else
			@show_offline_option = false
		end
	end

	# DoDirectPayment API call

	def do_DCC
 

    puts "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    puts "=============?>>>>>>>>>>>>>#{params[:displayed_fund_text_box].inspect}"

    funds = FundRaiser.find_all_by_organization_id(Campaign.find_by_id(params[:campaign_id]).organization.id)
    amount_entered_by_user = get_amount_entered_by_user

    puts "-------------#{amount_entered_by_user}-----------------"

    @is_configured = true
		@campaign = campaign = Campaign.find(params[:campaign_id])
    set_site_branding_from_campaign
    
		if campaign
      once_transaction = true
      authorize_success = false
      session_array = []
      unless params[:displayed_fund_text_box].nil?
         
        for index in 0..params[:displayed_fund_text_box].size-1
          if params[:displayed_fund_text_box][index] != ""
            percentage_calculated_amount = ( (params[:displayed_fund_text_box][index]).to_f * amount_entered_by_user.to_f) / 100.to_f

            new_payment_object_and_setting_some_of_its_attributes(amount_entered_by_user, campaign, funds, index)
            unless @payment.valid?              
              setting_all_the_require_attributes_if_payment_not_valid(campaign)
              render :action => 'pay'
              return
            end

#            authorize_success = false
            
            if once_transaction == true
              if @organization.payment_processor == Organization::PAYPAL ## PAYPAL IMPLEMENTATION
                #-------------------------------------PAYPAL IMPLEMENTATION-----------------------------------------------
                authorize_success , once_transaction = whole_process_of_paypal_transaction(authorize_success,once_transaction)
                #-------------------------------------PAYPAL IMPLEMENTATION-----------------------------------------------
              elsif @organization.payment_processor == Organization::AUTHORIZE ## AUTHORIZE.NET IMPLEMENTATION
                #-------------------------------------AUTHORIZE.NET IMPLEMENTATION-----------------------------------------------
                authorize_error, authorize_success , once_transaction = whole_process_of_authorize_transaction(authorize_error ,authorize_success,once_transaction)
                #-------------------------------------AUTHORIZE.NET IMPLEMENTATION-----------------------------------------------
              end 
            end

            puts "authorize_error=>#{authorize_error.inspect}"

            if authorize_success && @transaction.success?
              puts "---------------========SUCCESS=========-----------"
              
              session[:dcc_response] = nil
              session[:authorize_response] = nil

              if @organization.payment_processor == Organization::PAYPAL
                puts @transaction.inspect
                puts @transaction.response["TRANSACTIONID"]
                puts percentage_calculated_amount
                puts @payment.fund_raiser.name
                #               session[:dcc_response] = @transaction.response
                session_array << {"id"=>@transaction.response["TRANSACTIONID"], "amount"=>percentage_calculated_amount , "fund_raiser_name"=>@payment.fund_raiser.name}
              elsif @organization.payment_processor == Organization::AUTHORIZE
                session_array << {"id"=>@transaction.params["transaction_id"], "amount"=>percentage_calculated_amount , "fund_raiser_name"=>@payment.fund_raiser.name}
                #session[:authorize_response] = {"id"=>@transaction.params["transaction_id"], "amount"=>amount_entered_by_user}
              end

              puts "YEA VALUE DB MAIN JA A GE===>>>#{percentage_calculated_amount}"
              @payment.amount = percentage_calculated_amount
              @payment.save!              
              sending_thanks_email_for_payment(campaign)
              
              campaign.initiated(:donate)
              contact = campaign.find_or_create_user_contact_for(campaign.creator, @payment.email)
              contact.donate!
              logger.debug "Contact: #{contact.inspect}"
            else

              puts "---------------========FAIL=========-----------"
              @user = logged_in_user
              if @organization.payment_processor == Organization::PAYPAL
             
                error_message = PaypalErrorMessages::DirectPaymentAPI[@transaction.response["L_ERRORCODE0"].first]
                error_message ||= "#{@transaction.response["L_LONGMESSAGE0"].first} (#{@transaction.response["L_ERRORCODE0"].first})"
                logger.debug "Transaction failed: #{@transaction.inspect}"
                @payment.errors.add_to_base(error_message)
              elsif @organization.payment_processor == Organization::AUTHORIZE
             
                if authorize_success
                  @payment.errors.add_to_base(@transaction.message.to_s)
                else
                  @payment.errors.add_to_base(authorize_error)
                end
              end
            end 
          end
        end
      end
      session[:authorize_response] = session_array
     
     
      puts "*********************************************"
      if authorize_success == false
        
        puts "rendering"
        @funds = FundRaiser.find_all_by_organization_id(campaign.organization_id)
        @donation_options = @campaign.organization.donation_options        
        render :action => 'pay'
      else#TO B DELETED
        redirect_to :protocol => "http://", :controller => 'dcc', :action => 'thanks', :campaign_id => campaign.id#TO B DELETED
      end

		else
			@user = logged_in_user
      
      
			@payment.errors.add_to_base("Campaign Must be selected")
      @funds = FundRaiser.find_all_by_organization_id(@organization.id)
      puts "rendering"
			render :action => 'pay'
		end
	end
  
  # TODO Comment
  def whole_process_of_authorize_transaction(authorize_error,authorize_success,once_transaction)
#    gateway = ActiveMerchant::Billing::Base.gateway(:linkpoint).new(:login => "LNKPNT_STORE_NAME", :test => true)
#    puts gateway.inspect


#    ActiveMerchant::Billing::Base.mode = :test
    gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new( 
      :login  => @organization.authorize_credential.api_login_id,
      :password => @organization.authorize_credential.transaction_key
#      :login  => "54PB5egZ",:password => "48V258vr55AE8tcg"
#      :login  => "TestMerchant",:password => "password"      
    )
    puts gateway.inspect
    credit_card = credit_card_new_object_creation
    
    if credit_card.valid?
      authorize_error, authorize_success , once_transaction  = charge_amount_and_make_aurthorize_success_false(authorize_error,authorize_success, credit_card, gateway,once_transaction)
      puts "RIGHT AFTER GETTING VALUE WHEN RETURNING=>#{authorize_success}"
    else
      puts "AUTHORIZE KA CREDIT CARD VALID NAI HAI"
      authorize_success = false
      authorize_error = credit_card.errors.to_a.flatten.join " "
    end
    return authorize_error, authorize_success , once_transaction
  end

  # TODO Comment
  def whole_process_of_paypal_transaction(authorize_success,once_transaction)

    fake_transaction = params[:fake_paypal_call] == "1" || @payment.offline?
    transaction_hash = creating_transaction_hash_for_paypal

    if !fake_transaction
      @caller =  PayPalSDKCallers::Caller.new(@organization.main_credential,false)
      @transaction = @caller.call(transaction_hash)
      authorize_success = true
      once_transaction = false
    else
      logger.warn "Faking call to paypal"
      @transaction = PayPalSDKCallers::Transaction.new("ACK" => "Success", "AMT" => @payment.amount,
        "TRANSACTIONID" => "TESTING")
      authorize_success = true
      once_transaction = false
      logger.warn "*"*50
      logger.warn "PAYMENT:#{transaction_hash.inspect}"
      logger.warn "*"*50
      puts "********************#{@transaction.inspect}"
    end
    return authorize_success ,once_transaction
  end

  def thanks
    #	  if session[:dcc_response]
    #      puts "i m d c c"
    #  		puts response = session[:dcc_response]
    #  		puts @transactionId = response["TRANSACTIONID"]
    #  		puts @amount = response["AMT"]
    #  	//elsif session[:authorize_response]
    #        response[] = session[:authorize_response]
    #      @transactionId = response["id"]
    #  		@amount = response["amount"]
    #  	end
		@campaign = Campaign.find(params[:campaign_id])
		set_site_branding_from_campaign
	end

  # TODO Comment
  def sending_thanks_email_for_payment(campaign)
    begin
      Notification.deliver_thanks_for_payment(@payment, campaign)
    rescue Exception=>e
    end
  end

  # TODO Comment
  def creating_transaction_hash_for_paypal
    transaction_hash = {
      :method          => 'DoDirectPayment',
      :amt             => @payment.amount,
      :currencycode    => 'USD',
      :creditcardtype  => @payment.creditcard_type,
      :acct            => @payment.acct,
      :firstname       => @payment.first_name.to_s,
      :lastname        => @payment.last_name,
      :street          => @payment.address1,
      :city            => @payment.city,
      :state           => @payment.state,
      :zip             => @payment.zip.to_s,
      :countrycode     => 'US',
      :expdate         => @payment.expire_date,
      :cvv2            => @payment.cvv.to_s,
      :paymentaction   => 'Sale'
    }
    transaction_hash
  end

  # TODO Comment
  def new_payment_object_and_setting_some_of_its_attributes(amount_entered_by_user, campaign, funds, index)
    @payment = Payment.new(params[:payment])
    @payment.user_id = logged_in_user.id if logged_in_user
    @payment.campaign_id = campaign.id
    @payment.amount = amount_entered_by_user
    puts "THIS VALUE IS TO BE DEDUCTED FIRST AND ONLY ONCE<<<<<<<<<<<<<<<<<<<<<<<#{@payment.amount}"
    @payment.fund_raiser_id = funds[index].id
    @payment.sanitize
    @organization = campaign.organization
    @donation_options = @organization.donation_options
  end
  
  # TODO Comment
  def setting_all_the_require_attributes_if_payment_not_valid(campaign)
    puts "PAYMENT VALUES ARE NOT UPTO THE MARK"
    @campaign = campaign
    @donation_options = @campaign.organization.donation_options
    set_site_branding_from_campaign
    @user = logged_in_user
    if @user
      @show_offline_option = (@user.has_role?('Administrator') || @user.is_org_admin_for(@campaign.organization))
    else
      @show_offline_option = false
    end
    @funds = FundRaiser.find_all_by_organization_id(@organization.id)
  end

  # TODO Comment
  def charge_amount_and_make_aurthorize_success_false(authorize_error,authorize_success, credit_card, gateway,once_transaction)
    charge_amount = @payment.amount_in_cents
    options = setting_options_for_transaction
    puts "---------------------------------1------------------------------------"
    puts charge_amount.inspect
    puts credit_card.inspect
    puts options.inspect

    @transaction = gateway.authorize(charge_amount, credit_card, options)
    puts "---------------------------------2------------------------------------"
    puts @transaction.inspect
    puts"----------------------------------3------------------------------------"
    if @transaction.success?
      gateway.capture(charge_amount, @transaction.authorization).inspect
      puts "TRANSACTION HO GAE HIA , CONGRATSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"
      once_transaction = false
      authorize_success = true
    else
      puts "TRANSACTION cancel"
      authorize_error = @transaction.params["response_reason_text"].to_s
      puts authorize_error
    end
    
    # logger.warn "*"*50
    # logger.warn "AUTHORIZE:#{@transaction.inspect}"
    # logger.warn "*"*50
    return authorize_error,authorize_success,once_transaction
  end

  # TODO Comment
  def setting_options_for_transaction
    options = {:address => {}, :billing_address => {
        :name => @payment.full_name,
        :address1 => @payment.address1,
        :city => @payment.city,
        :state => @payment.state,
        :zip => @payment.zip,
        :country => 'US'
      }}
#  options = {
#        :order_id => '1234', # this is required for LinkPoint, if it's blank, LinkPoint will create an order id for you
#        :subtotal => 950,
#        :tax => 50,
#        :address => {
#          :address1 => '1 Show Me the Money Blvd',
#          :city => 'Salt Lake City',
#          :state => 'UT',
#          :country => 'US',
#          :zip => '84000',
#          :phone => '555-555-5555'
#        },
#        :shipping_address => {}, # if you don't put this in, it will be populated with the :address
#        :email => 'mrhamidraza@hotmail.com'
#      }
    options
  end

  # TODO Comment
  def credit_card_new_object_creation
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :type               => @payment.authorize_type,
      :number             => @payment.acct,
      :verification_value => @payment.cvv.to_s,
      :month              => @payment.expire_month,
      :year               => @payment.expire_year,
      :first_name         => @payment.first_name,
      :last_name          => @payment.last_name
    )
    credit_card
  end

  # TODO Comment
  def get_amount_entered_by_user
    puts "=>#{params[:payment][:user_entered_amount]}"
    puts "=>#{params[:payment][:custom_amount]}"
    if params[:payment][:custom_amount]
      puts "1"
      amount_entered_by_user =  params[:payment][:custom_amount] == "" ?  params[:payment][:user_entered_amount] : params[:payment][:custom_amount]
    else
      puts "2"
      amount_entered_by_user = params[:payment][:user_entered_amount]
    end

    amount_entered_by_user.to_i
  end

	

	private

	def payment_from_params
		payment_params = {
			:amount => params[:dcc][:amount],
			:ok_to_send => params[:sharing_ok],
			:campaign_id => params[:campaign_id],
			:email => params[:dcc][:email],
			:i_agree => params[:dcc][:i_agree],
			:phone => params[:phone],
		}
		if params[:process_anonomous] != 'true'
			payment_params[:user_id] = logged_in_user ? logged_in_user.id : 0
		end
		Payment.new(payment_params)
	end

end


