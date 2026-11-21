module Ontoportal
  # Locates the bubastis jar shipped in this gem. Run it with
  #
  #   java -jar #{Ontoportal::Bubastis.jar_path} -ontology1 OLD -ontology2 NEW \
  #     -output diff.xml -format xml
  #
  # Bubastis exits 0 even when it cannot load an input, so callers should
  # treat a missing or empty output file as the failure signal.
  module Bubastis
    JAR_DIR = File.expand_path('../../jars', __dir__)
    JAR_PATTERN = /\Abubastis-(.+)\.jar\z/.freeze

    # Absolute path to the bubastis jar.
    def self.jar_path
      jars = Dir[File.join(JAR_DIR, 'bubastis-*.jar')]
      if jars.empty?
        raise LoadError, "no bubastis jar in #{JAR_DIR} " \
                         '(in a git checkout, run `rake jar:fetch`)'
      end

      # An installed gem has exactly one jar; a checkout may hold several.
      jars.max_by { |jar| Gem::Version.new(File.basename(jar)[JAR_PATTERN, 1]) }
    end

    # Version of the jar itself, such as "1.4.1". It can differ from the gem
    # version, which may carry a fourth segment for a packaging-only fix.
    def self.jar_version
      File.basename(jar_path)[JAR_PATTERN, 1]
    end
  end
end
