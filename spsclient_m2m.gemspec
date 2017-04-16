Gem::Specification.new do |s|
  s.name = 'spsclient_m2m'
  s.version = '0.3.1'
  s.summary = 'The SPSClient_M2M gem is designed to run as a service with the RSF_Services gem and the dws-registry gem or the remote_dwsregistry gem.'
  s.authors = ['James Robertson']
  s.add_runtime_dependency('polyrex', '~> 1.1', '>=1.1.12')  
  s.add_runtime_dependency('spstrigger_execute', '~> 0.4', '>=0.4.6')
  s.add_runtime_dependency('sps-sub', '~> 0.3', '>=0.3.4')
  s.files = Dir['lib/spsclient_m2m.rb']
  s.signing_key = '../privatekeys/spsclient_m2m.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/spsclient_m2m'
end
