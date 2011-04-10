class JekyllAdmin
  LOG = Logger.new(RAILS_ROOT + "/log/jekyll.log")

  def initialize(values = {})
    @data = Hash.new
    values.each do |key,value|
      @data[key] = value
    end
    @excluded_keys = ["filename", "body"]
  end

  def self.all
    posts = Array.new
    Dir.open(JekyllAdmin.admin_config["post_path"]).each do |post|
      # Ignore files whose names start with . and _
      if post.first != "." and post.first != "_" and post.first != ":"
        posts.push(JekyllAdmin.load(post))      
      end
    end      
    return posts
  end
  
  def self.load(filename)
    content = File.open(File.join(JekyllAdmin.admin_config["post_path"], filename)).read 
    obj = JekyllAdmin.new()
    if content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
      body = content[($1.size + $2.size)..-1]
    end
    if content and content.size > 0
      YAML::load(ERB.new(content).result(binding)).symbolize_keys.each do |key,value|
        obj.send("#{key}=",value.gsub(/\"/,""))
      end
    end
    obj.body = body || ""
    obj.body.gsub!(/\{% #{JekyllAdmin.admin_config["content_top"]} %\}/,"")
    obj.body.gsub!(/\{% #{JekyllAdmin.admin_config["content_bottom"]} %\}/,"")
    obj.filename = filename
    return obj
  end
  
  def update_attributes(values)
    values.each do |key,value|
      @data[key.to_s] = value
    end
  end
  
  def save
    file = File.open(File.join(JekyllAdmin.admin_config["post_path"], filename),"w")
    file.puts("---")
    JekyllAdmin.post_template.each do |key,value|
      if not @excluded_keys.include?(key.to_s)
        file.puts("#{key}: \"#{@data[key]}\"")
      end
    end
    file.puts("---")
    file.puts("{% " + JekyllAdmin.admin_config["content_top"] + " %}")
    file.puts(body)
    file.puts("{% " + JekyllAdmin.admin_config["content_bottom"] + " %}")
    file.close
  end
  
  def to_s
    "#{title}"
  end
  
  def id
    filename.split("/").last
  end
  
  def start_at
    date = filename.split("/").last.split("-")
    Time.parse("#{date[0]}-#{date[1]}-#{date[2]} #{time}")
  end
  
  def method_missing(name, *args)
    return_value = ""
    name = name.to_s
    if name.last == "="
      return_value = @data[name.gsub(/\=/,"")] = args[0]
    else
      return_value = @data[name]
    end
    return_value
  end
  
  def self.admin_config
    admin_config = YAML.load_file(File.join(Rails.root, "config", "jekyll_admin.yml"))
    admin_config["post_path"] = File.join(Rails.root, admin_config["relative_blog_path"], "_posts")
    return admin_config
  end
  
  def self.config
    YAML.load_file(File.join(Rails.root, JekyllAdmin.admin_config["relative_blog_path"], "_config.yml"))
  end
  
  def self.post_template
    YAML.load_file(File.join(Rails.root,"config","jekyll_admin_post_template.yml"))
  end
  
  def self.publish
    admin_config = JekyllAdmin.admin_config
    Dir.chdir(File.join(Rails.root,admin_config["relative_blog_path"]))
    system("#{admin_config["jekyll_bin_path"]}")
    if admin_config["post_publish_commands"] and admin_config["post_publish_commands"].size > 0
      Dir.chdir(Rails.root)
      system("#{admin_config["post_publish_commands"]}")
      sleep 1
    end
  end
  
  def self.make_filename(params)
    "#{params[:jekyll]['date(1i)'].rjust(2,'0')}-#{params[:jekyll]['date(2i)'].rjust(2,'0')}-#{params[:jekyll]['date(3i)'].rjust(2,'0')}-#{params[:jekyll]['title'].gsub(/\W/, "-").downcase}.html"    
  end
end