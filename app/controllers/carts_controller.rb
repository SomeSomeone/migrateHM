class CartsController < ApplicationController
	require 'net/http'
	before_action :authenticate_user! , :only => [:create_order, :diver , :order ]
	protect_from_forgery with: :null_session

	def order_create
		puts params
		@order=Order.new(order_params)
		@order.user=current_user
		data = JSON.parse order_params[:json]
	    
		@order.status = 'Ожидает платежа'
	    
	      	@address = Address.where(user: current_user)[0]||Address.new
	      	
	      	@address.city=order_address_params["city"]||@address.city
	      	@address.post_index=order_address_params["post_index"]||@address.post_index
	      	@address.user=@order.user
	      	@address.save
	      	@order.address_ref = @address
	      	@order.address_city = @address.city
	      	@order.address_post_index = @address.post_index
	      	@order.address=@address.city+" "+@address.post_index

	    respond_to do |format|
	      if @order.save
	      	@order.sum=0
	      	@order.polka_sum=0
	      	if data && data!=[]
		      	data.each { |d|
		      		a=OrdersProductDatum.new
		      		a.order_id=@order.id
		      		a.count=d['count']
		      		a.product_datum_id=d['id']
		      		a.product_size=ProductSize.find_by(size: d['size'])
		      		pd = ProductDatum.find(d['id'])
		      		if pd.promotional_price?
		      			@order.sum += pd.get_promotional_price*a.count
		      		else
		      			@order.sum += pd.get_price*a.count
		      		end
		      		if pd.promotional_price>0
		      			@order.polka_sum+= pd.promotional_price*a.count
		      		else
		      			@order.polka_sum+= pd.price*a.count
		      		end
	      			

		      		
		      		a.save
		      	}
	      	end
	      	persent=Campaign.find_by(code: order_params[:campaign_code])
	      	if Order.find_by(user: current_user).nil?
	      		helper_sale=true
	      	end
	      	if persent and persent.actual? and (Order.find_by(user: current_user , campaign_id: persent.id)).nil?
	      		persent.get_one
      			@order.sum=@order.sum*(1-persent.value/100)
      			@order.campaign_id=persent.id
	      	end

	      	if @user.money>0
	      		if @user.money-3>@order.sum
	      			@user.money-=@order.sum
	      			@order.sum=0
	      			@order.status="Принят"
	      		else
	      			@order.sum-=@user.money
	      			@user.money=0
	      		end
	      		@user.save
	      	end
	      	@order.save
	      	if helper_sale
	      		@campaing=Campaign.new
	      		@campaing.code = (Time.now.to_f*1000).to_i
	      		@campaing.value = 10
	      		@campaing.number = 1
	      		@campaing.inf_period = true
	      		@campaing.save
		      	RootMailer.cart_email(@user , @order , @campaing).deliver_now
	      	else
	      		RootMailer.cart_email(@user , @order , false).deliver_now	
	      	end
	      	RootMailer.clone_email(@order , "inbrogues1@gmail.com" ).deliver_now
	      	RootMailer.clone_email(@order , "alena.lazutkina@gmail.com" ).deliver_now
	      	if params[:money][:money]=="liqpay" and @order.sum>0
	      		@order.cash_method = true
		        format.html {redirect_to controller:"carts", action:"liqpay_request", id:  @order.id , notice: 'Color was successfully created.' }
		        format.json { render :show, status: :created, location: @order }
	      	else

				uri = URI('http://app.bsg.hk/sendsms')
				params = { "user" => "inbrogues1@gmai", "pwd" => "bqfD2k6b","sadr" => "Your HM" ,"dadr" => @user.tel.to_s ,
					"text" => 'Вы оформили заказ. Оплатите на карту 4149437832389686 сумму '+@order.sum.to_s+' грн ' }
				uri.query = URI.encode_www_form(params)

				res = Net::HTTP.get_response(uri)
				puts res.body if res.is_a?(Net::HTTPSuccess)
				@order.cash_method = false
		        

		        format.html {redirect_to controller:"carts", action:"order", id:  @order.id , notice: 'Color was successfully created.' }
		        format.json { render :show, status: :created, location: @order }
	      	end
	      else
	        format.html { render :new }
	        format.json { render json: @order.errors, status: :unprocessable_entity }
	      end
	    end
	end
	def liqpay_request
		@order=Order.find(params[:id])
		@liqpay_request = Liqpay::Request.new(	:amount => @order.sum,
												:currency => 'UAH',
												:order_id => @order.id,
												:description => 'Ваш заказ',
												server_url: 'https://yourhm.com.ua/liqpay_payment',
												:sandbox => 1
												)
		#:server_url => liqpay_payment 
	end

	def liqpay_payment 
		@liqpay_response = Liqpay::Response.new(params) 
		@order=Order.find(@liqpay_response.order_id)
		if @liqpay_response.success? && @order && @order.sum.to_f==@liqpay_response.amount.to_f
			# обработать платеж 
			@order.status="Принят"
		else 
			@order.status=""
			unless @liqpay_response.success?
				@order.status="Ошибка : "
			end
			unless @liqpay_response.amount == @order.sum
				@order.status+= "Пришло = " +@liqpay_response.amount.to_s+" а должно было "+@order.sum.to_s
			end
		end 
		@order.save
		format.html {redirect_to controller:"carts", action:"order", id:  @order.id , notice: 'Color was successfully created.' }
        format.json { render :show, status: :created, location: @order }
	end
	def diver
		@payment=payment_method
		@order=Order.new()

		@addresses=Address.where(user: @user)
		unless  @addresses[0]
			@address=Address.new(user: @user)
			@address.save
		else
			@address=@addresses[0]
		end
		@order.address_ref=@address
	end
	def order_activate
		respond_to do |format|
			@order=Order.find(params[:id])
			@order.bool_factor=true
			@order.status="Подлежит проверке"
			@order.save
			 msg = { 
		    	:status => "ok",
		    	:message => "Success!",
		    	:html => "<b>...</b>"
		    }
		    format.json  { render :json => msg }
		end
	end
	def test
	  respond_to do |format|
      	persent=Campaign.find_by(code: params["campaign_code"].to_s)

      	if persent and persent.actual? and (Order.find_by(user: @user , campaign_id: persent.id)).nil?
		    msg = { 
		    	:status => "ok",
		    	:message => "Success!",
		    	:html => "<b>...</b>",
		    	:value => persent.value
		    }
		else
		    msg = { 
		    	:status => "ok",
		    	:message => "Error",
		    	:html => "<b>...</b>"
		    }
		end
	    format.json  { render :json => msg }

	  end
	end
	def order_params
   		params.require(:order).permit(:json , :campaign_code)
   	end
   	def order_address_params
   		params.require(:order).require(:address_ref_attributes)
    end
    def payment_method
    	[ [ "Оплата через liqpay (приват 24)", "liqpay" ] ,
    	  [ "Оплата через терминал или кассу банка (получить реквизиты)" , "privat24"] ]
    end
end
