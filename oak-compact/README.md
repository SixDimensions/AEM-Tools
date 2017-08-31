# Oak Compact Helper
This tool automates offline Oak Compaction run against AEM repositiories. This script automates the check of checkpoints, removal, and compaction of an Oak repository.
## Use
You can use the file standalone in the repository directory by performing a chmod +x on the file, then running the file as so:

`./run-compact.sh -d /opt/aem/crx-quickstart/repository/segmentstore -v 1.0.8 -m rm-all`

Using the above command this will compact the repository at `/opt/aem/crx-quickstart/repository/segmentstore` using the oak-run jar version `1.0.8` with the option to remove all checkpoints `rm-all`.

It is up to you to supply the correct oak-run.jar version for the version of the repository you are using. The jar should be dropped into the `oak_run_jars` folder.

Likewise you could alias this and use just the command itself, likely useful if you have multiple AEM instances.

There are many options that can be passed into the run-compact script:
* ```-j``` = Specify the JVM Parameters for compaction
* ```-p``` = The pid file - use if you want run-compact to shutdown and start your AEM instances before and after compaction for you.
* ```-i``` = instance type, in case you are compacting both an author and publish on the same system, this flag allows the script to switch between the proper start/stop commands.

There are a few configurable parameters within oak-compact.sh itself

# script configurations
## the start and stop need to be configured for the modes you plan to run this with (-i).
START='/etc/init.d/aem-author start'
STOP='/etc/init.d/aem-author stop'
ITYPE='' #blank for author, this is for internal error reporting.
OAK_JARS_LOCATION="/opt/oak-compact"
COMPACTION_USER="cq"
SLEEPTIME='20s'
TIMEOUT=5
# email notification configuration
HOST="HOSTNAME"
TO="youremail@email.com"


If you specify the PID file, the script expects to stop and start the instance...

You can find the appropriate oak-run jar at: https://mvnrepository.com/artifact/org.apache.jackrabbit/oak-run


This tool is covered by the LICENSE file at the root of this repository.
