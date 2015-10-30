require 'paycorp_rails/version'

# Paycorp internet payment gateway
class PaycorpRails
    # Get the credentials and store them in the memory
    def initialize(options)
        @options = options
    end

    # Talk to Paycorp and initiate the payment
    def initiate_payment(payment_options)
        json = (create_init_params(payment_options)).to_json
        hash = gen_hash(json, @options[:hmac])
        response = set_request_url(@options[:auth_token], hash, json)
        JSON.parse(response.read_body)
    end

    # Send the payment confirmation to Paycorp to complete the transaction
    def complete_payment(payment_options)
        json = (create_complete_params(payment_options)).to_json
        hash = gen_hash(json, @options[:hmac])
        response = set_request_url(@options[:auth_token], hash, json)
        JSON.parse(response.read_body)
    end

    private

    # Talk to paycorp
    def set_request_url(auth_token, hash, json)
        url = URI("#{@options[:endpoint]}")

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(url)
        request['authtoken'] = "#{auth_token}"
        request['hmac'] = "#{hash}"
        request['content-type'] = 'application/json'
        request.body = "#{json}"

        http.request(request)
    end

    # Encrypt the data
    def gen_hash(json, hmac)
        OpenSSL::HMAC.hexdigest('sha256', hmac, json)
    end

    def create_complete_params(payment_options)
        {
            "version": '1.04',
            "msgId": "#{payment_options[:msg_id]}", # Make it unique and store in order db
            "operation": 'PAYMENT_COMPLETE',
            "requestDate": "#{Time.now.to_formatted_s(:db)}",
            "validateOnly": false,
            "requestData": {
                "reqid": payment_options[:reqid]
            }
        }
    end

    def create_init_params(payment_options)
        {
            "version": '1.04',
            "msgId": "#{payment_options[:msg_id]}", # Make it unique and store in order db
            "operation": 'PAYMENT_INIT',
            "requestDate": "#{Time.now.to_formatted_s(:db)}",
            "validateOnly": false,
            "requestData": {
                "clientId": @options[:client_id].to_i,
                "clientIdHash": '',
                "transactionType": 'PURCHASE',
                "transactionAmount": {
                    "totalAmount": 0,
                    "paymentAmount": payment_options[:amount].to_i,
                    "serviceFeeAmount": 0,
                    "currency": payment_options[:currency]
                },
                "redirect": {
                    "returnUrl": payment_options[:return_url],
                    "cancelUrl": '',
                    "returnMethod": 'GET'
                },
                "clientRef": payment_options[:user_id],
                "comment": '',
                "tokenize": false,
                "tokenReference": '',
                "cssLocation1": payment_options[:css_url],
                "cssLocation2": '',
                "useReliability": true,
                "extraData": {
                    "orderId": payment_options[:order_id] # optional info
                }
            }
        }
    end
end
