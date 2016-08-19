class VouchersController < ApplicationController
  before_action :set_voucher, only: [:show, :edit, :update, :destroy]

  def input_wizard_1
  	#if params[date] exists, save it to dateholder 
  	#else if params[dateholder] exists, save it to dateholder 
  	#else, default value is today
  	set_dateholder
  end
  def process_input_wizard_1
    set_dateholder
    
    input=params['input'];
    vouchers_created=0

    #parse input
    lines=input.split("\n");
    data=[];
    lines.each do |line|
      #validate line is not empty, ignore
      next if line.strip==""
      
      #validate format
      #"--" is separator description and amount
      #if separator not found, error
      #if(strpos(line,"--")===false)
      if(line.scan(/(?=#{"--"})/).count!=3)
        message="Incorrect format: "+line;
        flash[:alert] = message
        flash[:meta] = input
        return redirect_to(:back) 
      end
      
      #separate description from value
      segments=line.split("--");
      no=segments[0].strip;
      payee=segments[1].strip;
      desc=segments[2].strip;
      value=segments[3].strip;
      
      #validate that voucher number exists
      if(no=="")
        message="Please enter a voucher number for: "+line;
        flash[:alert] = message
        flash[:meta] = input
        return redirect_to(:back) 
      end

      #validate that payee exists
      if(payee=="")
        message="Please enter a payee for: "+line;
        flash[:alert] = message
        flash[:meta] = input
        return redirect_to(:back) 
      end
      
      #validate that description exists
      if(desc=="")
        message="Please enter a description for: "+line;
        flash[:alert] = message
        flash[:meta] = input
        return redirect_to(:back) 
      end

      #validate that value exists
      if(value=="")
        message="Please enter a price for: "+line;
        flash[:alert] = message
        flash[:meta] = input
        return redirect_to(:back) 
      end

      #validate that value is a number
      if(!value.is_number?)
        message="Not a number: "+value+" in "+line;
        flash[:alert] = message
        flash[:meta] = input
        return redirect_to(:back) 
      end
      
      #all checks passed 
      #save data
      voucher = Voucher.new;
      voucher.date = @dateholder.date
      voucher.no = no
      voucher.payee = payee
      voucher.description = desc
      voucher.amount = value
      voucher.save
      vouchers_created+=1
    end
            
    message=vouchers_created.to_s+" vouchers successfully created";
    flash[:alert] = message
    redirect_to vouchers_input_wizard_1_path+"?date="+@dateholder.date.to_s 
  end
  def input_wizard_2
  end
  def process_input_wizard_2
    set_dateholder
    redirect_to vouchers_input_wizard_2_path+"?date="+@dateholder.date.to_s 
  end
  def search
    searchkeys = params['searchstring']
    searchkeys ||= ""
    searchkeys = searchkeys.split(" ")
    
    if searchkeys.count==0
      @vouchers = []
    else
      @vouchers = Voucher.all
      searchkeys.each do |key|
        @vouchers = @vouchers.where("no = \"#{key}\" or description like \"%#{key}%\" or payee like \"%#{key}%\"")
      end
    end
      
    render :layout => false if params['fragment']
  end
  
  def editNo
    voucher=Voucher.find(params['id'])
    voucher.no=params['no']
    voucher.save
    redirect_to vouchers_dashboard_path+"?date="+voucher.date.to_s 
  end
  
  def editAmount
    voucher=Voucher.find(params['id'])
    voucher.amount=params['amount']
    voucher.save
    redirect_to vouchers_dashboard_path+"?date="+voucher.date.to_s 
  end
  
  def dashboard

    #load accounts
    @accounts= VoucherAccount.all
      	
    #group accounts into columns
    @columncount=4.0;
  	@accountgroups=[];
  	@accountspergroup=(@accounts.count/@columncount).ceil;
  	(0...@accountspergroup).each do |i|
  	  (0...@columncount).each do |j|
    	  @accountgroups[j] ||= []
  	    @accountgroups[j].push(@accounts[j*@accountspergroup+i]);
  	  end
  	end
  	
  	#if params[date] exists, save it to dateholder 
  	#else if params[dateholder] exists, save it to dateholder 
  	#else, default value is today
  	set_dateholder

    #load vouchers from database to be displayed
    @vouchers =Voucher.where(date: @dateholder.date).order(:voucher_account_id)

    #calculate totals
    @total=0;
    @vouchers.each do |v|
      @total+=v.amount
    end
  end
  
  def help
  end

  # GET /vouchers
  # GET /vouchers.json
  def index
    @vouchers = Voucher.all
  end

  # GET /vouchers/1
  # GET /vouchers/1.json
  def show
  end

  # GET /vouchers/new
  def new
    @voucher = Voucher.new
    if params['voucher_account_id'] 
      @voucher.voucher_account_id=params['voucher_account_id']
    end
  end

  # GET /vouchers/1/edit
  def edit
    @accounts = VoucherAccount.all
  end

  # POST /vouchers
  # POST /vouchers.json
  def create
    @voucher = Voucher.new(voucher_params)

    respond_to do |format|
      if @voucher.save
        format.html { redirect_to @voucher, notice: 'Voucher was successfully created.' }
        format.json { render :show, status: :created, location: @voucher }
      else
        format.html { render :new }
        format.json { render json: @voucher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vouchers/1
  # PATCH/PUT /vouchers/1.json
  def update
    respond_to do |format|
      if @voucher.update(voucher_params)
        format.html { redirect_to @voucher, notice: 'Voucher was successfully updated.' }
        format.json { render :show, status: :ok, location: @voucher }
      else
        format.html { render :edit }
        format.json { render json: @voucher.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vouchers/1
  # DELETE /vouchers/1.json
  def destroy
    @voucher.destroy
    respond_to do |format|
      format.html { redirect_to vouchers_url, notice: 'Voucher was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_voucher
      @voucher = Voucher.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def voucher_params
      params.require(:voucher).permit(:no, :date, :payee, :description, :amount, :voucher_account_id)
    end
    
    def set_dateholder
    	#if params[date] exists, save it to dateholder 
    	#else if params[dateholder] exists, save it to dateholder 
    	#else, default value is today
    	@dateholder = Voucher.new
    	if params['date']
    	  @dateholder.date = params['date']
    	elsif params['dateholder']
      	@dateholder.date = params['dateholder']['date(1i)']+"-"+
                      	  params['dateholder']['date(2i)']+"-"+
                      	  params['dateholder']['date(3i)']
	    else
	      @dateholder.date = Date.today.to_s
	    end
    end
end
