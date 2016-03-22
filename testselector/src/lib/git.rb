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

  # get list of modified files in commit
  def self.getModifiedFiles(debug, commit)
    cmd ="git show --format=\"format:\" --name-only --diff-filter=\"M\" -m #{commit}"
    output = `#{cmd}`
    files = output.split("\n").select {|file| file != ""}
    if (debug)
      puts "cmd: #{cmd}\nfiles modified in commit: #{files}"
    end
    files
  end
  # get list of modified functions in commit
  def self.getModifiedFunctions(debug, commit)
    functions = []
    regexp = Regexp.new('@@.*@@ .* (.*)\(')
    excludeRegexp = Regexp.new('\$')
    cmd = "git log -p -m #{commit}^..#{commit} | grep '^@@'"
    output = `#{cmd}`
    output.split("\n").map do |line|
      match = regexp.match(line)
      nomatch = excludeRegexp.match(line)
      if (!match.nil? && nomatch.nil?)
        functions.push(match[1])
      end
    end
    if (debug)
      puts "cmd: #{cmd}\nfunctions modified in commit: #{functions}"
    end
    functions.uniq!
  end

  # Function auto-detects and returns git repo root
  # e.g. /repo/esignum/radiosw/
  def self.getRepoRoot
    gitRoot = `git rev-parse --show-toplevel`
    gitRoot.strip
  end

  # Function returns top-level commit SHA ID
  def self.getDefaultCommitHash()
    commitId = `git rev-parse HEAD`[0..-2]
    return commitId
  end

end
