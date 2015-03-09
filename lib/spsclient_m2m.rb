#!/usr/bin/env ruby

# file: spsclient_m2m.rb


require 'polyrex'
require 'spstrigger_execute'
require 'websocket-eventmachine-client'    


class SPSClientM2M

  def initialize(rws, sps_keywords_url, px_url, logfile: nil, \
                                          sps: {host: 'sps', port: '59000'})
          
    @log = Logger.new(logfile,'daily') if logfile
    @rws = rws
    @sps_address = "%s:%s" % [sps[:host], sps[:port]]
    
    reg = @rws.services['registry']
    
    px = Polyrex.new px_url
    
    @ste = SPSTriggerExecute.new sps_keywords_url, reg, px

  end
  
  def run()
  
    rws = @rws
    ste = @ste
    sps_address = @sps_address
    
    EM.run do

      ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://' + sps_address)

      ws.onopen do
        puts "Client connected"
      end

      ws.onmessage do |msg, type|

        log 'msg : ' + msg.inspect
        topic, raw_message = msg.split(/\s*:\s*/,2)
        puts "[%s] SPS M2M kywrd lstnr INFO %s: %s" % \
                        [Time.now.strftime("%D %H:%M"), topic, raw_message]

        a = ste.mae topic, raw_message
        log 'a: ' + a.inspect

        # obj is the DRb object, r is the result from find_match, 
        # a is the Dynarex lookup array, ws is the websocket.

        if a.length > 0 then
          
          h = {
          
            rse: ->(x){
            
              job = x.shift[/\/\/job:(.*)/,1]                  
              package_path = x.shift 
              package = package_path[/([^\/]+)\.rsf$/,1]
              
              log "job: %s path: %s package: %s" % [job, package_path, package]
              rws.run_job package, job, {}, args=x, package_path: package_path
            }, 
            sps: ->(x){ ws.send x },
            ste: ->(x){ ste.run x }
          }

        end
        
        
        EM.defer {  a.each {|type, x| h[type].call x}   }
      end

      ws.onclose do
        puts "Client disconnected"
      end

      EventMachine.next_tick do
        ws.send 'subscribe to topic: #'
        ws.send 'rse_info: spsclient_m2m connected'
      end
      
      EventMachine.error_handler{ |e|
        puts "Error raised during event loop: #{e.message}"
      
      }

    end
  
  end
  
  private
  
  def log(s)
    @log.debug(s) if @log
  end
end
