# 变量

**只支持 RHEL7**

- resolv_search  
   必选。指定搜索域，列表形式。格式为：`resolv_search = ["fdisk.cc", "frame.com"}]`

- resolv_domain  
  必选。指定域名，字符串。格式为：`resolv_domain = "fdisk.cc"`

- resolv_nameservers  
  必选。指定 nameservers，最多指定 3 个，超过 3 个取前三个，列表形式。  
  格式为：`resolv_nameservers = ["223.5.5.5", "223.6.6.6", "114.114.114.114"]`

- resolv_options  
  可选。指定其他选项。默认值为： `resolv_options = "rotate timeout:2 attempts:3"`
