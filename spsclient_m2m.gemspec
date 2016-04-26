Gem::Specification.new do |s|
  s.name = 'spsclient_m2m'
  s.version = '0.2.0'
  s.summary = 'The SPSClient_M2M gem is designed to run as a service with the RSF_Services gem and the dws-registry gem or the remote_dwsregistry gem.'
  s.authors = ['James Robertson']
  s.add_runtime_dependency('polyrex', '~> 1.0', '>=1.1.1')  
  s.add_runtime_dependency('spstrigger_execute', '~> 0.4', '>=0.4.6')
  s.add_runtime_dependency('websocket-eventmachine-client', '~> 1.0', '>=1.1.0')
  s.files = Dir['lib/spsclient_m2m.rb']
  s.signing_key = '../privatekeys/spsclient_m2m.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/spsclient_m2m'
end
