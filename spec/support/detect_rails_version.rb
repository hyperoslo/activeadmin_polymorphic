# Detects the current version of Rails that is being used
#
#
RAILS_VERSION_FILE ||= File.expand_path("../../../.rails-version", __FILE__)


def detect_rails_version
  version = version_from_file || ENV['RAILS'] || '4.2.0'
ensure
  puts "Detected Rails: #{version}" if ENV['DEBUG']
end

def detect_rails_version!
  detect_rails_version or raise "can't find a version of Rails to use!"
end

def version_from_file
  if File.exists?(RAILS_VERSION_FILE)
    version = File.read(RAILS_VERSION_FILE).chomp.strip
    version unless version == ''
  end
end

def write_rails_version(version)
  File.open(RAILS_VERSION_FILE, "w+"){|f| f << version }
end
