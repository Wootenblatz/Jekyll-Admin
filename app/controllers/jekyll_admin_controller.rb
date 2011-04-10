class JekyllAdminController < ApplicationController
  before_filter :load_configs
  def index
    @posts = JekyllAdmin.all
  end
  
  def new
    if request.post?
      errors = form_errors
      if errors.size == 0
        @post = JekyllAdmin.new(params[:jekyll])
        @post.filename = JekyllAdmin.make_filename(params)
        @post.save
        JekyllAdmin.publish
        flash[:notice] = "#{@post.title} saved"
        redirect_to :action => "index"
      else
        flash[:error] = errors.join("<br/>")
      end
    end
  end
  
  def edit
    if params[:jekyll] and params[:jekyll][:filename]
      params[:id] = params[:jekyll][:filename]
    else
      params[:id] = "#{params[:id]}.#{params[:format]}"
    end
    
    @post = JekyllAdmin.load(params[:id])
    if request.post?
      errors = form_errors
      if errors.size == 0
        @post.update_attributes(params[:jekyll])
        @post.save
        JekyllAdmin.publish
        flash[:notice] = "#{@post.title} saved"
        redirect_to :action => "index"
      else
        flash[:error] = errors.join("<br/>")
      end
    end
  end
  
  def destroy
    load_configs
    params[:id] = "#{params[:id]}.#{params[:format]}"
    params[:id].gsub!(/\.\./,"")
    params[:id].gsub!(/\//,"")
    params[:id].gsub!(/%/,"")
    File.delete(File.join(JekyllAdmin.admin_config["post_path"],params[:id]))
    flash[:notice] = "Post deleted"
    redirect_to :action => "index"
  end
  
  protected
    def form_errors
      if not @admin_config
        load_configs
      end
      errors = Array.new
      @required_fields.each do |f|
        if not params[:jekyll][f] or params[:jekyll][f].size == 0
          errors.push("#{f} must not be blank".capitalize)
        elsif @admin_config["field_format_#{f}"] and params[:jekyll][f] !~ Regexp.new(@admin_config["field_format_#{f}"].split(",").first)
          errors.push("#{f} #{@admin_config["field_format_#{f}"].split(",").last}".capitalize)
        end
      end
      return errors
    end

    def load_configs
      @post_template = false
      @admin_config = JekyllAdmin.admin_config
      logger.info @admin_config["ip_address_restriction"].split(",").each { |ip| ip.strip! }.inspect
      @admin_config["ip_address_restriction"].split(",").each do |ip| 
        if request.env["REMOTE_ADDR"] =~ /#{ip.strip}/
          @post_template = JekyllAdmin.post_template
          @required_fields = @admin_config["required_fields"].split(",").each { |f| f.strip! }        
        end
      end
      
      if not @post_template
        flash[:error] = "You must be an admin to edit this blog"
        redirect_to "/"        
      end
    end
end
