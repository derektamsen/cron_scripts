#!/usr/bin/ruby

# Variables
$basesourcedir = "/tmp/test"          # Base Directory to be backed up

$maxparallelproc = 8                     # Number of parallel rsync processes to run
$sleeptime = 0.8                        # time to sleep while checking pids.
                                        # can be increased for longer running processes
                                        # to reduce parent proc cpu usage

# rsync related information
# rsync program location
$rsync = "/usr/bin/rsync"                  # file location of rsync

# rsync options
$rproto = "ssh -i /root/.ssh/rsync-key"    # rsync proto options
$flags = "-av -e"                          # rsync flags

# source and destinations
$source = "/tmp/file_to_send"              # files to send
$dest = "server2:/tmp/"                    # directory to store files

# Location to store lock files
#$lockdir = "/var/lock/ha-sync-parallel"            # location for lock file
$lockdir = "/Users/dtamsen/git_working/derektamsen/cron_scripts/scheduled_rsync_parallel/lock"
$lockfileparent = "ha-sync-parallel-parent"



#### Begin Functions
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

def createsubproclock(dir, pid)
    puts "Creating lock file for " + dir
    begin
        # Create lock file for sub process
        File.new($lockdir + "/" + "syncing_" + dir, "w+")
        puts "created lock file for sub process: " + pid.to_s
    rescue
        raise "Unable to create lockfile for sub process: " + pid.to_s
        exit
    end # end parent lock file create
    puts "Adding pid to lock file"
    begin
        # Add pid to lock file
        File.open($lockdir + "/" + "syncing_" + dir, 'w') {|f| f.write(pid)}
    rescue
        puts "Unable to write pid in sub process lock file"
        raise $lockdir + "/" + "syncing_" + dir
        exit
    end # end write pid into file
end # end createsubproclock

def checksubproclock(dir)
    if File.exists?($lockdir + "/" + "syncing_" + dir)
        puts "Lock file for sub process exists: " + $lockdir + "/" + "syncing_" + dir
        
        return true
    else
        return false
    end # end lock exists check
end

def deletesubproclock(dir)
    begin
        # delete sub process lock file
        File.delete($lockdir + "/" + "syncing_" + dir)
        puts "deleted lock file for sub process: " + $lockdir + "/" + "syncing_" + dir
    rescue
        puts "Unable to delete lock file for sub process: "
        raise $lockdir + "/" + "syncing_" + dir
    end # end delete sub process lock file
end

def syncproc(dir)
    if checksubproclock(dir) == true
        puts "Something is already syncing: " + dir
        # hack to pass int to Process.getpgid that we know does not exist.
        # For now DO NOT DIRECTLY PASS TO KILL OR IT WILL KILL THE ABSOULTE VALUE
        return -99999
    else
    num = 5 + rand(30)
    proc = IO.popen("sleep " + num.to_s)
    createsubproclock(dir, proc.pid)
    Process.detach(proc.pid)
    return proc.pid
end # end checksubproclock
end # end syncproc

def synccheckdel(pid, dir)
    begin
        # check to see if we get the pid back. If we do that means it is still running
        Process.getpgid(pid)
        #puts "still running: " + pid.to_s
    # If the process is not running we will get a return of Errno::ESRCH
    rescue Errno::ESRCH
        # remove non active pid so we can launch another in its place
        if pid == -99999
            $pids.delete($pids.index(pid))
            puts "something else started this process... leaving lock file for: " + dir
        else
            deletesubproclock($pids.index(pid))
            $pids.delete($pids.index(pid))
            puts "no longer running: " + pid.to_s
        end # end check if we started process
    end # end begin rescue check to catch non runing pid
end # end synccheckdel

#### End Functions





#### Main Program
# Check to see if the lock directory exists
if File.directory?($lockdir) == false
    puts "Lock dir: " + $lockdir
    puts "does not exist. Creating..."
    begin
        # Create lock directory with u+rwx go+rx
        Dir.mkdir($lockdir, 0755)
    rescue
        raise "unable to create lock dir"
        exit
    end # end mkdir rescue
    puts "lock dir created"
end # end lockdir check

# Ensure we are not currently running
if File.exists?($lockdir + "/" + $lockfileparent) == true
    puts "Assuming ha-sync-parallel is currently running"
    raise "found lock file: " + $lockdir + "/" + $lockfileparent
    exit
else
    puts "Creating lock file"
    begin
        # Create lock file for parent process
        File.new($lockdir + "/" + $lockfileparent, "w+")
        puts "created lock file for parent process"
    rescue
        raise "Unable to create lockfile"
        exit
    end # end parent lock file create
end # end currently running check

# Get subdirectory listing and store it as a variable
$sourcedir = builddir

$pids = {}
until $sourcedir.empty?
# Launch sub processes until parallelisim = $maxparallelproc
while $pids.length < $maxparallelproc
    # Remove dir from array and prep for copy
    dirtocopy = $sourcedir.pop
    # check to see if we have done all the work to prevent errors
    unless dirtocopy == nil
        # call the copy function and store the pid
        $pids[dirtocopy] = syncproc(dirtocopy)
        if $pids[dirtocopy] == -99999
            puts "skipping: " + $basesourcedir + "/" + dirtocopy
        else
            puts "copying " + $basesourcedir + "/" + dirtocopy
        end # end skip if sub dir locked
    end # end work done check
end # end maxprallelproc

puts "Left to copy " + $sourcedir.length.to_s

# loop until # processes is greater than maxparallelproc
while $pids.length >= $maxparallelproc
    # Check each pid to see if it is currently running
    $pids.each_value {|pid| synccheckdel(pid, $pids.index(pid))}
    # Sleep some so we don't consume a lot of cpu
    sleep $sleeptime
end # end while $pids.length >= maxparallelproc
end # end until sourcedir is empty

# wait until all processes have exited before stopping script
Process.waitall

# cleanup the any remaining processes
$pids.each_value {|pid| synccheckdel(pid, $pids.index(pid))}

# run some cleanup tasks
begin
    # remove parent process lockfile
    puts "Deleting parent lock file: " + $lockdir + "/" + $lockfileparent
    File.delete($lockdir + "/" + $lockfileparent)
rescue
    raise "Unable to remove parent lock file: " + $lockdir + "/" + $lockfileparent
end # end parent lock file delete