#!/usr/bin/env ruby

# file: spsclient_m2m.rb


require 'logger'
require 'polyrex'
require 'spstrigger_execute'
require 'sps-sub'    


class SPSClientM2M

  def initialize(rsc, reg, keywords, px_url, logfile: nil, \
            sps_host: 'sps', sps_port: '59000', topic: '#', 
                 reload_keyword: /^reload$/)
          
    @rsc = rsc
    @log = Logger.new(logfile,'daily') if logfile

    @sps_address = "%s:%s" % [sps_host, sps_port]
    @topic = topic
    
    @sps = SPSSub.new host: sps_host, port: sps_port
    
    px = Polyrex.new px_url

    @ste = SPSTriggerExecute.new keywords, reg, px, logfile: 'ste.log'
    @keywords, @reload_keyword = keywords, reload_keyword

  end
  
  def run()
 
    rsc = @rsc
    ste = @ste
    keywords = @keywords
    
    @sps.subscribe(topic: @topic) do |raw_message, topic|

      if raw_message.strip =~ @reload_keyword then
        
        puts 'reloading'
        ste = SPSTriggerExecute.new keywords, reg=nil, px=nil, logfile: 'ste.log'        
      end
      
      puts "[%s] SPS M2M kywrd lstnr INFO %s: %s" % \
                      [Time.now.strftime("%D %H:%M"), topic, raw_message]

      a = ste.mae topic, raw_message
      log 'a: ' + a.inspect

      # obj is the DRb object, r is the result from find_match, 
      # a is the Dynarex lookup array

      if a.length > 0 then
        
        h = {
        
          rse: ->(x, rsc){
          
            job = x.shift[/\/\/job:(.*)/,1]                  
            package_path = x.shift 
            package = package_path[/([^\/]+)\.rsf$/,1]
            
            log "job: %s path: %s package: %s" % [job, package_path, package]
            log 'foo: ' + rsc.r.hello
            rsc.run_job package, job, {}, args=x, package_path: package_path
          }, 
          sps: ->(x, rsc){ @sps.notice x },
          ste: ->(x, rsc){ log 'before ste run'; ste.run x }
        }

      end

      EM.defer do          
        
        a.each do |type, x| 
          
          Thread.new do
            
            begin
              h[type].call x, rsc
            rescue
              warning =  'SPSClientM2M warning: ' + ($!).inspect
              puts warning
              log warning
            end
            
          end # /thread
          
        end # /each
        
      end      
      
    end        
    
  end

  private
  
  def log(s)
    @log.debug(s) if @log
  end
end