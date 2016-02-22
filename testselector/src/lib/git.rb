module GitWrapper
  #####################
  # Module Functions
  #####################
  # Function checks to see if the script is being run inside a git repo
  def self.isInRepo()
    #output = `git rev-parse --is-inside-work-tree`
    output = `cd .git 2>&1 ;git rev-parse --is-inside-git-dir  2>&1`
    # if command faild or didn't return true:
    if (($?.to_i !=0) || output.strip != "true")
      puts "Error: must be run inside a git repository and at the top of the working directory."
      return false
    end

    return true
  end

  # Function returns the path of the configuration directory.
  def self.getConfigDirPath
    File.join(File.expand_path(File.dirname(__FILE__)), '..', 'cfg')
  end

  # Function auto-detects and returns git repo root
  # e.g. /repo/esignum/radiosw/
  def self.getRepoRoot
    gitRoot = `git rev-parse --show-toplevel`
    gitRoot.strip
  end

  # Function returns top-level commit SHA ID
  def self.getDefaultCommitHash()
    commitId = `git rev-parse HEAD`
    return commitId
  end

  # Function: given an array of filenames,
  # will return an array containing only the interesting file names
  def self.pruneFileList(files, gitParam )
    includeRegExp = Regexp.union(gitParam['includeFilesRegexp'])
    excludeRegExp = Regexp.union(gitParam['ignoreFilesRegexp'])
    prunedFiles = Array.new
    files.each do |file|
      if (file =~ includeRegExp)
        unless (file =~ excludeRegExp)
          prunedFiles.push(file.sub(gitParam['removePrefix'], gitParam['replacePrefixWith']))
        end
      end
    end
    return prunedFiles
  end
end
