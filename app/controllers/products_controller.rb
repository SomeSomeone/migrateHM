class ProductsController < ApplicationController

	include ProductsHelper
	require 'will_paginate/array'
	require 'net/http'

	def single
		

		
		@product_data=ProductDatum.find_by(article: params[:article])
	
		Net::HTTP.post_form URI('http://parse.yourhm.com.ua/allow_sizes.php'),
		               { 'id' => @product_data.id, 'article' => @product_data.article }

		@product = @product_data.product

		if @product.categories !=[]
			@pop=@product.get_pop
		end

		@product_datas = @product.product_datum
		@product_sizes = @product_data.product_product_sizes.sort_by{|ps| ps.size}
		color_id=@product_datas.collect(&:color_id)
		if color_id != [nil]
			@colors = Color.find(color_id)
		else
			@colors = []
		end
		
		@color_active = @product_data.color
		@products=Product.where(id: 
			CategoriesProducts.where(category_id: 
				CategoriesProducts.where(product_id: @product.id
					).select(:category_id)
				).select(:product_id)
			).limit(6)
		.order("RANDOM()")

		
		
			# $.ajax({
			#   type: 'POST',
			#   url: '',
			#   data: {'id':'<%=@product_data.id%>','':'<%=%>'}
			# });
	end
	def index



		@category=Category.all
		
		@main_category=@category.select{|e| e.category_id==nil}
		@params_cat=[ params[:categorie0] , params[:categorie1], params[:categorie2] ,params[:categorie3]].compact 



		helper=@category
		@cat=nil;
		@cat_active=[]

		@params_cat.each{ |cat_name|
			if helper.find{|e| e.url == cat_name}
				@cat=helper.find{|e| e.url == cat_name}
				helper=@category.select{|e| e.category_id==@cat.id}				
				@cat_active<<@cat
			else return
			end
		}

		@current_main_cat=@cat_active[0]||Category.find_by(url: @params_cat[0])||{}
		@current_cat = @cat_active[-1]||Category.find_by(url: @params_cat[-1])||{}
		

		
		@ChoizenColor = params[:colorWithNames]||[]
		@ChoizenSize = params[:sizes]||[]
		@Sort = params[:sort]


			@cat_for_product=[]
			if @cat
				@cat_for_product<<@cat
				helper=@category.select{|e| e.category_id==@cat.id}
				if helper !=[]
					helper.each do |c0|
						@cat_for_product<<c0
						helper1=@category.select{|e| e.category_id==c0.id}
						if helper1 !=[]
							helper1.each do |c1|
								@cat_for_product<<c1
								helper2=@category.select{|e| e.category_id==c1.id}
								if helper2 !=[]
									helper2.each do|c2|
										@cat_for_product<<c2
									end
								end
							end
						end
					end
				end
			end
			if @params_cat[0]=="sale" or @params_cat[0]=="Sale"
				@productDatums=ProductDatum.where(product_id:
					Product.where(id: 
						CategoriesProducts.where(category_id: 
							@cat_for_product
						).select(:product_id) , visible:true
					).ids
				).where.not(promotional_price: [0.0,0,nil]).select(:id,:article,:color_id,:product_id,:price,:promotional_price,:updated_at)
			else
				@productDatums=
					ProductDatum.where(id:	
						ProductProductSize.where(has:true , product_datum_id:
							ProductDatum.where(product_id:
								Product.where(visible:true , id: 
									CategoriesProducts.where(category_id: 
										@cat_for_product
									).select(:product_id) 
								).ids
							).ids
						).select(:product_datum_id)
					).select(:id,:article,:color_id,:product_id,:price,:promotional_price,:updated_at)

			end




		@SomeThingСhoose=false


		if @ChoizenColor!=[]
			@productDatums=@productDatums.where(color_id:
					Color.where(main_color_id: 
						MainColor.where(name: @ChoizenColor).ids
					).ids
				)
			@SomeThingСhoose=true
		end
	
		if @ChoizenSize!=[]
			@productDatums=@productDatums.where(id:
				ProductProductSize.where(product_size_id: 
					ProductSize.where(size: @ChoizenSize) , has:true
				).select(:product_id)
			)
			@SomeThingСhoose=true
		end
		
		if @Sort
			if @Sort == "PriceAsc"
				@productDatums = @productDatums.order(price: :asc)
			elsif @Sort == "PriceDesc"
				@productDatums = @productDatums.order(price: :desc)
			end 
		end
		if @SomeThingСhoose
			if params[:categorie1]
				@PossibleSizes=ProductSize.where(id: 
					ProductProductSize.where(product_id: 
						@productDatums.ids, has:true
					).select(:product_size_id)
				)||[]
			else
				@PossibleSizes=[]
			end	
		
			@PossibleColors=MainColor.where(id: 
				Color.where(id: @productDatums.collect(&:color_id).uniq ).select(:main_color_id)
			)||[]


			@productDatumsSize=@productDatums.size
		else
			if params[:categorie1]
				@PossibleSizes=Rails.cache.fetch("category/#{@current_cat.id}/PossibleSizes", expires_in: 1.hours) do
					ProductSize.where(id: 
						ProductProductSize.where(product_id: 
							@productDatums.ids, has:true
						).select(:product_size_id)
					)||[]
				end
			else
				@PossibleSizes=[]
			end	
			@PossibleColors=Rails.cache.fetch("category/#{@current_cat.id}/PossibleColors", expires_in: 1.hours) do 
				MainColor.where(id: 
					Color.where(id: @productDatums.collect(&:color_id).uniq ).select(:main_color_id)
				)||[]
			end
			@productDatumsSize=Rails.cache.fetch("category/#{@current_cat.id}/size", expires_in: 1.hours) do
			 @productDatums.size 
			end
		end


		@productDatumsAll = @productDatums.paginate(:page => params[:page], :per_page => 30)

	end
	def search




		@search = params[:search]||""
		#color
		if @search.strip == "" 
			@productsAll=[]
			@PossibleSizes=[]
			@PossibleColors=[]
		else
			@res=[]
			@res+=ProductDatum.where(color_id: 
				Color.where("name LIKE ?", "%#{@search}%")
				.collect(&:id)
			).collect(&:product_id)
			
			#имя (title) = ?", title.downcase
			@res+=Product.where("name LIKE ?", "%#{@search.downcase}%").collect(&:id)


			#артикл
			@res+=ProductDatum.where("article LIKE ?", "%#{@search}%").collect(&:product_id)

			#размер
			@res+=ProductDatum.where(id: 
				ProductProductSize.where(product_size_id: 
					ProductSize.where("size LIKE ?", "%#{@search}%")
					.collect(&:id)
				).collect(&:product_id)
			).collect(&:product_id)		
			#Категории
			@res+=CategoriesProducts.where(category_id: 
				Category.where("name LIKE ?", "%#{@search}%")
				.collect(&:id)
			).collect(&:id)

			
			@res=@res.each_with_object( {} ) {|e, h| h[e] ||= 0; h[e] += 1 }.sort_by {|o, ct| [-ct, o] }

			@ids=[]

			@res.each{|k| @ids<<k[0]}

			@productsAll=Product.where(id: @ids)


			@ChoizenColor = params[:colorWithNames]||[]
			@ChoizenSize = params[:sizes]||[]



			@PossibleSizes=ProductSize.where(id: 
				ProductProductSize.where(product_id: 
					ProductDatum.where(product_id: 
						@productsAll.collect(&:id)
					).collect(&:id), has:true
				).collect(&:product_size_id)
			)
		
			
			@PossibleColors=MainColor.where(id: 
				Color.where(id: 
					ProductDatum.where(product_id: 
						@productsAll.collect(&:id)
					).collect(&:color_id)
				).collect(&:main_color_id)
			)
		end
		@products=@productsAll.paginate(:page => params[:page], :per_page => 30)
	end

	def favourites
	end
	
	def test
	  respond_to do |format|
	  	product_datum = ProductDatum.find(params[:id])
	    product=product_datum.product
	    color=product_datum.color
	    photo=product_datum.photos.first
	    sizes = ProductSize.where( id: product_datum.product_product_sizes.where(has: true).collect(&:product_size_id)).collect{|d| {id: d.id,size: d.size}}

	    msg = { 
	    	:status => "ok",
	    	:message => "Success!",
	    	:html => "<b>...</b>",
	    	:name => product.name ,
	    	:src => photo.img(:original),
	    	:price => product_datum.get_price,
	    	:promotional_price => product_datum.get_promotional_price ,
	    	:article => product_datum.article ,
	    	:color => color.name,
	    	:sizes => sizes
	    }
	    format.json  { render :json => msg }
	  end
	end
	def sizes
	  respond_to do |format|
	  	product_datum = ProductDatum.find(params[:id])
	    sizes = ProductSize.where( id: product_datum.product_product_sizes.where(has: true).collect(&:product_size_id)).collect(&:size)
	    msg = {
	    	:status => "ok",
	    	:message => "Success!",
	    	:html => "<b>...</b>",
	    	:sizes => sizes,
	    	:price => product_datum.get_price,
	    	:promotional_price => product_datum.get_promotional_price
	    }
	    format.json  { render :json => msg }
	  end
	end
    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:img , :img_alt)
    end

end