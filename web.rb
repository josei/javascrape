# -*- encoding: utf-8 -*-
require 'rubygems'
require 'bundler'
Bundler.require

Faraday.default_adapter = :em_synchrony

class JavaScrape < Sinatra::Base
  register Sinatra::Synchrony
  
  Connection = Faraday.new do |builder|
    builder.use FaradayMiddleware::FollowRedirects, :limit=>3
    builder.adapter Faraday.default_adapter
  end
  
  get '/' do
    haml :index
  end

  get '/get' do
    Connection.get(params[:uri]).body
  end

  helpers do
    def base_js
      <<-EOS
        jQuery(function($) {
          $("input#run").click(function() {
            $("pre#result").text("");
            try {
              eval(editor.getValue());
            } catch(err) {
              alert("Error:\\n" + err.message);
            }
          });
        
          $(document).bind('keydown', 'alt+r', function() { $("input#run").click(); });

          function get(real_url, callback) {
            url = "/get?uri=" + encodeURIComponent(real_url);
            $.get(url, callback);
          }
        
          function linkify(html) {
            var noProtocolUrl = /(^|["'(\\s]|&lt;)(www\\..+?\\..+?)((?:[:?]|\\.+)?(?:\\s|$)|&gt;|[)"',])/g;
            var httpOrMailtoUrl = /(^|["'(\\s]|&lt;)((?:(?:https?|ftp):\\/\\/|mailto:).+?)((?:[:?]|\\.+)?(?:\\s|$)|&gt;|[)"',])/g;
            return html.replace( noProtocolUrl, '$1<a class="previewlink" href="<``>://$2">$2</a>$3' )
                       .replace( httpOrMailtoUrl, '$1<a class="previewlink" href="$2">$2</a>$3' )
                       .replace( /"<``>/g, '"http' );
          }

          function println(text) {
            $("pre#result").html($("pre#result").html()+linkify(text)+"\\n");
            bindBubbles();
          }
        
        });
      EOS
    end

    def code_mirror_js
      <<-EOS
        editor = CodeMirror.fromTextArea(document.getElementById("code"), {
          mode: 'javascript',
          lineNumbers: true,
          extraKeys: { 'Alt-R': function() { $("input#run").click(); } },
          matchBrackets: true
        });
      EOS
    end
  
    def example
      <<-EOS
get("http://engadget.com", function(result) {
  $(result).find("h4.post_title a").each(function() {
    println($(this).text());
    println($(this).attr("href"));
  });
});
      EOS
    end
  end
end
