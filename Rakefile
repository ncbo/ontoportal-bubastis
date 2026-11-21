require 'digest'
require 'fileutils'
require 'net/http'
require 'uri'

ROOT = __dir__
VERSION_FILE = File.join(ROOT, 'BUBASTIS_VERSION')
CHECKSUM_FILE = File.join(ROOT, 'jars.sha256')
JAR_DIR = File.join(ROOT, 'jars')
# The repository whose GitHub releases carry bubastis-X.Y.Z.jar.
SOURCE_REPO = ENV.fetch('BUBASTIS_REPO', 'ncbo/bubastis')

def jar_version
  File.read(VERSION_FILE).strip
end

def jar_name(version = jar_version)
  "bubastis-#{version}.jar"
end

def release_url(version)
  "https://github.com/#{SOURCE_REPO}/releases/download/v#{version}/#{jar_name(version)}"
end

# The checksum recorded in jars.sha256 (sha256sum format) for a jar name.
def recorded_sha256(name)
  File.foreach(CHECKSUM_FILE) do |line|
    sha, file = line.split
    return sha if file == name
  end
  nil
end

# Streams url to dest, following redirects (GitHub serves release assets from
# another host).
def download(url, dest, redirects = 5)
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(Net::HTTP::Get.new(uri)) do |res|
      case res
      when Net::HTTPRedirection
        raise "too many redirects fetching #{url}" if redirects.zero?

        next_url = URI.join(url, res['location']).to_s
        return download(next_url, dest, redirects - 1)
      when Net::HTTPSuccess
        File.open(dest, 'wb') { |f| res.read_body { |chunk| f.write(chunk) } }
      else
        raise "GET #{url} failed: #{res.code} #{res.message}"
      end
    end
  end
end

# Downloads a release jar to a temporary file and returns [path, sha256].
def fetch_to_temp(version)
  FileUtils.mkdir_p(JAR_DIR)
  tmp = File.join(JAR_DIR, "#{jar_name(version)}.part")
  puts "Downloading #{release_url(version)}"
  download(release_url(version), tmp)
  [tmp, Digest::SHA256.file(tmp).hexdigest]
end

namespace :jar do
  desc 'Download the jar named by BUBASTIS_VERSION and verify it against jars.sha256'
  task :fetch do
    name = jar_name
    expected = recorded_sha256(name) or abort "no checksum for #{name} in jars.sha256"
    dest = File.join(JAR_DIR, name)

    if File.file?(dest) && Digest::SHA256.file(dest).hexdigest == expected
      puts "#{name} already present and verified"
    else
      # Never leave a jar that fails verification where gem build would pick it up.
      FileUtils.rm_f(dest)
      tmp, actual = fetch_to_temp(jar_version)
      unless actual == expected
        FileUtils.rm_f(tmp)
        abort "SHA-256 mismatch for #{name}: expected #{expected}, got #{actual}"
      end
      File.rename(tmp, dest)
      puts "#{name} verified (sha256 #{actual})"
    end

    # Only the current jar belongs in jars/, so the gem and jar_path agree.
    (Dir[File.join(JAR_DIR, 'bubastis-*.jar')] - [dest]).each { |old| FileUtils.rm_f(old) }
  end

  desc 'Verify the jar already in jars/ against jars.sha256'
  task :verify do
    name = jar_name
    path = File.join(JAR_DIR, name)
    abort "#{path} is missing; run `rake jar:fetch`" unless File.file?(path)
    actual = Digest::SHA256.file(path).hexdigest
    abort "SHA-256 mismatch for #{name}: got #{actual}" unless actual == recorded_sha256(name)
    puts "#{name} OK"
  end

  desc 'Switch to a new bubastis release: rake "jar:add[1.4.2]". Records its checksum.'
  task :add, [:version] do |_t, args|
    version = args[:version] or abort 'usage: rake "jar:add[X.Y.Z]"'
    name = jar_name(version)
    abort "#{name} already in jars.sha256" if recorded_sha256(name)

    tmp, sha = fetch_to_temp(version)
    File.rename(tmp, File.join(JAR_DIR, name))
    File.open(CHECKSUM_FILE, 'a') { |f| f.puts "#{sha}  #{name}" }
    File.write(VERSION_FILE, "#{version}\n")
    puts "Recorded #{sha}  #{name}"
    puts 'Compare it with the digest shown for the asset on the GitHub release page ' \
         "(gh release view v#{version} -R #{SOURCE_REPO} --json assets) before committing."
  end
end

def gem_file
  spec = Gem::Specification.load(File.join(ROOT, 'ontoportal-bubastis.gemspec'))
  "#{spec.name}-#{spec.version}.gem"
end

desc 'Build the gem (fetches and verifies the jar first)'
task build: 'jar:fetch' do
  sh 'gem', 'build', 'ontoportal-bubastis.gemspec'
end

desc 'Build and install the gem locally'
task install: :build do
  sh 'gem', 'install', '--local', gem_file
end

desc 'Install the gem and run the smoke test against the installed jar_path'
task smoke: :install do
  sh 'script/smoke-test'
end

task default: :smoke
