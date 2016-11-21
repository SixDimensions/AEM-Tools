# Oak Compact Helper
This tool automates offline Oak Compaction run against AEM repositiories. This script automates the check of checkpoints, removal, and compaction of an Oak repository. 
## Use
You can use the file standalone in the repository directory by performing a chmod +x on the file, then running the file as so:

`./run-compact.sh -d /opt/aem/crx-quickstart/repository/segmentstore -v 1.0.8 -m rm-all`

Using the above command this will compact the repository at `/opt/aem/crx-quickstart/repository/segmentstore` using the oak-run jar version `1.0.8` with the option to remove all checkpoints `rm-all`.

It is up to you to supply the correct oak-run.jar version for the version of the repository you are using. The jar should be dropped into the `oak_run_jars` folder.

Likewise you could alias this and use just the command itself, likely useful if you have multiple AEM instances.


You can find the appropriate oak-run jar at: https://mvnrepository.com/artifact/org.apache.jackrabbit/oak-run


This tool is covered by the LICENSE file at the root of this repository.
