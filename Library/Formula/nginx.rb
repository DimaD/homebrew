require 'formula'

class Nginx < Formula
  url 'http://nginx.org/download/nginx-0.7.65.tar.gz'
  head 'http://nginx.org/download/nginx-0.8.36.tar.gz'
  homepage 'http://nginx.org/'

  if ARGV.include? '--HEAD'
    @md5='171d88e44be3025a0bdac48c4eecd743'
  else
    @md5='abc4f76af450eedeb063158bd963feaa'
  end

  depends_on 'pcre'
  
  skip_clean 'logs'

  def patches
    # Changes default port to 8080
    # Adds code to detect PCRE installed in a non-standard HOMEBREW_PREFIX
    DATA
  end

  def options
    [
      ['--with-passenger', "Compile with support for Phusion Passenger module"],
      ['--with-upload-module', "Compile with upload module by Valery Kholodkov"]
    ]
  end
  
  def passenger_config_args
      passenger_root = `passenger-config --root`.chomp
      
      if File.directory?(passenger_root)
        return "--add-module=#{passenger_root}/ext/nginx"
      end
      
      puts "Unable to install nginx with passenger support. The passenger"
      puts "gem must be installed and passenger-config must be in your path"
      puts "in order to continue."
      exit
  end
    
  def install
    configure_args = [
      "--prefix=#{prefix}",
      "--with-http_ssl_module"
    ]
    

    configure_args << passenger_config_args if ARGV.include? '--with-passenger'
    

    if ARGV.include? '--with-upload-module'
      prepare_nginx_upload_module

      configure_args << "--add-module=./#{nginx_upload_module_dirname}"
    end

    system "./configure", *configure_args
    system "make install"
  end
  
  def caveats
    <<-CAVEATS
In the interest of allowing you to run `nginx` without `sudo`, the default 
port is set to localhost:8080.

If you want to host pages on your local machine to the public, you should
change that to localhost:80, and run `sudo nginx`. You'll need to turn off
any other web servers running port 80, of course.
    CAVEATS
  end

protected
  def prepare_nginx_upload_module
    ohai "Downloading #{nginx_upload_module_url}"
    curl "-O", nginx_upload_module_url

    ohai "Extracting #{nginx_upload_module_filename}"
    safe_system "/usr/bin/tar", "-zxvf", nginx_upload_module_filename
  end

  def nginx_upload_module_url
    "http://www.grid.net.ru/nginx/download/nginx_upload_module-2.0.12.tar.gz"
  end

  def nginx_upload_module_filename
    @nginx_upload_module_filename ||= nginx_upload_module_url.split('/').last
  end

  def nginx_upload_module_dirname
    nginx_upload_module_filename.sub(".tar.gz", "")
  end
end

__END__
--- a/auto/lib/pcre/conf
+++ b/auto/lib/pcre/conf
@@ -155,6 +155,22 @@ else
             . auto/feature
         fi
 
+        if [ $ngx_found = no ]; then
+
+            # Homebrew
+           HOMEBREW_PREFIX=${NGX_PREFIX%Cellar*}
+            ngx_feature="PCRE library in ${HOMEBREW_PREFIX}"
+            ngx_feature_path="${HOMEBREW_PREFIX}/include"
+
+            if [ $NGX_RPATH = YES ]; then
+                ngx_feature_libs="-R#{HOMEBREW_PREFIX}/lib -L#{HOMEBREW_PREFIX}/lib -lpcre"
+            else
+                ngx_feature_libs="-L#{HOMEBREW_PREFIX}/lib -lpcre"
+            fi
+
+            . auto/feature
+        fi
+
         if [ $ngx_found = yes ]; then
             CORE_DEPS="$CORE_DEPS $REGEX_DEPS"
             CORE_SRCS="$CORE_SRCS $REGEX_SRCS"
--- a/conf/nginx.conf
+++ b/conf/nginx.conf
@@ -33,7 +33,7 @@
     #gzip  on;
 
     server {
-        listen       80;
+        listen       8080;
         server_name  localhost;
 
         #charset koi8-r;
