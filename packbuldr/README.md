# Package Builder (packbuldr)
This tool makes it easier to build packages that may have multiple filters. This tool automates the creation, adding filters, building of packages, downloading and optionally, installing packages on another AEM instance.
## Use
You can use the file standalone by performing a chmod +x on the file, then running the file as so:

`./packbuldr.sh -p myuserpassword -n my_new_package -h http://localhost:4502 -t "http://localhost:5502 http://localhost:5503" -f myNewFilters.txt`

There is some additional configuration that you need to configure within the script itself. Namely:
* User
* Package Group

Other options can be configured, or passed in as arguments:
* Host:Port
* Target Host:Port
* Filters text file

This tool is covered by the LICENSE file at the root of this repository.
