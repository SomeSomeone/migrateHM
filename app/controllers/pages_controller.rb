class PagesController < ApplicationController
  
  def index
    

    @product_datum=
     ProductDatum.where(id:  
          ProductProductSize.where(has:true , product_datum_id:
              ProductDatum.where.not(promotional_price: [nil,0,0.0]).or(
                ProductDatum.where( id:
                  CategoriesProducts.where(category_id: 
                    Category.where.not(sale: [nil,0]).ids
                  ).select(:product_id)
                )
              ).select(:id)
            ).select(:product_datum_id)
    ).limit(8).order("RANDOM()")




    @baners=Baner.where.not(number:  nil).order(number:  :desc)
  end
  def page
    @pages=Page.where.not(order:  nil).order(order:  :desc)
    @page=Page.find_by(link: params[:link])
  end

  def search_results
  end

  def lockscreen
    render :layout => "empty"
  end

  def invoice
  end

  def invoice_print
    render :layout => "empty"
  end

  def login
    render :layout => "empty"
  end

  def login_2
    render :layout => "empty"
  end

  def forgot_password
      render :layout => "empty"
  end

  def register
    render :layout => "empty"
  end

  def internal_server_error
    render :layout => "empty"
  end

  def empty_page
  end

  def not_found_error
    render :layout => "empty"
  end

end
