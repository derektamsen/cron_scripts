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
    num = 1 + rand(10)
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
    # Remove dir from array and prep for copy
    dirtocopy = $sourcedir.pop
    # call the copy function and store the pid
    pids << syncproc(dirtocopy)
    puts "copying " + $basesourcedir + "/" + dirtocopy
end # end maxprallelproc

puts "Left to copy " + $sourcedir.length.to_s

# loop until # processes is greater than maxparallelproc
while pids.length >= $maxparallelproc
    # Check each pid to see if it is currently running
    pids.each {|pid|
        begin
          # check to see if we get the pid back. If we do that means it is still running
          Process.getpgid(pid)
          #puts "still running: " + pid.to_s
        # If the process is not running we will get a return of Errno::ESRCH
        rescue Errno::ESRCH
          # remove non active pid so we can launch another in its palace
          pids.delete(pid)
          puts "no longer running: " + pid.to_s
        end
    }
    # Sleep some so we don't consume a lot of cpu
    sleep 0.8
end # end while pids.length >= maxparallelproc
end # end until sourcedir is empty

# wait until all processes have exited before stopping script
Process.waitall
