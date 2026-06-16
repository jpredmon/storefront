class Admin::ProductsController < Admin::BaseController
  def index
    @products = Product.order(:name)
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_products_path, notice: "Product created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to admin_products_path, notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Product.find(params[:id]).destroy
    redirect_to admin_products_path, notice: "Product deleted."
  end

  private

  def product_params
    params.require(:product).permit(:name, :description, :price, :image_url)
  end
end
