require 'rake'

Gem::Specification.new do |spec|
  spec.name = 'overdrive-m4b'
  spec.version = File.read('version').chomp
  spec.summary = 'Convert Overdrive audiobook mp3 files to an m4b '
  spec.description = 'A dirty script to convert Overdrive audiobooks to a single m4b file'
  spec.authors = ['Pablo Flouret']
  spec.email = 'pflouret@gmail.com'
  spec.homepage = 'https://github.com/pflouret/overdrive-m4b'
  spec.license = 'Apache-2.0'
  spec.executables = ['overdrive-m4b']

  spec.files = FileList[
    'bin/overdrive-m4b',
    'version',
  ]

  spec.add_runtime_dependency 'nokogiri', '>= 1.10.7', '< 1.12.0'
  spec.add_runtime_dependency 'id3tag', ['~> 0.12.1']
end
