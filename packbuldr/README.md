# Package Builder (packbuldr)
This tool makes it easier to build packages that may have multiple filters. This tool automates the creation, adding filters, building of packages, downloading and optionally, installing packages on another AEM instance.
## Use
You can use the file standalone by performing a chmod +x on the file, then running the file as so:

`./packbuldr.sh -p myuserpassword -n my_new_package`

There is some additional configuration that you need to configure within the script itself. Namely:
* Host
* Port
* User
* Package Group
* Target Host
* Target Port
* Filters text file - currently this is set to filters.txt, or if your using it to make smaller packages you could pass multiple filters with the `-f` flag.


This tool is covered by the LICENSE file at the root of this repository.
