class RootMailer < ApplicationMailer
	def welcome_email(user)
	    @user = user
	    mail(to: @user.email, subject: 'Приветсвуем в семье HM')
	end
	def clone_email(cart , email)
	    @order = cart
	    mail(to: email , subject: "Новый заказ ! (#{@order.id})")	
	end
	def cart_email(user , cart , campaing)
		@order = cart
		@user = user
		@campaing = campaing 
	    mail(to: @user.email, subject: 'Мы приняли ваш заказ')
	end
	def status_email(user)
		@user = user
	    mail(to: @user.email, subject: 'Статус вашего заказа обновлён')	
	end


end
