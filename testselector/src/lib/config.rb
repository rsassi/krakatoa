require 'yaml'

module TestSelectorConfigFile
  # Function returns the path of the configuration directory.
  def self.getConfigDirPath
    File.join(File.expand_path(File.dirname(__FILE__)), '..', 'cfg')
  end

  #####################
  # Module Classes
  #####################

  #Class which manages the config file for this script
  class ConfigReader
    CONFIG_YAML = "config.yaml"
    def initialize()
      fullPath = File.join(TestSelectorConfigFile::getConfigDirPath(), CONFIG_YAML)
      @config = YAML.load_file(fullPath)
    end

    # Function returns
    def getDB()
      return @config["dbconfig"]
    end

    def getGit()
      return @config["git"]
    end


    def getOutput()
      return @config["output"]
    end
  end

end