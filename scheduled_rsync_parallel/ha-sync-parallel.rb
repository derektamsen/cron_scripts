#!/usr/bin/ruby

# Variables
$basesourcedir = "/tmp/test"              # Base Directory to be backed up

$maxparallelproc = 4                     # Number of parallel rsync processes to run


rsync="/usr/bin/rsync"                  # file location of rsync


rproto="ssh -i /root/.ssh/rsync-key"    # rsync proto options
flags="-av -e"                          # rsync flags
source="/tmp/file_to_send"              # files to send
dest="server2:/tmp/"                    # directory to store files
lockfile="/var/lock/ha-sync"            # location for lock file

# Get the directory listing based on basesourcedir and split it for parallel processes
def builddir()
    if File.directory?($basesourcedir) == true
        puts "Using " + $basesourcedir + " to build rsync source list"
        
        # Listing subdirectories under basesourcedir and loading the list into an array.
        sourcels = Dir.entries($basesourcedir)
        # Removing . and .. entries
        sourcels.delete(".")
        sourcels.delete("..")
        
        return sourcels
        
    else
        raise $basesourcedir + " Is missing or not a directory."
    end
end # end builddir

def syncproc(dir)
    num = 1 + rand(5)
    proc = Kernel.fork{sleep num}
    Process.detach(proc)
    return proc
end # end syncproc

# Get subdirectory listing and store it as a variable
$sourcedir = builddir

pids = []
until $sourcedir.empty?
# Launch sub processes until parallelisim = $maxparallelproc
while pids.length < $maxparallelproc
    dirtocopy = $sourcedir.pop
    pids << syncproc(dirtocopy)
    #puts "copying " + $basesourcedir + "/" + dirtocopy
end # end maxprallelproc
Process.wait
#puts "Left to copy " + $sourcedir.length.to_s
end # end until sourcedir is empty

# wait until all processes have exited before stoping script
Process.waitall