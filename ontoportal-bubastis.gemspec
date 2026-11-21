# Packages the bubastis jar released at https://github.com/ncbo/bubastis so
# Ruby projects can depend on it instead of committing the binary. The jar is
# not in git: `rake jar:fetch` downloads the release asset named by
# BUBASTIS_VERSION and checks it against jars.sha256. Then:
#
#   gem build ontoportal-bubastis.gemspec
#
# The gem version is the jar version unless GEM_VERSION is set, for example
# 1.4.1.1 for a packaging-only fix to the 1.4.1 jar.
jar_version = File.read(File.join(__dir__, 'BUBASTIS_VERSION')).strip
jar = "jars/bubastis-#{jar_version}.jar"
unless File.file?(File.join(__dir__, jar))
  raise "#{jar} is missing; run `rake jar:fetch` before building the gem"
end

gem_version = ENV.fetch('GEM_VERSION', '').strip
gem_version = jar_version if gem_version.empty?
unless gem_version == jar_version || gem_version.start_with?("#{jar_version}.")
  raise "GEM_VERSION #{gem_version} must be #{jar_version} or #{jar_version}.N " \
        '(the jar version comes from BUBASTIS_VERSION)'
end

# GitHub Actions sets GITHUB_REPOSITORY, so a fork that publishes its own gem
# links to itself.
repo_url = "https://github.com/#{ENV.fetch('GITHUB_REPOSITORY', 'ncbo/ontoportal-bubastis')}"

Gem::Specification.new do |s|
  s.name        = 'ontoportal-bubastis'
  s.version     = gem_version
  s.summary     = 'The bubastis ontology diff jar, packaged for OntoPortal'
  s.description = "Ships the bubastis #{jar_version} command-line jar (an OWL ontology " \
                  'diff tool, https://github.com/ncbo/bubastis) and returns its path. ' \
                  'Needs Java 11 or later at run time.'
  s.authors     = ['OntoPortal Alliance']
  s.homepage    = repo_url
  s.license     = 'Apache-2.0'
  s.files       = ['lib/ontoportal/bubastis.rb', jar, 'LICENSE', 'README.md']
  s.required_ruby_version = '>= 2.7'
  s.requirements << 'Java 11 or later'
  s.metadata = {
    'homepage_uri' => repo_url,
    'source_code_uri' => repo_url,
    'rubygems_mfa_required' => 'true'
  }
end
