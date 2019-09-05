#!/usr/bin/env ruby

# file: spsclient_m2m.rb


require 'polyrex'
require 'spstrigger_execute'
require 'sps-sub'    


class SPSClientM2M

  def initialize(rsc, reg, keywords, px_url, log: nil, \
            sps_host: 'sps', sps_port: '59000', topic: '#', 
                 reload_keyword: /^reload$/)
          
    @rsc, @log, @topic = rsc, log, topic
    
    log.info 'SPSCLientM2M/initialize: active' if log
    
    @sps_address = "%s:%s" % [sps_host, sps_port]    
    @sps = SPSSub.new host: sps_host, port: sps_port, log: log
    
    px = Polyrex.new px_url

    log.info 'SPSCLientM2M/initialize: before @ste' if log
    @ste = SPSTriggerExecute.new keywords, reg, px, log: log
    log.info 'SPSCLientM2M/initialize: after @ste' if log
    @keywords, @reload_keyword, @reg = keywords, reload_keyword, reg

  end
  
  def run()
 
    log.info 'SPSCLientM2M/run: active' if log
    
    rsc, ste, keywords, reg, reload_keyword  = @rsc, @ste, @keywords, @reg, 
        @reload_keyword

    @sps.subscribe(topic: @topic) do |raw_message, topic|
      
      log.info 'SPSCLientM2M/run: received something' if log
      
      if reg and topic == 'system/clock' then
        reg.set_key 'hkey_services/spsclient_m2m/last_seen', 
            "#%s#" % Time.now.to_s
      end
      
      if raw_message.strip =~ reload_keyword then
        
        log.info 'SPSClientM2M/run: reloading' if log        
        ste = SPSTriggerExecute.new keywords, reg=nil, px=nil, log: log
        
      end
      
      if log then
        log.info "SPSClientM2M/run: received %s: %s" % [topic, raw_message]
      end
      
      a = ste.mae topic: topic, message: raw_message
      log.info 'SPSClientM2M/run: a: ' + a.inspect if log

      # obj is the DRb object, r is the result from find_match, 
      # a is the Dynarex lookup array

      if a.length > 0 then
        
        h = {
        
          rse: ->(x, rsc, params){
          
            job = x.shift[/\/\/job:(.*)/,1]                  
            package_path = x.shift 
            package = package_path[/([^\/]+)\.rsf$/,1]
            
            if log then
              log.info "SPSClientM2M/run: job: %s path: %s package: %s" % \
                         [job, package_path, package]
            end
                         
            rsc.run_job package, job, params, args=x, package_path: package_path
          }, 
          sps: ->(x, rsc, _){ @sps.notice x },
          ste: ->(x, rsc, _){ 
            log.info 'SPSClientM2M/run: before ste run' if log
            ste.run x 
          }
        }

      end

      EM.defer do          
        
        a.each do |type, x, params| 
          
          Thread.new do
            
            begin

              h[type].call x, rsc, params
            rescue
              
              err_msg = 'SPSClientM2M/run/error: ' + ($!).inspect              
              log ? log.debug(err_msg) :  puts(err_msg)

            end
            
          end # /thread
          
        end # /each
        
      end      
      
    end        
    
  end
  
  private
  
  def log()
    @log
  end

end
